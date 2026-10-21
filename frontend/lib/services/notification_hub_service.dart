import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../models/notification_hub_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<List<NotificationLog>> fetchLogs() async {
    final res = await http
        .get(ApiConfig.endpoint(NotificationEndpoints.list), headers: _headers)
        .timeout(ApiConfig.timeout);

    final body = _decodeResponse(res, 'load notifications');
    final List data = body is List ? body : (body['data'] ?? []);
    return data.map((e) => NotificationLog.fromJson(e)).toList();
  }

  Future<NotificationLog> dispatch({
    required String title,
    required String message,
    required String recipient,
    required String priority,
    String? userId,
  }) async {
    final res = await http
        .post(
          ApiConfig.endpoint(NotificationEndpoints.dispatch),
          headers: _headers,
          body: jsonEncode({
            'title': title,
            'message': message,
            'user_id': userId ?? _userIdFromRecipient(recipient),
            'type': priority.toLowerCase(),
          }),
        )
        .timeout(ApiConfig.timeout);

    final body = _decodeResponse(res, 'dispatch notification');
    final data = body['data'];
    return NotificationLog.fromJson(data is Map<String, dynamic> ? data : {
      'id': '',
      'title': title,
      'message': message,
      'recipient': recipient,
      'type': priority,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateLog({
    required String id,
    required String title,
    required String message,
    required String recipient,
    required String priority,
    String? userId,
  }) async {
    final res = await http
        .post(
          ApiConfig.endpoint(NotificationEndpoints.update),
          headers: _headers,
          body: jsonEncode({
            'id': id,
            'title': title,
            'message': message,
            'user_id': userId ?? _userIdFromRecipient(recipient),
            'type': priority.toLowerCase(),
          }),
        )
        .timeout(ApiConfig.timeout);
    _decodeResponse(res, 'update notification');
  }

  Future<void> deleteLog(String id) async {
    final res = await http
        .post(
          ApiConfig.endpoint(NotificationEndpoints.delete),
          headers: _headers,
          body: jsonEncode({'id': id}),
        )
        .timeout(ApiConfig.timeout);

    _decodeResponse(res, 'delete notification');
  }

  String? _userIdFromRecipient(String recipient) {
    final trimmed = recipient.trim();
    if (trimmed.isEmpty || trimmed == 'GLOBAL BROADCAST (ALL INVESTORS)' ||
        trimmed == 'ACTIVE INVESTORS ONLY' || trimmed == 'STAFF & ADMINS' ||
        trimmed == 'SPECIFIC USER (ID)') {
      return null;
    }
    return trimmed;
  }

  dynamic _decodeResponse(http.Response response, String operation) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Failed to $operation: invalid server response (${response.statusCode})');
    }
    if (response.statusCode < 200 || response.statusCode >= 300 ||
        (decoded is Map && decoded['status'] != null && decoded['status'] != 'success')) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Failed to $operation (${response.statusCode})');
    }
    return decoded;
  }
}