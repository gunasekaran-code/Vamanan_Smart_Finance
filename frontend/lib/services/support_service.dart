import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/network/api_response.dart';
import '../../models/support_model.dart';

class SupportService {
  SupportService._();
  static final SupportService instance = SupportService._();

  /// GET admin/get_all_notifications.php
  /// The PHP has no filtering/pagination — it always returns the latest
  /// 50 rows across all users, so there are no query params to pass here.
  Future<ApiResponse<List<SupportNotification>>> fetchNotifications() async {
    try {
      final uri = ApiConfig.endpoint(NotificationEndpoints.list);
      final res = await http.get(uri).timeout(ApiConfig.timeout);
      final decoded = _decode(res.body);

      if (decoded is Map && decoded['status'] == 'success') {
        final rows = (decoded['data'] as List? ?? [])
            .map((e) => SupportNotification.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
        return ApiResponse.success(rows);
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