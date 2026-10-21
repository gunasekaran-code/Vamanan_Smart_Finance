import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';

/// Fetches the advocate dashboard payload from `/api/advocate/stats.php`.
///
/// The backend returns:
/// {
///   "status": "success" | "error",
///   "data": {
///     "agreements": [...],
///     "kyc_pending": [...],
///     "disputes": [...],
///     "activities": [...],
///     "purchases": [...],
///     "stats": { active_members, pending_agreements, active_agreements,
///                active_disputes, compliance_score, total_docs }
///   },
///   "message": "..."   // present on error
/// }
class AdvocateDashboardService {
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final uri = ApiConfig.endpoint(AdvocateEndpoints.dashboardStats);

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    late final http.Response response;
    try {
      response = await http.get(uri, headers: headers).timeout(ApiConfig.timeout);
    } catch (e) {
      throw Exception('Could not reach the server: $e');
    }

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}. Please try again.');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Received an unexpected response from the server.');
    }

    if (decoded['status'] != 'success') {
      throw Exception(decoded['message']?.toString() ?? 'Failed to load dashboard data.');
    }

    return (decoded['data'] as Map<String, dynamic>?) ?? {};
  }
}