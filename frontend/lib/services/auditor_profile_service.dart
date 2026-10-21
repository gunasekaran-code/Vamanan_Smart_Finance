import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:frontend/core/config/api_config.dart';
import '../../models/auditor_profile_model.dart';

/// Thin wrapper around `api/auditor/profile.php`.
///
/// Uses [ApiConfig.endpoint] + [AuditorEndpoints.profile], so it automatically
/// points at whatever host/port `ApiConfig.baseUrl` resolves to (emulator,
/// device override via --dart-define=API_BASE_URL, etc). No backend changes
/// required — this only talks to the existing profile.php.
class AuditorProfileService {
  AuditorProfileService._();
  static final AuditorProfileService instance = AuditorProfileService._();

  /// GET ?user_id=N
  Future<AuditorProfile> fetchProfile(int userId) async {
    final uri = ApiConfig.endpoint(AuditorEndpoints.profile)
        .replace(queryParameters: {'user_id': '$userId'});

    final res = await http.get(uri).timeout(ApiConfig.timeout);
    final body = _decode(res);

    if (res.statusCode != 200 || body['status'] != 'success') {
      throw AuditorProfileException(
        body['message']?.toString() ?? 'Failed to load profile.',
      );
    }
    return AuditorProfile.fromJson(
      Map<String, dynamic>.from(body['data'] as Map),
    );
  }

  /// POST {user_id, name, email, phone, password?}
  /// Pass [password] only when the user actually wants to change it —
  /// profile.php treats an empty/omitted password as "leave unchanged".
  Future<AuditorProfile> updateProfile({
    required int userId,
    required String name,
    required String email,
    required String phone,
    String? password,
  }) async {
    final uri = ApiConfig.endpoint(AuditorEndpoints.profile);

    final res = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'name': name,
            'email': email,
            'phone': phone,
            if (password != null && password.isNotEmpty) 'password': password,
          }),
        )
        .timeout(ApiConfig.timeout);

    final body = _decode(res);

    if (res.statusCode != 200 || body['status'] != 'success') {
      throw AuditorProfileException(
        body['message']?.toString() ?? 'Failed to update profile.',
      );
    }
    return AuditorProfile.fromJson(
      Map<String, dynamic>.from(body['data'] as Map),
    );
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('Unexpected response shape.');
    } catch (_) {
      throw AuditorProfileException(
        'Server returned an unreadable response (HTTP ${res.statusCode}).',
      );
    }
  }
}

class AuditorProfileException implements Exception {
  final String message;
  const AuditorProfileException(this.message);
  @override
  String toString() => message;
}