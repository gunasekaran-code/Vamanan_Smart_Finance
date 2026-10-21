import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/services/session_service.dart';
import '../models/customer_dashboard_model.dart';

/// Thin wrapper around `api/customer/dashboard.php`.
///
/// Deliberately *not* AuditorDashboardService: that one reads
/// `auditor/summary.php`, which aggregates revenue, GST and wallet liability
/// across the whole platform. dashboard.php is scoped to a single
/// `?user_id=`, which is what a customer is entitled to see.
///
/// No backend change is needed — this only calls the endpoint that already
/// exists.
class CustomerDashboardService {
  CustomerDashboardService._();
  static final CustomerDashboardService instance = CustomerDashboardService._();

  /// GET ?user_id=N — defaults to the signed-in user.
  Future<CustomerDashboard> fetchDashboard({String? userId}) async {
    final id = userId ?? SessionService.instance.currentUser?.id ?? '';
    if (id.isEmpty) {
      throw const CustomerDashboardException('No signed-in customer.');
    }

    final uri = ApiConfig.endpoint(CustomerEndpoints.dashboard)
        .replace(queryParameters: {'user_id': id});

    final http.Response res;
    try {
      res = await http.get(uri).timeout(ApiConfig.timeout);
    } catch (_) {
      throw const CustomerDashboardException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    final body = _decode(res);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw CustomerDashboardException(
        body['message']?.toString() ?? 'Failed to load your dashboard.',
      );
    }

    final data = body['data'];
    if (data is! Map) {
      throw const CustomerDashboardException(
        'The server returned an unexpected dashboard payload.',
      );
    }
    return CustomerDashboard.fromJson(Map<String, dynamic>.from(data));
  }

  /// dashboard.php runs the lazy yield cron before responding and can print
  /// PHP notices ahead of the JSON, so fall back to the `{...}` substring the
  /// way ApiClient does.
  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic>? parsed = _tryDecode(res.body);
    if (parsed == null) {
      final start = res.body.indexOf('{');
      final end = res.body.lastIndexOf('}');
      if (start != -1 && end > start) {
        parsed = _tryDecode(res.body.substring(start, end + 1));
      }
    }
    if (parsed == null) {
      throw CustomerDashboardException(
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

class CustomerDashboardException implements Exception {
  final String message;
  const CustomerDashboardException(this.message);
  @override
  String toString() => message;
}
