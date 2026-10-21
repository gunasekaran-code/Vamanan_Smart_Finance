import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../../models/payout_report_model.dart';

class PayoutReportsService {
  Future<PayoutReportsData> fetchReports() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.payoutReports);

    http.Response response;
    try {
      response = await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw PayoutReportsException('Could not reach the server: $e');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw PayoutReportsException(
        'Unexpected response (HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode != 200 || body['status'] != 'success') {
      throw PayoutReportsException(
        body['message']?.toString() ?? 'Failed to load payout reports.',
      );
    }

    return PayoutReportsData.fromJson(body);
  }
}