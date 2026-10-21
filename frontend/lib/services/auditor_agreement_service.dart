import 'dart:convert';

import 'package:frontend/core/config/api_config.dart';
import 'package:http/http.dart' as http;

import '../models/auditor_agreement_model.dart';

class AuditorAgreementService {
  AuditorAgreementService._();
  static final instance = AuditorAgreementService._();

  Future<AuditorAgreement> fetch(String userId) async {
    final uri = ApiConfig.endpoint(CustomerEndpoints.agreement)
        .replace(queryParameters: {'user_id': userId});
    final response = await http.get(uri).timeout(ApiConfig.timeout);
    final body = _decode(response);
    if (response.statusCode != 200 || body['status'] != 'success') {
      throw AuditorAgreementException(
        body['message']?.toString() ?? 'Could not load the agreement.',
      );
    }
    return AuditorAgreement.fromJson(body['data'] as Map<String, dynamic>);
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'status': 'error', 'message': 'Unexpected server response.'};
    }
  }
}

class AuditorAgreementException implements Exception {
  final String message;
  AuditorAgreementException(this.message);
  @override
  String toString() => message;
}
