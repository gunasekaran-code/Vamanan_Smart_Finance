import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../models/advocate_customer_model.dart';

class CustomerDirectoryService {
  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
      };

  Future<List<CustomerKycModel>> fetchCustomers() async {
    final uri = ApiConfig.endpoint(AdvocateEndpoints.dashboardStats);

    late final http.Response response;
    try {
      response = await http.get(uri, headers: _headers).timeout(ApiConfig.timeout);
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
      throw Exception(decoded['message']?.toString() ?? 'Failed to load customers.');
    }

    final data = decoded['data'] as Map<String, dynamic>? ?? {};
    final customers = data['kyc_pending'] as List<dynamic>? ?? [];

    return customers
        .map((c) => CustomerKycModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveKyc(int id) => _postAction('approve_kyc', id);

  /// POST /api/advocate/actions.php  {"action": "reject_kyc", "id": id}
  Future<void> rejectKyc(int id) => _postAction('reject_kyc', id);

  Future<void> _postAction(String action, int id) async {
    final uri = ApiConfig.endpoint(AdvocateEndpoints.actions);

    late final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({'action': action, 'id': id}),
          )
          .timeout(ApiConfig.timeout);
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
      throw Exception(decoded['message']?.toString() ?? 'Action failed.');
    }
  }
}