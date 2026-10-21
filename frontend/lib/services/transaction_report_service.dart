import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../models/transaction_report_models.dart';

/// Thrown for any failure talking to the transaction report backend.
class TransactionReportException implements Exception {
  final String message;
  TransactionReportException(this.message);

  @override
  String toString() => message;
}

/// Reads the transaction analytics bundle from `admin/reports.php`.
class TransactionReportService {
  TransactionReportService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// reports.php filters history to the last 30 days unless a range is
  /// given, so ask for everything up to tomorrow (server runs IST).
  Future<TransactionReport> fetchReport() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final uri = ApiConfig.endpoint(AdminEndpoints.reports).replace(queryParameters: {
      'type': 'transaction',
      'start_date': '2000-01-01',
      'end_date': tomorrow.toIso8601String().substring(0, 10),
    });

    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw TransactionReportException('Could not reach the server: $e');
    }

    Map<String, dynamic> body;
    try {
      body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw TransactionReportException('Server returned an unreadable response (HTTP ${response.statusCode}).');
    }

    if (response.statusCode != 200 || body['status'] != 'success') {
      throw TransactionReportException(body['message']?.toString() ?? 'Failed to load transaction reports.');
    }

    final data = body['data'];
    return TransactionReport.fromJson(data is Map ? Map<String, dynamic>.from(data) : const {});
  }

  void dispose() => _client.close();
}
