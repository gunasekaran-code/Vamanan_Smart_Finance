import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';

import '../models/cashback_monitoring_model.dart';

class CashbackMonitoringService {
	CashbackMonitoringService({http.Client? client}) : _client = client ?? http.Client();

	final http.Client _client;

	Future<CashbackMonitoringResult> fetchMonitoringData() async {
		final response = await _client
				.get(ApiConfig.endpoint(AdminEndpoints.cashbackApplications))
				.timeout(ApiConfig.timeout);

		Map<String, dynamic> body;
		try {
			final decoded = jsonDecode(response.body);
			body = decoded is Map
					? Map<String, dynamic>.from(decoded)
					: <String, dynamic>{};
		} catch (_) {
			throw const CashbackMonitoringException('The server returned invalid data.');
		}

		if (response.statusCode != 200 || body['status'] != 'success') {
			throw CashbackMonitoringException(
				body['message']?.toString() ?? 'Failed to load cashback monitoring data.',
			);
		}

		return CashbackMonitoringResult.fromJson(body);
	}

	void dispose() => _client.close();
}

class CashbackMonitoringException implements Exception {
	final String message;

	const CashbackMonitoringException(this.message);

	@override
	String toString() => message;
}
