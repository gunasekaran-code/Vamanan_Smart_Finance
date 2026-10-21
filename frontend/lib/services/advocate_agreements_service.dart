import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../models/advocate_agreements_model.dart';

class AgreementsService {
  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
      };

  /// GET /api/advocate/stats.php — returns the `agreements` list, mapped
  /// to [AgreementModel]. The endpoint also returns kyc/disputes/activities/
  /// purchases/stats, which this call ignores.
  Future<List<AgreementModel>> fetchAgreements() async {
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
      throw Exception(decoded['message']?.toString() ?? 'Failed to load agreements.');
    }

    final data = decoded['data'] as Map<String, dynamic>? ?? {};
    final agreements = data['agreements'] as List<dynamic>? ?? [];

    return agreements
        .map((a) => AgreementModel.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/advocate/actions.php  {"action": "sign_agreement", "id": id}
  ///
  /// NOTE: 'sign_agreement' is assumed to match the naming convention used
  /// elsewhere in your actions endpoints (approve_purchase, approve_kyc,
  /// etc). Since I don't have advocate/actions.php, confirm this case
  /// exists in its switch statement — add it there if it doesn't, without
  /// changing anything else in that file.
  Future<void> signAgreement(int id) async {
    final uri = ApiConfig.endpoint(AdvocateEndpoints.actions);

    late final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({'action': 'sign_agreement', 'id': id}),
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
      throw Exception(decoded['message']?.toString() ?? 'Failed to sign agreement.');
    }
  }
}