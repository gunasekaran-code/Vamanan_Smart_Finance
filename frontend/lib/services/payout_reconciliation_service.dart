import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart' as csv_pkg;
import 'package:excel/excel.dart' as excel_pkg;
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/models/payout_reconciliation_model.dart';

class PayoutReconciliationService {
  /// csv 8.x dropped `CsvToListConverter` in favour of this codec object.
  /// Line endings are normalised to `\n` before decoding, so a file saved on
  /// Windows (CRLF) or classic Mac (CR) parses the same as a Unix one.
  static final csv_pkg.Csv _csv = csv_pkg.Csv(
    lineDelimiter: '\n',
    skipEmptyLines: true,
  );

  /// Parses an uploaded CSV/XLSX file's bytes into reconciliation rows.
  /// The first row is treated as a header and skipped.
  List<ReconciliationRow> parseFile(String fileName, Uint8List bytes) {
    final ext = fileName.split('.').last.toLowerCase();
    final List<List<dynamic>> rawRows;

    if (ext == 'csv') {
      rawRows = _csv.decode(_decodeText(bytes));
    } else if (ext == 'xlsx' || ext == 'xls') {
      final excel_pkg.Excel book;
      try {
        book = excel_pkg.Excel.decodeBytes(bytes);
      } catch (e) {
        throw ReconciliationException('Could not read that Excel file: $e');
      }
      if (book.tables.isEmpty) {
        throw ReconciliationException('The Excel file has no sheets.');
      }
      final sheet = book.tables[book.tables.keys.first]!;
      rawRows = sheet.rows
          .map((row) => row.map<dynamic>(_cellText).toList())
          .toList();
    } else {
      throw ReconciliationException(
        'Unsupported file type ".$ext". Upload CSV or Excel — PDF parsing '
        'isn\'t supported on this screen yet.',
      );
    }

    if (rawRows.length <= 1) return [];

    return rawRows
        .skip(1) // header
        .where((r) => r.isNotEmpty && r.first.toString().trim().isNotEmpty)
        .map(ReconciliationRow.fromRawRow)
        .toList();
  }

  /// Bank files are usually UTF-8 (sometimes with a BOM) but can arrive as
  /// Latin-1. `allowMalformed` keeps a stray byte from blowing up the whole
  /// upload; the BOM is stripped so the first cell isn't prefixed with it.
  String _decodeText(Uint8List bytes) {
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.startsWith('﻿')) text = text.substring(1);
    return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  /// excel 4.x wraps every cell in a sealed [excel_pkg.CellValue].
  ///
  /// `TextCellValue.toString()` returns the TextSpan wrapper rather than the
  /// text inside it, so text cells are flattened explicitly — otherwise a
  /// transaction id would arrive looking like `TextSpan(text: 38)`. The other
  /// variants (int, double, bool, formula, dates) all stringify sensibly.
  static String _cellText(excel_pkg.Data? cell) {
    final value = cell?.value;
    if (value == null) return '';
    if (value is excel_pkg.TextCellValue) return _flattenSpan(value.value);
    return value.toString();
  }

  static String _flattenSpan(excel_pkg.TextSpan span) {
    final buffer = StringBuffer(span.text ?? '');
    for (final child in span.children ?? const <excel_pkg.TextSpan>[]) {
      buffer.write(_flattenSpan(child));
    }
    return buffer.toString();
  }

  /// READ — the cashback payouts shown in the STATUS MATRIX, newest first.
  ///
  /// `admin/payout_reports.php` returns the last 500 cashback + referral
  /// transactions with `failure_reason`; only cashback rows are kept because
  /// those are the only ones `reconcile_payouts.php` updates.
  Future<List<ReconciliationLedgerRow>> fetchLedger() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.payoutReports);
    // Fired in parallel: user ids for the rows (see ReconciliationLedgerRow).
    final userIdsFuture = _fetchUserIdsByTransaction();
    http.Response response;
    try {
      response = await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw ReconciliationException('Could not reach the server: $e');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ReconciliationException(
        'Unexpected response (HTTP ${response.statusCode}).',
      );
    }
    if (response.statusCode != 200 || body['status'] != 'success') {
      throw ReconciliationException(
        body['message']?.toString() ?? 'Failed to load payout records.',
      );
    }

    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final history = data['history'] as List<dynamic>? ?? const [];
    final userIds = await userIdsFuture;
    return history
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .where((e) => (e['category'] ?? '').toString() == 'cashback')
        .map((e) => ReconciliationLedgerRow.fromJson(e,
            userId: userIds[e['id']?.toString()]))
        .toList();
  }

  /// { transaction id: users.id } for cashback transactions, from
  /// `auditor/ledger.php` (which, unlike payout_reports.php, returns
  /// `user_id`). Best-effort — an empty map just leaves the ids blank.
  Future<Map<String, String>> _fetchUserIdsByTransaction() async {
    try {
      final uri = ApiConfig.endpoint('auditor/ledger.php').replace(
          queryParameters: {'category': 'cashback', 'limit': '1000'});
      final res = await http.get(uri).timeout(ApiConfig.timeout);
      final body = jsonDecode(res.body);
      if (body is! Map || body['status'] != 'success') return const {};
      return {
        for (final row in (body['data'] as List? ?? const []).whereType<Map>())
          if (row['id'] != null && row['user_id'] != null)
            row['id'].toString(): row['user_id'].toString(),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<ReconciliationSummary> submitReconciliation(
    List<ReconciliationRow> rows,
  ) async {
    if (rows.isEmpty) {
      throw ReconciliationException('No valid rows found in the uploaded file.');
    }

    final uri = ApiConfig.endpoint(AdminEndpoints.reconcilePayouts);

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'results': rows.map((r) => r.toJson()).toList()}),
          )
          .timeout(ApiConfig.timeout);
    } catch (e) {
      throw ReconciliationException('Could not reach the server: $e');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ReconciliationException(
        'Unexpected response (HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode != 200 || body['status'] != 'success') {
      throw ReconciliationException(
        body['message']?.toString() ?? 'Reconciliation failed.',
      );
    }

    final failedRows = rows.where((r) => !r.isSuccess).toList();
    return ReconciliationSummary.fromJson(body, failedRows: failedRows);
  }
}
