// lib/features/auditor/services/referral_service.dart
//
// Adjust the import paths below to match where you placed api_config.dart
// and referral_summary.dart in your project.

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:frontend/core/config/api_config.dart';
import '../../models/auditor_referral_model.dart';

class ReferralService {
  ReferralService._();
  static final ReferralService instance = ReferralService._();

  /// Fetches the full referral snapshot (code, rates, direct members,
  /// history) for [userId]. Throws on network failure or a non-success
  /// API response, so callers can drive loading/error UI off a try/catch.
  Future<ReferralSummary> fetchSummary(String userId) async {
    final uri = ApiConfig.endpoint(AuditorEndpoints.referralSummary)
        .replace(queryParameters: {'user_id': userId});

    final http.Response response;
    try {
      response = await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw ReferralServiceException('Could not reach the server: $e');
    }

    if (response.statusCode != 200) {
      throw ReferralServiceException(
        'Server returned ${response.statusCode}',
      );
    }

    late final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ReferralServiceException('Unexpected response from server');
    }

    if (body['status'] != 'success') {
      throw ReferralServiceException(
        (body['message'] ?? 'Unknown error').toString(),
      );
    }

    return ReferralSummary.fromJson(body['data'] as Map<String, dynamic>);
  }
}

class ReferralServiceException implements Exception {
  final String message;
  ReferralServiceException(this.message);

  @override
  String toString() => message;
}