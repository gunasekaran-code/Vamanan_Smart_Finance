import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_request_model.dart';
import 'package:frontend/core/config/api_config.dart';

class ProductRequestServiceException implements Exception {
  final String message;
  ProductRequestServiceException(this.message);
  @override
  String toString() => message;
}

class ProductRequestService {
  ProductRequestService._();
  static final ProductRequestService instance = ProductRequestService._();

  static const String _path = 'admin/product_requests.php';

  static const Map<String, String> _headers = {'Content-Type': 'application/json'};

  Future<List<ProductRequest>> fetchAll() async {
    final res = await http.get(ApiConfig.endpoint(_path), headers: _headers).timeout(ApiConfig.timeout);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw ProductRequestServiceException(body['message']?.toString() ?? 'Failed to load requests (${res.statusCode}).');
    }
    return (body['data'] as List<dynamic>? ?? [])
        .map((e) => ProductRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateStatus({
    required int id,
    required String status, // pending | reviewing | approved | rejected | fulfilled
    String? adminNote,
  }) async {
    final res = await http
        .post(
          ApiConfig.endpoint(_path),
          headers: _headers,
          body: jsonEncode({'id': id, 'status': status, if (adminNote != null) 'admin_note': adminNote}),
        )
        .timeout(ApiConfig.timeout);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw ProductRequestServiceException(body['message']?.toString() ?? 'Update failed (${res.statusCode}).');
    }
  }
}