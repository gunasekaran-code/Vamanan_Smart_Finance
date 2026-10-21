import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/services/session_service.dart';
import '../../models/feedback_remarks_model.dart';

class FeedbackFeed {
  final List<FeedbackItem> inbox;
  final List<FeedbackItem> sent;
  final int unreadCount;
  FeedbackFeed({required this.inbox, required this.sent, required this.unreadCount});
}

class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<FeedbackFeed> fetchFeedback() async {
    final res = await http
        .get(ApiConfig.endpoint(FeedbackEndpoints.feedback), headers: _headers)
        .timeout(ApiConfig.timeout);

    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to load feedback (${res.statusCode})');
    }
    final data = body['data'] ?? {};
    return FeedbackFeed(
      inbox: (data['inbox'] as List? ?? []).map((e) => FeedbackItem.fromJson(e)).toList(),
      sent: (data['sent'] as List? ?? []).map((e) => FeedbackItem.fromJson(e)).toList(),
      unreadCount: int.tryParse((data['unread_count'] ?? 0).toString()) ?? 0,
    );
  }

  /// Reuses the existing all-users admin endpoint, filtered to customers.
  Future<List<CustomerOption>> fetchCustomers() async {
    final res = await http
        .get(ApiConfig.endpoint(AdminEndpoints.allUsers), headers: _headers)
        .timeout(ApiConfig.timeout);

    final body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw Exception('Failed to load customers (${res.statusCode})');
    }
    final List data = body is List ? body : (body['data'] ?? []);
    return data
        .where((u) => (u['role'] ?? '').toString().toLowerCase() == 'customer')
        .map<CustomerOption>((u) => CustomerOption.fromJson(u))
        .toList();
  }

  Future<void> sendReply({
    required String toUserId,
    String subject = '',
    required String message,
  }) async {
    final currentUser = SessionService.instance.currentUser;
    if (currentUser == null) {
      throw Exception('You must be signed in to send feedback.');
    }

    final res = await http
        .post(
          ApiConfig.endpoint(FeedbackEndpoints.feedback),
          headers: _headers,
          body: jsonEncode({
            'action': 'reply',
            'from_user_id': currentUser.id,
            'to_user_id': toUserId,
            'subject': subject,
            'message': message,
          }),
        )
        .timeout(ApiConfig.timeout);

    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to send feedback (${res.statusCode})');
    }
  }

  Future<void> markRead(String id) async {
    await http
        .post(
          ApiConfig.endpoint(FeedbackEndpoints.feedback),
          headers: _headers,
          body: jsonEncode({'action': 'read', 'id': id}),
        )
        .timeout(ApiConfig.timeout);
  }

  Future<void> deleteFeedback(String id) async {
    final res = await http
        .post(
          ApiConfig.endpoint(FeedbackEndpoints.feedback),
          headers: _headers,
          body: jsonEncode({'action': 'delete', 'id': id}),
        )
        .timeout(ApiConfig.timeout);

    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to delete (${res.statusCode})');
    }
  }
}