import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../models/auditor_dashboard_model.dart';

class AuditorDashboardService {
  AuditorDashboardService._();
  static final AuditorDashboardService instance = AuditorDashboardService._();

  Future<AuditorDashboardSummary> fetchSummary() async {
    final response = await http
        .get(ApiConfig.endpoint(AuditorEndpoints.summary))
        .timeout(ApiConfig.timeout);

    final decoded = _decode(response.body);
    if (response.statusCode != 200 || decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'Failed to load auditor dashboard');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Auditor dashboard returned an invalid response');
    }
    return AuditorDashboardSummary.fromJson(data);
  }

  Map<String, dynamic> _decode(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {'status': 'error', 'message': 'Malformed server response'};
    }
  }
}
