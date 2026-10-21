import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:frontend/core/config/api_config.dart';
import '../../models/investment_report_model.dart';

class InvestmentApiException implements Exception {
  final String message;
  InvestmentApiException(this.message);
  @override
  String toString() => message;
}

class InvestmentService {
  /// GET admin/investments.php — cycles with status == 'pending'.
  Future<List<Investment>> fetchPendingInvestments() {
    return _fetchList(AdminEndpoints.pendingInvestments);
  }

  /// GET admin/investment_history.php — cycles with status != 'pending'.
  Future<List<Investment>> fetchInvestmentHistory() {
    return _fetchList(AdminEndpoints.investmentHistory);
  }

  /// POST admin/approve_investment.php
  /// Set [approve] = true to activate the investment, false to reject it.
  /// Throws [InvestmentApiException] on any non-success response.
  Future<void> decideInvestment({
    required int cycleId,
    required bool approve,
  }) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.approveInvestment);

    late final http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'cycle_id': cycleId,
              'status': approve ? 'active' : 'rejected',
            }),
          )
          .timeout(ApiConfig.timeout);
    } catch (e) {
      throw InvestmentApiException('Could not reach the server: $e');
    }

    final body = _safeDecode(res.body);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw InvestmentApiException(
        (body['message'] ?? 'Request failed (HTTP ${res.statusCode})').toString(),
      );
    }
  }

  // --- internals ---

  Future<List<Investment>> _fetchList(String endpointPath) async {
    final uri = ApiConfig.endpoint(endpointPath);

    late final http.Response res;
    try {
      res = await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw InvestmentApiException('Could not reach the server: $e');
    }

    final body = _safeDecode(res.body);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw InvestmentApiException(
        (body['message'] ?? 'Request failed (HTTP ${res.statusCode})').toString(),
      );
    }

    final data = body['data'];
    if (data is! List) return const [];

    return data
        .whereType<Map>()
        .map((e) => Investment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
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