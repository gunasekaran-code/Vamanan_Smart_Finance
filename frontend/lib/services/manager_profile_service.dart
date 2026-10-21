// lib/features/manager/profile/manager_profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/services/session_service.dart';
import '../../models/manager_profile_model.dart';
import '../../models/operational_footprint_model.dart';

class ManagerProfileService {
  ManagerProfileService._();
  static final ManagerProfileService instance = ManagerProfileService._();

  /// There is no dedicated "get my profile" endpoint anywhere in the
  /// backend you've shared, so the screen seeds itself from the cached
  /// session user (SessionService.instance.currentUser) instead of a
  /// network call. This method exists only as a hook in case you later
  /// add a real fetch endpoint.
  ManagerProfile? currentFromSession() {
    final user = SessionService.instance.currentUser;
    if (user == null) return null;
    return ManagerProfile.fromAppUser(user);
  }

  /// POST manager/update_profile.php — updates the signed-in manager profile.
  ///
  /// The endpoint resets `notify_email` / `notify_system` to 1 when they are
  /// missing, so callers must always pass the current preferences.
  /// Returns the updated user row the server sends back.
  Future<Map<String, dynamic>> updateProfile({
    required String id,
    required String name,
    required String email,
    required String phone,
    required bool notifyEmail,
    required bool notifySystem,
    String? password, // optional — only sent if non-empty
  }) async {
    final uri = ApiConfig.endpoint(ManagerEndpoints.updateProfile);

    final body = {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'notify_email': notifyEmail ? 1 : 0,
      'notify_system': notifySystem ? 1 : 0,
      if (password != null && password.isNotEmpty) 'password': password,
    };

    final response = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.timeout);

    final decoded = _decode(response.body);
    if (response.statusCode != 200 || decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'Failed to update account details');
    }

    final data = decoded['data'];
    return data is Map<String, dynamic> ? data : const {};
  }

  Future<List<OperationalFootprintEntry>> fetchOperationalFootprint() async {
    final response = await http
        .get(ApiConfig.endpoint(ManagerEndpoints.operationalFootprint))
        .timeout(ApiConfig.timeout);

    final decoded = _decode(response.body);
    if (response.statusCode != 200 || decoded['status'] != 'success') {
      throw Exception(
          decoded['message'] ?? 'Failed to load operational footprint');
    }

    final data = decoded['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(OperationalFootprintEntry.fromJson)
        .toList();
  }

  Map<String, dynamic> _decode(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {'status': 'error', 'message': 'Malformed server response'};
    }
  }
}
