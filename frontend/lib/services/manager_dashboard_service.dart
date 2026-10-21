import 'dart:convert';
import 'package:http/http.dart' as http;
// TODO: Import your actual api_config.dart path here
import 'package:frontend/core/config/api_config.dart';

class ManagerDashboardService {
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    try {
      final url = ApiConfig.endpoint(ManagerEndpoints.dashboardStats);
      final response = await http.get(url).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data'];
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load dashboard data');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}