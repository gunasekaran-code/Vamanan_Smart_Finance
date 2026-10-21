import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Added to use XFile
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/models/settings_models.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  Future<PlatformSettings> fetchSettings() async {
    final body = await _request('GET', AdminSettingsEndpoints.settings);
    return PlatformSettings.fromJson(_dataMap(body));
  }

  // Changed to accept XFile? instead of File? for Web Compatibility
  Future<PlatformSettings> saveSettings(Map<String, dynamic> values,
      {XFile? qrImage}) async {
    if (qrImage != null) {
      final uri = ApiConfig.endpoint(AdminSettingsEndpoints.settings);
      final request = http.MultipartRequest('POST', uri);

      values.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Convert image to bytes. This prevents the Flutter Web 'fromPath' crash
      final bytes = await qrImage.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'qr_image', // This must match the $_FILES['qr_image'] key in your PHP backend
        bytes,
        filename: qrImage.name,
      ));

      try {
        final streamedResponse =
            await request.send().timeout(ApiConfig.timeout);
        final response = await http.Response.fromStream(streamedResponse);

        final decoded = jsonDecode(response.body);
        final body =
            decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

        if (response.statusCode < 200 ||
            response.statusCode >= 300 ||
            body['status'] != 'success') {
          throw Exception(body['message'] ??
              'Settings request failed (${response.statusCode})');
        }

        final settings = PlatformSettings.fromJson(_dataMap(body));
        if (settings.value('qr_image_url', '').isEmpty) {
          throw Exception(
            'The server accepted the settings but did not save the QR image. '
            'The PHP settings endpoint must handle the qr_image upload.',
          );
        }
        return settings;
      } on SocketException {
        throw Exception(
            'Could not reach the server. Check your connection and try again.');
      } on FormatException {
        throw Exception('The server returned an invalid response.');
      }
    } else {
      final body = await _request(
        'POST',
        AdminSettingsEndpoints.settings,
        payload: values,
      );
      return PlatformSettings.fromJson(_dataMap(body));
    }
  }

  Future<void> updateAdminProfile({
    required String name,
    required String email,
    String? password,
  }) async {
    final payload = <String, dynamic>{'name': name, 'email': email};
    if (password != null && password.isNotEmpty) payload['password'] = password;
    await _request('POST', AdminSettingsEndpoints.updateProfile,
        payload: payload);
  }

  Future<void> processMonthlyYield() async {
    await _request('POST', AdminSettingsEndpoints.processMonthlyYield);
  }

  Future<List<SettingsStaff>> fetchStaff() async {
    final body = await _request('GET', AdminSettingsEndpoints.allUsers);
    final data = body['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => SettingsStaff.fromJson(item.cast<String, dynamic>()))
        .where((staff) => staff.role != 'customer')
        .toList();
  }

  Future<void> updatePermissions({
    required String userId,
    required List<String> permissions,
  }) async {
    await _request(
      'POST',
      AdminSettingsEndpoints.updatePermissions,
      payload: {'user_id': userId, 'permissions': permissions},
    );
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? payload,
  }) async {
    try {
      final uri = ApiConfig.endpoint(path);
      final response = method == 'GET'
          ? await http.get(uri).timeout(ApiConfig.timeout)
          : await http
              .post(
                uri,
                headers: const {'Content-Type': 'application/json'},
                body: jsonEncode(payload ?? const {}),
              )
              .timeout(ApiConfig.timeout);
      final decoded = jsonDecode(response.body);
      final body =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          body['status'] != 'success') {
        throw Exception(body['message'] ??
            'Settings request failed (${response.statusCode})');
      }
      return body;
    } on SocketException {
      throw Exception(
          'Could not reach the server. Check your connection and try again.');
    } on FormatException {
      throw Exception('The server returned an invalid response.');
    }
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> body) {
    final data = body['data'];
    return data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
  }
}

class AdminSettingsEndpoints {
  AdminSettingsEndpoints._();
  static const settings = 'admin/settings.php';
  static const updateProfile = 'admin/update_profile.php';
  static const updatePermissions = 'admin/update_permissions.php';
  static const allUsers = 'admin/all_users.php';
  static const processMonthlyYield = 'admin/run_daily_payout.php';
}
