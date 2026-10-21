import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/models/manager_customer_model.dart';

class ManagerCustomerServiceException implements Exception {
  const ManagerCustomerServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ManagerCustomerService {
  ManagerCustomerService._();
  static final ManagerCustomerService instance = ManagerCustomerService._();

  Future<List<ManagerCustomerModel>> fetchCustomers() async {
    final body = await _request('GET', ManagerEndpoints.customers);
    final rows = body['data'] as List? ?? const [];
    return rows
        .whereType<Map>()
        .map((row) =>
            ManagerCustomerModel.fromJson(Map<String, dynamic>.from(row)))
        .where((customer) => customer.id > 0)
        .where((customer) => customer.role == 'CUSTOMER')
        .toList();
  }

  Future<void> updateCustomer({
    required int id,
    String? status,
    String? role,
    String? password,
  }) async {
    final payload = <String, dynamic>{'id': id};
    if (status != null) payload['status'] = status;
    if (role != null) payload['role'] = role;
    if (password != null && password.isNotEmpty) payload['password'] = password;
    await _request('POST', ManagerEndpoints.updateCustomer, payload: payload);
  }

  Future<void> deleteCustomer(int id) async {
    await _request('POST', ManagerEndpoints.deleteCustomer,
        payload: {'id': id});
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? payload,
  }) async {
    try {
      final uri = ApiConfig.endpoint(endpoint);
      final response = method == 'GET'
          ? await http.get(uri).timeout(ApiConfig.timeout)
          : await http
              .post(
                uri,
                headers: const {'Content-Type': 'application/json'},
                body: jsonEncode(payload ?? const {}),
              )
              .timeout(ApiConfig.timeout);
      final decoded = jsonDecode(response.body);
      final body = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          body['status'] != 'success') {
        throw ManagerCustomerServiceException(
          body['message']?.toString() ?? 'Customer request failed.',
        );
      }
      return body;
    } on ManagerCustomerServiceException {
      rethrow;
    } on FormatException {
      throw const ManagerCustomerServiceException(
          'Invalid response from server.');
    } catch (error) {
      throw ManagerCustomerServiceException('Could not reach server: $error');
    }
  }
}
