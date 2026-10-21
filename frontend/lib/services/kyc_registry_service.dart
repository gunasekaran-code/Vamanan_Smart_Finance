import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../models/kyc_registry_model.dart';

class KycRegistryService {
  Future<List<KycCustomer>> fetchPendingKyc() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.allUsers);

    http.Response response;
    try {
      response = await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw KycRegistryException('Could not reach the server: $e');
    }

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw KycRegistryException('Unexpected response (HTTP ${response.statusCode}).');
    }

    List<dynamic> rows;
    if (body is List) {
      rows = body;
    } else if (body is Map<String, dynamic>) {
      if (body['status'] != null && body['status'] != 'success') {
        throw KycRegistryException(body['message']?.toString() ?? 'Failed to load users.');
      }
      rows = (body['data'] ?? body['users'] ?? []) as List<dynamic>;
    } else {
      throw KycRegistryException('Unexpected response shape.');
    }

    final all = rows.map((e) => KycCustomer.fromJson(e as Map<String, dynamic>)).toList();
    return all.where((c) => c.isPending).toList();
  }

  Future<KycActionResult> _updateStatus(String userId, String status) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.updateUser);

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': userId, 'kyc_status': status}),
          )
          .timeout(ApiConfig.timeout);
    } catch (e) {
      throw KycRegistryException('Could not reach the server: $e');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw KycRegistryException('Unexpected response (HTTP ${response.statusCode}).');
    }

    final result = KycActionResult.fromJson(body);
    if (!result.success) {
      throw KycRegistryException(result.message.isNotEmpty ? result.message : 'Update failed.');
    }
    return result;
  }

  Future<KycActionResult> approve(String userId) => _updateStatus(userId, 'verified');
  Future<KycActionResult> reject(String userId) => _updateStatus(userId, 'rejected');

  /// Uses the existing, already-wired monthly-yield endpoint.
  Future<KycActionResult> processMonthlyYield() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.processMonthlyYield);

    http.Response response;
    try {
      response = await http.post(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw KycRegistryException('Could not reach the server: $e');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw KycRegistryException('Unexpected response (HTTP ${response.statusCode}).');
    }

    return KycActionResult.fromJson(body);
  }
}