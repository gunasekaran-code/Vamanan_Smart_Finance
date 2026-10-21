import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../models/withdrawal_models.dart';

class WithdrawalsService {
  Future<List<WithdrawalRequest>> fetchWithdrawals({String? userId}) async {
    final params = <String, String>{};
    if (userId != null && userId.isNotEmpty) params['user_id'] = userId;

    final uri = ApiConfig.endpoint(AdminEndpoints.withdrawals)
        .replace(queryParameters: params.isEmpty ? null : params);

    http.Response response;
    try {
      response = await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw WithdrawalsException('Could not reach the server: $e');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw WithdrawalsException('Unexpected response (HTTP ${response.statusCode}).');
    }

    if (response.statusCode != 200 || body['status'] != 'success') {
      throw WithdrawalsException(body['message']?.toString() ?? 'Failed to load withdrawals.');
    }

    final rows = (body['data'] as List<dynamic>? ?? []);
    return rows.map((e) => WithdrawalRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Approve a withdrawal. transactionId should be the bank/UTR reference
  /// once the transfer is actually made.
  Future<WithdrawalActionResult> approve(String id, {String? transactionId}) {
    return _process(id, 'approved', transactionId: transactionId);
  }

  /// Reject a withdrawal — the backend refunds the locked capital back
  /// to the wallet automatically.
  Future<WithdrawalActionResult> reject(String id) {
    return _process(id, 'rejected');
  }

  Future<WithdrawalActionResult> _process(String id, String status, {String? transactionId}) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.processWithdrawal);

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': id,
              'status': status,
              if (transactionId != null && transactionId.isNotEmpty) 'transaction_id': transactionId,
            }),
          )
          .timeout(ApiConfig.timeout);
    } catch (e) {
      throw WithdrawalsException('Could not reach the server: $e');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw WithdrawalsException('Unexpected response (HTTP ${response.statusCode}).');
    }

    final result = WithdrawalActionResult.fromJson(body);
    if (!result.success) {
      throw WithdrawalsException(result.message.isNotEmpty ? result.message : 'Action failed.');
    }
    return result;
  }
}