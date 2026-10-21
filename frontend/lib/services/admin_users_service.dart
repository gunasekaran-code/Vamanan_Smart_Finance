import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../models/admin_user_model.dart';
import 'package:frontend/core/network/api_response.dart';

class AdminUsersService {
  AdminUsersService._();
  static final AdminUsersService instance = AdminUsersService._();

  Future<ApiResponse<List<AdminUserModel>>> fetchUsers() async {
    try {
      final uri = ApiConfig.endpoint(AdminEndpoints.allUsers);
      final res = await http.get(uri).timeout(ApiConfig.timeout);
      final body = _decode(res.body);

      if (body == null || body['status'] != 'success') {
        return ApiResponse.failure(_messageOf(body) ?? 'Failed to load users.');
      }

      final rows = (body['data'] as List? ?? const [])
          .map((e) =>
              AdminUserModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      return ApiResponse.success(rows);
    } catch (e) {
      return ApiResponse.failure('Could not reach server: $e');
    }
  }

  Future<ApiResponse<void>> updateUser({
    required int userId,
    String? role,
    String? status,
    String? kycStatus,
    String? password,
  }) async {
    final payload = <String, dynamic>{'id': userId};
    if (role != null) payload['role'] = role;
    if (status != null) payload['status'] = status;
    if (kycStatus != null) payload['kyc_status'] = kycStatus;
    if (password != null && password.isNotEmpty) payload['password'] = password;

    return _mutate(
        AdminEndpoints.updateUser, payload, 'Failed to update user.');
  }

  Future<ApiResponse<void>> deleteUsers(List<int> userIds) {
    return _mutate(
      'admin/delete_user.php',
      {'ids': userIds},
      'Failed to delete users.',
    );
  }

  /// Pauses or resumes the member's referral commission eligibility.
  /// The member's own cashback remains unaffected by this setting.
  Future<ApiResponse<bool>> setReferralActive({
    required int userId,
    required bool active,
  }) async {
    try {
      final response = await http
          .post(
            ApiConfig.endpoint(AdminEndpoints.toggleReferral),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId, 'active': active ? 1 : 0}),
          )
          .timeout(ApiConfig.timeout);
      final body = _decode(response.body);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          body?['status'] != 'success') {
        return ApiResponse.failure(
            _messageOf(body) ?? 'Failed to update referral commission.');
      }

      final persistedValue = body?['referral_active'];
      var persistedActive = active;
      if (persistedValue is num) {
        persistedActive = persistedValue != 0;
      } else if (persistedValue is bool) {
        persistedActive = persistedValue;
      } else if (persistedValue != null) {
        final value = persistedValue.toString().toLowerCase();
        if (value == '1' || value == 'true') persistedActive = true;
        if (value == '0' || value == 'false') persistedActive = false;
      }
      return ApiResponse.success(persistedActive);
    } catch (error) {
      return ApiResponse.failure('Could not reach server: $error');
    }
  }

  Future<ApiResponse<void>> _mutate(
    String endpoint,
    Map<String, dynamic> payload,
    String fallback,
  ) async {
    try {
      final response = await http
          .post(
            ApiConfig.endpoint(endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.timeout);
      final body = _decode(response.body);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          body?['status'] != 'success') {
        return ApiResponse.failure(_messageOf(body) ?? fallback);
      }
      return ApiResponse.success(null);
    } catch (error) {
      return ApiResponse.failure('Could not reach server: $error');
    }
  }

  Map<String, dynamic>? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  String? _messageOf(Map<String, dynamic>? body) =>
      body == null ? null : body['message']?.toString();
}
