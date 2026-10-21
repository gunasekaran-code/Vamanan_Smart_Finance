// auditor_cashback_application_service.dart — calls /customer/cashback_application.php
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/network/json_envelope.dart';
import '../../models/auditor_cashback_application_model.dart';

class AuditorCashbackApplicationService {
  AuditorCashbackApplicationService._();

  /// GET /customer/cashback_application.php?user_id=
  static Future<CashbackApplicationPrefill> fetchPrefill(int userId) async {
    final uri = ApiConfig.endpoint(CustomerEndpoints.cashbackApplication)
        .replace(queryParameters: {'user_id': '$userId'});
    final res = await http.get(uri, headers: _headers()).timeout(ApiConfig.timeout);
    final body = _decode(res);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to load applicant details');
    }
    return CashbackApplicationPrefill.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// POST /customer/cashback_application.php
  static Future<CashbackApplicationSubmitResult> submit(
    CashbackApplicationRequest request,
  ) async {
    final res = await http
        .post(
          ApiConfig.endpoint(CustomerEndpoints.cashbackApplication),
          headers: _headers(),
          body: jsonEncode(request.toJson()),
        )
        .timeout(ApiConfig.timeout);
    final body = _decode(res);
    final result = CashbackApplicationSubmitResult.fromJson(body);
    if (res.statusCode != 200 || !result.success) {
      throw Exception(result.message.isNotEmpty ? result.message : 'Submission failed');
    }
    return result;
  }

  /// Tolerates the PHP notices `config.php` can print ahead of the JSON, and
  /// surfaces what actually came back instead of a generic message.
  static Map<String, dynamic> _decode(http.Response res) {
    try {
      return decodeJsonEnvelope(res);
    } on ServerEnvelopeException catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        // TODO: add 'Authorization': 'Bearer <sanctum token>' if this route
        // ends up behind auth middleware.
      };
}