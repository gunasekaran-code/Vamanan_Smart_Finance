import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/services/session_service.dart';
import '../models/customer_profile_model.dart';

/// Wraps the `api/customer/*` endpoints behind the customer profile page.
///
/// Two endpoints are deliberately avoided:
///   * `auditor/profile.php` opens with
///     `if ($role !== 'auditor') throw new Exception("Not an auditor account.")`,
///     so it rejects every customer.
///   * `customer/get_profile.php` joins a `kyc_details` table that does not
///     exist in this database and fails with "Base table or view not found".
///
/// `customer/profile.php` has neither problem and returns the wallet balance
/// and portfolio stats as well, so the whole page loads in one request. No
/// backend change is needed.
class CustomerProfileService {
  CustomerProfileService._();
  static final CustomerProfileService instance = CustomerProfileService._();

  String get _sessionUserId => SessionService.instance.currentUser?.id ?? '';

  /// GET customer/profile.php?user_id=N
  Future<CustomerProfile> fetchProfile({String? userId}) async {
    final id = userId ?? _sessionUserId;
    if (id.isEmpty) {
      throw const CustomerProfileException('No signed-in customer.');
    }

    final uri = ApiConfig.endpoint(CustomerEndpoints.profile)
        .replace(queryParameters: {'user_id': id});

    final body = await _send(() => http.get(uri).timeout(ApiConfig.timeout));
    _ensureSuccess(body, 'Failed to load your profile.');

    final data = body['data'];
    if (data is! Map) {
      throw const CustomerProfileException(
        'The server returned an unexpected profile payload.',
      );
    }
    return CustomerProfile.fromJson(Map<String, dynamic>.from(data));
  }

  /// POST customer/update_profile.php
  ///
  /// The endpoint reads `name`, `email`, `phone` and `address` with no null
  /// guard, so all four are required here — a partial body would blow up in
  /// PHP. It replies with a message only, so the merged profile is returned
  /// rather than re-reading it.
  Future<CustomerProfile> updateProfile({
    required CustomerProfile current,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String bankName,
    required String accountNo,
    required String ifscCode,
  }) async {
    if (current.id == 0) {
      throw const CustomerProfileException('No signed-in customer.');
    }

    final body = await _send(
      () => http
          .post(
            ApiConfig.endpoint(CustomerEndpoints.updateProfile),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': current.id,
              'name': name,
              'email': email,
              'phone': phone,
              'address': address,
              'bank_name': bankName,
              'account_no': accountNo,
              'ifsc_code': ifscCode,
            }),
          )
          .timeout(ApiConfig.timeout),
    );
    _ensureSuccess(body, 'Failed to update your profile.');

    return current.copyWith(
      name: name,
      email: email,
      phone: phone,
      address: address,
      bankName: bankName,
      accountNo: accountNo,
      ifscCode: ifscCode,
    );
  }

  /// POST customer/change_password.php {user_id, new_password}
  ///
  /// Note the endpoint does not verify the current password — it overwrites
  /// directly — so the confirmation field on the dialog is the only guard
  /// against a typo locking the account out.
  Future<String> changePassword({
    required String newPassword,
    String? userId,
  }) async {
    final id = userId ?? _sessionUserId;
    if (id.isEmpty) {
      throw const CustomerProfileException('No signed-in customer.');
    }

    final body = await _send(
      () => http
          .post(
            ApiConfig.endpoint(CustomerEndpoints.changePassword),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': id, 'new_password': newPassword}),
          )
          .timeout(ApiConfig.timeout),
    );
    _ensureSuccess(body, 'Failed to update your password.');
    return body['message']?.toString() ?? 'Password updated.';
  }

  /// GET customer/get_feedback.php?user_id=N
  ///
  /// Side effect worth knowing: the endpoint marks every received row read as
  /// it returns them, so opening the FROM TEAM tab clears the unread state.
  Future<CustomerFeedbackThreads> fetchFeedback({String? userId}) async {
    final id = userId ?? _sessionUserId;
    if (id.isEmpty) {
      throw const CustomerProfileException('No signed-in customer.');
    }

    final uri = ApiConfig.endpoint(CustomerEndpoints.getFeedback)
        .replace(queryParameters: {'user_id': id});

    final body = await _send(() => http.get(uri).timeout(ApiConfig.timeout));
    _ensureSuccess(body, 'Failed to load your feedback.');

    final data = body['data'];
    if (data is! Map) return const CustomerFeedbackThreads();
    return CustomerFeedbackThreads.fromJson(Map<String, dynamic>.from(data));
  }

  /// POST customer/submit_feedback.php {user_id, subject, message, rating}
  Future<String> submitFeedback({
    required String message,
    String subject = '',
    int? rating,
    String? userId,
  }) async {
    final id = userId ?? _sessionUserId;
    if (id.isEmpty) {
      throw const CustomerProfileException('No signed-in customer.');
    }

    final body = await _send(
      () => http
          .post(
            ApiConfig.endpoint(CustomerEndpoints.submitFeedback),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': id,
              'subject': subject,
              'message': message,
              // The endpoint treats '' as "no rating"; null would be cast to 0.
              'rating': rating?.toString() ?? '',
            }),
          )
          .timeout(ApiConfig.timeout),
    );
    _ensureSuccess(body, 'Failed to submit your feedback.');
    return body['message']?.toString() ?? 'Feedback submitted.';
  }

  // ==========================================================================
  // TRANSPORT
  // ==========================================================================

  void _ensureSuccess(Map<String, dynamic> body, String fallback) {
    if (body['status'] != 'success') {
      throw CustomerProfileException(body['message']?.toString() ?? fallback);
    }
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final http.Response res;
    try {
      res = await request();
    } catch (_) {
      throw const CustomerProfileException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    // config.php can print PHP notices ahead of the JSON, so fall back to the
    // `{...}` substring the way ApiClient does.
    Map<String, dynamic>? parsed = _tryDecode(res.body);
    if (parsed == null) {
      final start = res.body.indexOf('{');
      final end = res.body.lastIndexOf('}');
      if (start != -1 && end > start) {
        parsed = _tryDecode(res.body.substring(start, end + 1));
      }
    }
    if (parsed == null) {
      throw CustomerProfileException(
        'Server returned an unreadable response (HTTP ${res.statusCode}).',
      );
    }
    return parsed;
  }

  Map<String, dynamic>? _tryDecode(String source) {
    try {
      final value = jsonDecode(source);
      return value is Map<String, dynamic> ? value : null;
    } catch (_) {
      return null;
    }
  }
}

class CustomerProfileException implements Exception {
  final String message;
  const CustomerProfileException(this.message);
  @override
  String toString() => message;
}
