import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../models/advocate_purchase_model.dart';

class AdvocatePurchaseService {
  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
      };

  /// GET /api/advocate/stats.php — returns the `purchases` list, mapped
  /// to [PurchaseModel]. The endpoint also returns agreements/kyc/disputes/
  /// activities/stats, which this call ignores; use AdvocateDashboardService
  /// for those.
  Future<List<PurchaseModel>> fetchPurchases() async {
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
      throw Exception(decoded['message']?.toString() ?? 'Failed to load purchases.');
    }

    final data = decoded['data'] as Map<String, dynamic>? ?? {};
    final purchases = data['purchases'] as List<dynamic>? ?? [];

    return purchases
        .map((p) => PurchaseModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/advocate/actions.php  {"action": "approve_purchase", "id": id}
  Future<void> approvePurchase(int id) => _postAction('approve_purchase', id);

  /// POST /api/advocate/actions.php  {"action": "reject_purchase", "id": id}
  Future<void> rejectPurchase(int id) => _postAction('reject_purchase', id);

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