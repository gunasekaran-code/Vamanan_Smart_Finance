// service/advocate_profile_service.dart
//
// Uses your existing ApiConfig / endpoint constants:
//   - GET  AdminEndpoints.allUsers        ('admin/all_users.php')   -> to read the advocate's own row
//   - POST AdvocateEndpoints.updateProfile ('customer/update_profile.php') -> to save identity changes
//
// The GET side is solid (all_users.php's shape is known). The POST side's
// exact request body is a best guess (see comments below) since I don't
// have advocate/update_profile.php's source — share it and I'll line this
// up exactly.

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:frontend/core/config/api_config.dart';
import '../../models/advocate_profile_model.dart';

class AdvocateProfileService {
  /// Fetches the advocate's own profile by pulling the full user list from
  /// admin/all_users.php and filtering to [userId] client-side (there's no
  /// single-user or advocate-scoped GET endpoint in the current API).
  static Future<AdvocateProfile> fetchProfile(int userId) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.allUsers);

    late final http.Response response;
    try {
      response = await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw AdvocateProfileException('Could not reach the server: $e');
    }

    if (response.statusCode != 200) {
      throw AdvocateProfileException(
          'Server returned HTTP ${response.statusCode}');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw AdvocateProfileException('Could not parse server response');
    }

    if (decoded['status'] != 'success') {
      throw AdvocateProfileException(
          (decoded['message'] ?? 'Failed to load profile').toString());
    }

    final List<dynamic> users = (decoded['data'] as List<dynamic>?) ?? [];

    final match = users.firstWhere(
      (u) => (u as Map<String, dynamic>)['id'].toString() == userId.toString(),
      orElse: () => null,
    );

    if (match == null) {
      throw AdvocateProfileException(
          'Advocate profile not found (id: $userId)');
    }

    return AdvocateProfile.fromJson(match as Map<String, dynamic>);
  }

  static Future<void> updateIdentity({
    required int userId,
    required String name,
    required String email,
    required String phone,
    required String bio,
  }) async {
    await _postRequest(AdvocateEndpoints.updateProfile, {
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': '',
    });
  }

  static Future<void> updateSecurity({
    required int userId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _postRequest(AdvocateEndpoints.changePassword, {
      'user_id': userId,
      'new_password': newPassword,
    });
  }

  static Future<void> _postRequest(
      String endpoint, Map<String, dynamic> body) async {
    final uri = ApiConfig.endpoint(endpoint);

    late final http.Response response;
    try {
      response = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body))
          .timeout(ApiConfig.timeout);
    } catch (e) {
      throw AdvocateProfileException('Could not reach the server: $e');
    }

    if (response.statusCode != 200) {
      throw AdvocateProfileException(
          'Server returned HTTP ${response.statusCode}');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw AdvocateProfileException('Could not parse server response');
    }

    if (decoded['status'] != 'success') {
      throw AdvocateProfileException(
          (decoded['message'] ?? 'Update failed').toString());
    }
  }
}

class AdvocateProfileException implements Exception {
  final String message;
  AdvocateProfileException(this.message);

  @override
  String toString() => message;
}
