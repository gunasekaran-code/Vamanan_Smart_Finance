import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../models/wallet_payout_report_model.dart';

class PayoutReportApiException implements Exception {
  final String message;
  PayoutReportApiException(this.message);
  @override
  String toString() => message;
}

class PayoutReportService {
  /// GET admin/payout_reports.php
  Future<PayoutReportBundle> fetchReport() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.payoutReports);
    final res = await _get(uri);
    final body = _safeDecode(res.body);
    _assertSuccess(res, body);

    final data = body['data'];
    final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

    final summaryRaw = map['summary'];
    final summary = summaryRaw is Map
        ? PayoutSummary.fromJson(Map<String, dynamic>.from(summaryRaw))
        : PayoutSummary.empty();

    final chartRaw = map['chart'];
    final chart = (chartRaw is List)
        ? chartRaw.whereType<Map>().map((e) => PayoutChartPoint.fromJson(Map<String, dynamic>.from(e))).toList()
        : <PayoutChartPoint>[];

    final historyRaw = map['history'];
    final history = (historyRaw is List)
        ? historyRaw.whereType<Map>().map((e) => PayoutTransaction.fromJson(Map<String, dynamic>.from(e))).toList()
        : <PayoutTransaction>[];

    return PayoutReportBundle(summary: summary, chart: chart, history: history);
  }

  /// GET admin/export_payouts.php — past export runs.
  Future<List<ExportRecord>> fetchExportHistory() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.exportPayouts);
    final res = await _get(uri);
    final body = _safeDecode(res.body);
    _assertSuccess(res, body);

    final data = body['data'];
    if (data is! List) return const [];
    return data.whereType<Map>().map((e) => ExportRecord.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// POST admin/export_payouts.php — logs an export and, if [transactionIds]
  /// is non-empty, marks those transactions as 'completed' on the backend.
  Future<void> recordExport({
    required String filename,
    String exportType = 'Bank Bulk Transfer',
    required double totalAmount,
    required int totalRecords,
    List<int> transactionIds = const [],
  }) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.exportPayouts);

    late final http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'filename': filename,
              'export_type': exportType,
              'total_amount': totalAmount,
              'total_records': totalRecords,
              if (transactionIds.isNotEmpty) 'transaction_ids': transactionIds,
            }),
          )
          .timeout(ApiConfig.timeout);
    } catch (e) {
      throw PayoutReportApiException('Could not reach the server: $e');
    }

    final body = _safeDecode(res.body);
    _assertSuccess(res, body);
  }

  // --- internals ---

  Future<http.Response> _get(Uri uri) async {
    try {
      return await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw PayoutReportApiException('Could not reach the server: $e');
    }
  }

  void _assertSuccess(http.Response res, Map<String, dynamic> body) {
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw PayoutReportApiException(
        (body['message'] ?? 'Request failed (HTTP ${res.statusCode})').toString(),
      );
    }
  }

  Map<String, dynamic> _safeDecode(String raw) {
    if (raw.isEmpty) {
      return {'status': 'error', 'message': 'Empty response from server'};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {'status': 'error', 'message': 'Unexpected response format'};
    } catch (_) {
      return {'status': 'error', 'message': 'Server returned invalid JSON'};
    }
  }
}