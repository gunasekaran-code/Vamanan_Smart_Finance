import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../models/market_rate_model.dart';

class MarketRatesService {
  /// Triggers a live gold-price sync. Ignores any locally-typed value —
  /// the backend fetches its own spot price and overwrites the stored rate.
  Future<MarketRateSyncResult> syncGoldRate() async {
    final uri = ApiConfig.endpoint(TallyEndpoints.syncMarketRate);

    http.Response response;
    try {
      response = await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw MarketRateException('Could not reach the server: $e');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw MarketRateException('Unexpected response (HTTP ${response.statusCode}).');
    }

    if (response.statusCode != 200 || body['status'] != 'success') {
      throw MarketRateException(body['message']?.toString() ?? 'Rate sync failed.');
    }

    return MarketRateSyncResult.fromJson(body);
  }

  /// Reuses the existing, already-wired monthly-yield endpoint.
  Future<Map<String, dynamic>> processMonthlyYield() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.processMonthlyYield);

    http.Response response;
    try {
      response = await http.post(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw MarketRateException('Could not reach the server: $e');
    }

    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw MarketRateException('Unexpected response (HTTP ${response.statusCode}).');
    }
  }
}