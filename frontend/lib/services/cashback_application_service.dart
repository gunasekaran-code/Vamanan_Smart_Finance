import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../models/cashback_application_model.dart';
import 'package:frontend/core/network/api_response.dart';

/// Result wrapper for the list endpoint, which also returns a summary block.
class CashbackApplicationListResult {
  final List<CashbackApplication> applications;
  final int totalCount;
  final double totalAmount;

  const CashbackApplicationListResult({
    required this.applications,
    required this.totalCount,
    required this.totalAmount,
  });
}

/// Talks to api/admin/cashback_applications.php.
///
/// NOTE: that endpoint currently only supports:
///   GET  -> list (optionally filtered by status)
///   POST -> update status (approve / reject / reset to pending)
/// There is no create or delete route on the backend yet, so this service
/// does not expose add()/delete() methods — add a matching PHP action first
/// if you need those.
class CashbackApplicationService {
  CashbackApplicationService._();
  static final CashbackApplicationService instance =
      CashbackApplicationService._();

  Future<ApiResponse<CashbackApplicationListResult>> fetchApplications({
    CashbackStatus? status,
  }) async {
    try {
      var uri = ApiConfig.endpoint(AdminEndpoints.cashbackApplications);
      if (status != null) {
        uri = uri.replace(queryParameters: {'status': status.apiValue});
      }

      final res = await http.get(uri).timeout(ApiConfig.timeout);
      final body = _decode(res.body);

      if (body == null || body['status'] != 'success') {
        return ApiResponse.failure(
          _messageOf(body) ?? 'Failed to load cashback applications.',
        );
      }

      final rows = (body['data'] as List? ?? const [])
          .map((e) => CashbackApplication.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();

      final summary = body['summary'] is Map
          ? Map<String, dynamic>.from(body['summary'] as Map)
          : const <String, dynamic>{};

      return ApiResponse.success(
        CashbackApplicationListResult(
          applications: rows,
          totalCount: int.tryParse('${summary['count']}') ?? rows.length,
          totalAmount: double.tryParse('${summary['total_amount']}') ?? 0.0,
        ),
      );
    } catch (e) {
      return ApiResponse.failure('Could not reach server: $e');
    }
  }

  Future<ApiResponse<bool>> updateStatus({
    required int id,
    required CashbackStatus status,
  }) async {
    try {
      final uri = ApiConfig.endpoint(AdminEndpoints.cashbackApplications);
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': id, 'status': status.apiValue}),
          )
          .timeout(ApiConfig.timeout);

      final body = _decode(res.body);
      if (body != null && body['status'] == 'success') {
        return ApiResponse.success(true, _messageOf(body));
      }
      return ApiResponse.failure(_messageOf(body) ?? 'Update failed.');
    } catch (e) {
      return ApiResponse.failure('Could not reach server: $e');
    }
  }

  Future<ApiResponse<bool>> approve(int id) =>
      updateStatus(id: id, status: CashbackStatus.approved);

  Future<ApiResponse<bool>> reject(int id) =>
      updateStatus(id: id, status: CashbackStatus.rejected);

  Map<String, dynamic>? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  String? _messageOf(Map<String, dynamic>? body) =>
      body == null ? null : body['message']?.toString();
}