import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../models/advocate_disputes_model.dart';

class DisputesService {
  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
      };

  /// GET /api/advocate/stats.php — returns the `disputes` list, mapped to
  /// [DisputeModel].
  Future<List<DisputeModel>> fetchDisputes() async {
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
      throw Exception(decoded['message']?.toString() ?? 'Failed to load disputes.');
    }

    final data = decoded['data'] as Map<String, dynamic>? ?? {};
    final disputes = data['disputes'] as List<dynamic>? ?? [];

    return disputes
        .map((d) => DisputeModel.fromJson(d as Map<String, dynamic>))
        .toList();
  }
}