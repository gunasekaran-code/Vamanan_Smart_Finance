// auditor_cashback_service.dart — calls /auditor/summary.php and /auditor/ledger.php
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../models/auditor_cashback_model.dart';

class AuditorCashbackService {
  AuditorCashbackService._();

  /// GET /auditor/summary.php
  static Future<CashbackSummary> fetchSummary() async {
    final res = await http
        .get(ApiConfig.endpoint(AuditorEndpoints.summary), headers: _headers())
        .timeout(ApiConfig.timeout);
    final body = _decode(res);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to load cashback summary');
    }
    return CashbackSummary.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// GET /auditor/ledger.php — pass category: 'cashback' | 'referral' | null (= all)
  static Future<LedgerResponse> fetchLedger({
    String? category,
    int? userId,
    String? from,
    String? to,
    String? status,
    String? type,
    String? search,
    int limit = 300,
  }) async {
    final params = <String, String>{
      if (category != null && category != 'all') 'category': category,
      if (userId != null) 'user_id': '$userId',
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (status != null && status != 'all') 'status': status,
      if (type != null && type != 'all') 'type': type,
      if (search != null && search.isNotEmpty) 'search': search,
      'limit': '$limit',
    };
    final uri = ApiConfig.endpoint(AuditorEndpoints.ledger)
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers()).timeout(ApiConfig.timeout);
    final body = _decode(res);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to load cashback ledger');
    }
    return LedgerResponse.fromJson(body);
  }

  /// Convenience: today's credited cashback + referral amount for the "TODAY'S EARNING" card.
  static Future<double> fetchTodayEarning({int? userId}) async {
    final today = DateTime.now();
    final ymd =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final res = await fetchLedger(
      from: ymd,
      to: ymd,
      type: 'credit',
      userId: userId,
      limit: 1,
    );
    return res.summary.totalCredits;
  }

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'status': 'error', 'message': 'Invalid server response'};
    }
  }

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        // TODO: add 'Authorization': 'Bearer <sanctum token>' here if
        // /auditor/*.php sits behind auth middleware.
      };
}