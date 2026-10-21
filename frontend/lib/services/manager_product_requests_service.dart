import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/network/api_response.dart';
import '../../models/manager_product_requests_model.dart';

/// Talks to `admin/product_requests.php`.
/// GET  -> list every product request (all statuses)
/// POST -> update a single request's status (+ optional admin note)
class ProductRequestService {
  ProductRequestService._();
  static final ProductRequestService instance = ProductRequestService._();

  Future<ApiResponse<List<ProductRequest>>> fetchRequests() async {
    try {
      final uri = ApiConfig.endpoint(AdminEndpoints.productRequests);
      final res = await http.get(uri).timeout(ApiConfig.timeout);

      final decoded = _tryDecode(res.body);
      if (decoded == null) {
        return ApiResponse.failure('Unexpected response from server.');
      }

      final ok = decoded['status'] == 'success';
      final rawList = decoded['data'];
      if (ok && rawList is List) {
        final requests = rawList
            .whereType<Map>()
            .map((e) => ProductRequest.fromJson(e.cast<String, dynamic>()))
            .toList();
        return ApiResponse.success(requests);
      }

      return ApiResponse.failure(
        (decoded['message'] as String?) ?? 'Failed to load product requests.',
      );
    } catch (e) {
      return ApiResponse.failure('Could not reach the server: $e');
    }
  }

  /// [status] must be one of: pending, reviewing, approved, rejected, fulfilled
  Future<ApiResponse<void>> updateStatus({
    required int id,
    required String status,
    String? adminNote,
  }) async {
    try {
      final uri = ApiConfig.endpoint(AdminEndpoints.productRequests);
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': id,
              'status': status,
              if (adminNote != null) 'admin_note': adminNote,
            }),
          )
          .timeout(ApiConfig.timeout);

      final decoded = _tryDecode(res.body);
      if (decoded != null && decoded['status'] == 'success') {
        return ApiResponse.success(null);
      }

      return ApiResponse.failure(
        (decoded?['message'] as String?) ?? 'Failed to update the request.',
      );
    } catch (e) {
      return ApiResponse.failure('Could not reach the server: $e');
    }
  }

  Future<ApiResponse<void>> approve(int id, {String? adminNote}) =>
      updateStatus(id: id, status: 'approved', adminNote: adminNote);

  Future<ApiResponse<void>> reject(int id, {String? adminNote}) =>
      updateStatus(id: id, status: 'rejected', adminNote: adminNote);

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      final v = jsonDecode(body);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }
}