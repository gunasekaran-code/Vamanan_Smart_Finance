import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';

import '../models/cashback_reports_model.dart';

/// Reads the cashback analytics bundle for the cashback reports screen.
class CashbackService {
  CashbackService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// reports.php filters transaction history to the last 30 days unless a
  /// range is given, so ask for everything up to tomorrow (server runs IST).
  Future<CashbackReport> fetchReport() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final uri = ApiConfig.endpoint(AdminEndpoints.reports).replace(queryParameters: {
      'type': 'cashback',
      'start_date': '2000-01-01',
      'end_date': tomorrow.toIso8601String().substring(0, 10),
    });

    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(ApiConfig.timeout);
    } catch (error) {
      throw CashbackReportException('Could not reach the server: $error');
    }

    final body = _decode(response);
    if (response.statusCode != 200 || body['status'] != 'success') {
      throw CashbackReportException(
        body['message']?.toString() ?? 'Failed to load cashback reports.',
      );
    }

    final data = body['data'];
    return CashbackReport.fromJson(data is Map ? Map<String, dynamic>.from(data) : const {});
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Fall through to a consistent service error.
    }
    throw CashbackReportException(
      'Server returned an unreadable response (HTTP ${response.statusCode}).',
    );
  }

  void dispose() => _client.close();
}

class CashbackReportException implements Exception {
  final String message;

  const CashbackReportException(this.message);

  @override
  String toString() => message;
}
