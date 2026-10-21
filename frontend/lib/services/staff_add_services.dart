import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../models/staff_add_models.dart';
import 'package:frontend/core/network/api_response.dart';

/// Talks to `api/admin/add_staff.php`.
///
/// NOTE ON ASSUMPTIONS: this mirrors the pattern used by AuthService /
/// SessionService in this codebase (ApiResponse<T> with `.success`,
/// `.data`, and a static `ApiResponse.failure(message)` constructor). If
/// your actual `api_response.dart` has different factory names or fields,
/// adjust the three `ApiResponse<...>` construction sites below — the
/// request/parsing logic itself doesn't need to change.
class StaffAddService {
  StaffAddService._();
  static final StaffAddService instance = StaffAddService._();

  Future<List<Member>> fetchStaff() async {
    final response = await http
        .get(ApiConfig.endpoint(AdminEndpoints.allUsers))
        .timeout(ApiConfig.timeout);

    final decoded = jsonDecode(response.body);
    final body = decoded is Map ? decoded : <String, dynamic>{};
    final status = (body['status'] ?? '').toString();
    if (response.statusCode != 200 || status != 'success') {
      throw Exception(
        body['message'] ?? 'Failed to load staff (${response.statusCode})',
      );
    }

    final users = body['data'] is List ? body['data'] as List : const [];
    return users
        .whereType<Map>()
        .map((user) => Member.fromUser(user.cast<String, dynamic>()))
        .where((member) => member.isStaff)
        .toList();
  }

  Future<ApiResponse<StaffRegistrationResult>> registerStaff(
    StaffRegistrationRequest request,
  ) async {
    final uri = ApiConfig.endpoint(StaffEndpoints.addStaff);

    try {
      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.timeout);

      Map<String, dynamic> body;
      try {
        final decoded = jsonDecode(response.body);
        body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      } on FormatException {
        return ApiResponse<StaffRegistrationResult>.failure(
          'Server returned an unexpected response (HTTP ${response.statusCode}).',
        );
      }

      final status = (body['status'] ?? '').toString();
      final message = (body['message'] ?? '').toString();

      if (response.statusCode == 200 && status == 'success') {
        return ApiResponse<StaffRegistrationResult>.success(
          StaffRegistrationResult.fromJson(body, request: request),
        );
      }

      // add_staff.php sends specific 400 messages ("Email already
      // registered.", "Invalid staff role.", "Please fill all required
      // fields.") — surface them as-is rather than a generic error.
      return ApiResponse<StaffRegistrationResult>.failure(
        message.isNotEmpty ? message : 'Failed to register staff member (HTTP ${response.statusCode}).',
      );
    } on SocketException {
      return ApiResponse<StaffRegistrationResult>.failure(
        'Could not reach the server. Check your connection and try again.',
      );
    } on HttpException {
      return ApiResponse<StaffRegistrationResult>.failure('Server error. Please try again.');
    } catch (e) {
      return ApiResponse<StaffRegistrationResult>.failure('Unexpected error: $e');
    }
  }

  Future<void> updateStaff({
    required String id,
    String? role,
    String? status,
    String? password,
  }) async {
    final payload = <String, dynamic>{'id': id};
    if (role != null) payload['role'] = role;
    if (status != null) payload['status'] = status;
    if (password != null && password.isNotEmpty) payload['password'] = password;

    await _sendMutation(
      StaffEndpoints.updateStaff,
      payload,
      'Failed to update staff member',
    );
  }

  Future<void> deleteStaff(String id) async {
    await _sendMutation(
      StaffEndpoints.deleteStaff,
      {'id': id},
      'Failed to delete staff member',
    );
  }

  Future<void> _sendMutation(
    String endpoint,
    Map<String, dynamic> payload,
    String failureMessage,
  ) async {
    final response = await http
        .post(
          ApiConfig.endpoint(endpoint),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(ApiConfig.timeout);

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      throw Exception('$failureMessage (invalid server response).');
    }

    if (response.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? '$failureMessage (${response.statusCode})');
    }
  }
}