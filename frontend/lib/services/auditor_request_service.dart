// service/auditor_request_service.dart
//
// Talks to api/customer/product_request.php only (never the admin endpoint):
//   GET  customer/product_request.php?user_id=123   -> prefill user info + this user's past requests
//   POST customer/product_request.php                -> submit a new request
//
// Not in ApiConfig's endpoint classes yet, so called by literal path. If you
// want it centralized, add to api_config.dart, e.g.:
//   class CustomerEndpoints { CustomerEndpoints._();
//     static const String productRequest = 'customer/product_request.php'; }

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:frontend/core/config/api_config.dart';
import '../../models/auditor_request_model.dart';

class AuditorRequestService {
  static const String _path = 'customer/product_request.php';

  /// Fetches the logged-in customer's info (for the read-only "Requested By"
  /// fields) plus their previously submitted product requests.
  static Future<ProductRequestPrefill> fetchPrefill(int userId) async {
    final uri = ApiConfig.endpoint(_path).replace(
      queryParameters: {'user_id': userId.toString()},
    );

    late final http.Response response;
    try {
      response = await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw ProductRequestException('Could not reach the server: $e');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ProductRequestException('Could not parse server response');
    }

    if (decoded['status'] != 'success') {
      throw ProductRequestException((decoded['message'] ?? 'Failed to load requests').toString());
    }

    final data = decoded['data'] as Map<String, dynamic>? ?? {};
    final user = CustomerInfo.fromJson((data['user'] as Map<String, dynamic>?) ?? {});
    final requestsJson = (data['requests'] as List<dynamic>?) ?? [];
    final requests = requestsJson
        .map((r) => ProductRequestItem.fromJson(r as Map<String, dynamic>))
        .toList();

    return ProductRequestPrefill(user: user, requests: requests);
  }

  /// Submits a new product request. Returns the new request's id.
  static Future<int> submitRequest({
    required int userId,
    required String customerName,
    String? customerCode,
    String? customerEmail,
    String? phone,
    required String productName,
    String? model,
    String category = 'Gold',
    int quantity = 1,
    double weight = 0,
    String? description,
  }) async {
    final uri = ApiConfig.endpoint(_path);

    final body = json.encode({
      'user_id': userId,
      'customer_name': customerName,
      'customer_code': customerCode ?? '',
      'customer_email': customerEmail ?? '',
      'phone': phone ?? '',
      'product_name': productName,
      'model': model ?? '',
      'category': category,
      'quantity': quantity,
      'weight': weight,
      'description': description ?? '',
    });

    late final http.Response response;
    try {
      response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(ApiConfig.timeout);
    } catch (e) {
      throw ProductRequestException('Could not reach the server: $e');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ProductRequestException('Could not parse server response');
    }

    if (decoded['status'] != 'success') {
      throw ProductRequestException((decoded['message'] ?? 'Submission failed').toString());
    }

    final id = decoded['request_id'];
    if (id is int) return id;
    return int.tryParse(id.toString()) ?? 0;
  }
}

class ProductRequestException implements Exception {
  final String message;
  ProductRequestException(this.message);

  @override
  String toString() => message;
}