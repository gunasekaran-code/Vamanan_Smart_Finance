import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';

import '../../models/withdrawal_report_model.dart';

/// Reads the joined withdrawal report from `admin/withdrawals.php`.
class WithdrawalReportService {
  WithdrawalReportService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<WithdrawalListResult> fetchWithdrawals({int? userId}) async {
    final queryParameters = <String, String>{};
    if (userId != null) queryParameters['user_id'] = userId.toString();

    final uri = ApiConfig.endpoint(AdminEndpoints.withdrawals).replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(ApiConfig.timeout);
    } catch (error) {
      throw WithdrawalReportException('Could not reach the server: $error');
    }

    final body = _decode(response);
    if (response.statusCode != 200 || body['status'] != 'success') {
      throw WithdrawalReportException(
        body['message']?.toString() ?? 'Failed to load withdrawal reports.',
      );
    }

    return WithdrawalListResult.fromJson(body);
  }

  Future<void> approve(int id, {String? transactionId}) {
    return _process(id, WithdrawalStatus.approved.value,
        transactionId: transactionId);
  }

  Future<void> reject(int id) {
    return _process(id, WithdrawalStatus.rejected.value);
  }

  Future<void> _process(int id, String status, {String? transactionId}) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.processWithdrawal);

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': id,
              'status': status,
              if (transactionId != null && transactionId.trim().isNotEmpty)
                'transaction_id': transactionId.trim(),
            }),
          )
          .timeout(ApiConfig.timeout);
    } catch (error) {
      throw WithdrawalReportException('Could not reach the server: $error');
    }

    final body = _decode(response);
    if (response.statusCode != 200 || body['status'] != 'success') {
      throw WithdrawalReportException(
        body['message']?.toString() ?? 'Withdrawal update failed.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;

      final map = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      if (map != null) return map;
    } catch (_) {
      // Fall through to the same user-facing error for malformed responses.
    }

    debugPrint(
        'WithdrawalReportService: invalid response (${response.statusCode})');
    throw WithdrawalReportException(
      'Server returned an unreadable response (HTTP ${response.statusCode}).',
    );
  }

  void dispose() => _client.close();
}

class WithdrawalReportException implements Exception {
  final String message;

  const WithdrawalReportException(this.message);

  @override
  String toString() => message;
}
