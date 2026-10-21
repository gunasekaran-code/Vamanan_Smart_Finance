import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/network/api_response.dart';
import 'package:frontend/core/services/session_service.dart';
import '../../models/withdraw_liquidity_model.dart';

class WithdrawLiquidityService {
  WithdrawLiquidityService._();
  static final WithdrawLiquidityService instance = WithdrawLiquidityService._();

  /// GET admin/withdrawals.php — optionally scoped to one user.
  Future<ApiResponse<List<WithdrawalRequest>>> fetchWithdrawals({
    int? userId,
  }) async {
    try {
      final uri = ApiConfig.endpoint(AdminEndpoints.withdrawals).replace(
        queryParameters: userId != null ? {'user_id': '$userId'} : null,
      );

      final res = await http.get(uri).timeout(ApiConfig.timeout);
      final decoded = _decode(res.body);

      if (decoded is Map && decoded['status'] == 'success') {
        final rows = (decoded['data'] as List? ?? [])
            .map((e) => WithdrawalRequest.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
        return ApiResponse.success(rows);
      }

      return ApiResponse.failure(_errorMessage(decoded, res.statusCode));
    } catch (e) {
      return ApiResponse.failure('Could not reach the server: $e');
    }
  }

  /// POST admin/process_withdrawal.php — approve or reject a request.
  ///
  /// NOTE: the exact request contract for process_withdrawal.php wasn't
  /// available, so this assumes it accepts {id, status, transaction_id?,
  /// processed_by?} and returns {status:'success', data: <updated row>}.
  /// Adjust the body below if your endpoint expects different keys.
  Future<ApiResponse<WithdrawalRequest>> processWithdrawal({
    required int id,
    required String status, // 'approved' | 'rejected'
    String? transactionId,
  }) async {
    if (status != 'approved' && status != 'rejected') {
      return ApiResponse.failure('status must be "approved" or "rejected".');
    }

    try {
      final admin = SessionService.instance.currentUser;
      final uri = ApiConfig.endpoint(AdminEndpoints.processWithdrawal);

      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': id,
              'status': status,
              if (transactionId != null && transactionId.isNotEmpty)
                'transaction_id': transactionId,
              if (admin != null) 'processed_by': admin.id,
            }),
          )
          .timeout(ApiConfig.timeout);

      final decoded = _decode(res.body);

      if (decoded is Map && decoded['status'] == 'success') {
        final data = decoded['data'];
        if (data is Map) {
          return ApiResponse.success(
              WithdrawalRequest.fromJson(Map<String, dynamic>.from(data)));
        }
        // Endpoint acknowledged success but returned no row — treat as ok.
        return ApiResponse.success(WithdrawalRequest(
          id: id,
          userId: int.tryParse(admin?.id ?? '') ?? 0,
          userName: '',
          userEmail: '',
          amount: 0,
          paymentMethod: 'Bank Transfer',
          status: status,
          transactionId: transactionId,
          createdAt: DateTime.now(),
          processedAt: DateTime.now(),
          currentBalance: 0,
        ));
      }

      return ApiResponse.failure(_errorMessage(decoded, res.statusCode));
    } catch (e) {
      return ApiResponse.failure('Could not reach the server: $e');
    }
  }

  dynamic _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _errorMessage(dynamic decoded, int statusCode) {
    if (decoded is Map && decoded['message'] != null) {
      return decoded['message'].toString();
    }
    return 'Request failed (HTTP $statusCode).';
  }
}