import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/invoice_model.dart';
import 'package:frontend/core/config/api_config.dart';

class InvoiceListResult {
  final List<InvoiceModel> invoices;
  final InvoiceSummary summary;
  const InvoiceListResult(this.invoices, this.summary);
}

class InvoiceServiceException implements Exception {
  final String message;
  InvoiceServiceException(this.message);
  @override
  String toString() => message;
}

// Optional: You can create an endpoints class for invoices to match your AuthEndpoints pattern
class InvoiceEndpoints {
  InvoiceEndpoints._();
  static const String invoices = 'admin/invoices.php';
}

class InvoiceService {
  InvoiceService._();
  static final InvoiceService instance = InvoiceService._();

  Map<String, String> get _headers => {
        'Accept': 'application/json',
      };

  Future<InvoiceListResult> fetchInvoices({
    String status = 'active', // 'active' -> issued only, 'all' -> everything
    String search = '',
  }) async {
    final uri = ApiConfig.endpoint(InvoiceEndpoints.invoices).replace(
      queryParameters: {
        // The PHP endpoint currently fails with a collation error for
        // status=issued. Fetch the complete register and filter in Flutter.
        'status': 'all',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final res =
        await http.get(uri, headers: _headers).timeout(ApiConfig.timeout);

    if (res.statusCode == 401) {
      throw InvoiceServiceException('Session expired. Please log in again.');
    }

    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {}

    if (res.statusCode != 200) {
      final serverMsg = body['message']?.toString();
      throw InvoiceServiceException(
        serverMsg ??
            'Failed to load invoices (Server returned HTTP ${res.statusCode}).',
      );
    }

    var rows = (body['data'] as List<dynamic>? ?? [])
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();

    if (status != 'all') {
      final selectedStatus = status.toUpperCase();
      rows = rows
          .where((invoice) => invoice.status.toUpperCase() == selectedStatus)
          .toList();
    }

    // Calculate from the filtered rows so ACTIVE and ALL totals match what is
    // visible in the register, regardless of the server summary field names.
    final summary = InvoiceSummary.fromInvoices(rows);

    return InvoiceListResult(rows, summary);
  }

  /// Re-reads one invoice straight from the register endpoint so the printed
  /// document always shows the server's frozen snapshot (admin/invoices.php has
  /// no per-id route, so we narrow the list with `search` and match on id).
  Future<InvoiceModel> fetchInvoiceById(int id, {String? invoiceNo}) async {
    final uri = ApiConfig.endpoint(InvoiceEndpoints.invoices).replace(
      queryParameters: {
        'status': 'all',
        if (invoiceNo != null && invoiceNo.trim().isNotEmpty)
          'search': invoiceNo.trim(),
      },
    );

    final res =
        await http.get(uri, headers: _headers).timeout(ApiConfig.timeout);

    if (res.statusCode == 401) {
      throw InvoiceServiceException('Session expired. Please log in again.');
    }

    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {}

    if (res.statusCode != 200) {
      throw InvoiceServiceException(
        body['message']?.toString() ??
            'Failed to load invoice (Server returned HTTP ${res.statusCode}).',
      );
    }

    for (final row in (body['data'] as List<dynamic>? ?? [])) {
      final map = row as Map<String, dynamic>;
      if ((map['id'] as num?)?.toInt() == id) {
        return InvoiceModel.fromJson(map);
      }
    }

    throw InvoiceServiceException('Invoice not found on the server.');
  }
}
