import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:frontend/core/config/api_config.dart';
import '../../models/referral_reports_model.dart';

class ReferralApiException implements Exception {
  final String message;
  ReferralApiException(this.message);
  @override
  String toString() => message;
}

class ReferralService {
  /// GET admin/payout_reports.php — aggregate stats, deduction breakdown,
  /// elite referrers. Shape is assumed; see referral_model.dart.
  Future<ReferralReportBundle> fetchReport() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.payoutReports);
    final res = await _get(uri);
    final body = _safeDecode(res.body);
    _assertSuccess(res, body);

    final data = body['data'];
    final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

    final summary = ReferralSummary.fromJson(map);

    final elitesRaw = _pick(map, ['elite_referrers', 'top_referrers', 'leaderboard']);
    final elites = (elitesRaw is List)
        ? elitesRaw
            .whereType<Map>()
            .map((e) => EliteReferrer.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <EliteReferrer>[];

    return ReferralReportBundle(summary: summary, eliteReferrers: elites);
  }

  /// GET admin/payout_history.php — the protocol history table rows.
  /// Shape is assumed; see referral_model.dart.
  Future<List<ReferralHistoryEntry>> fetchHistory() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.payoutHistory);
    final res = await _get(uri);
    final body = _safeDecode(res.body);
    _assertSuccess(res, body);

    final data = body['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => ReferralHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// POST admin/toggle_referral.php — pause/resume a member's referral
  /// commissions. Fully specified; safe as-is.
  Future<bool> setReferralActive({required int userId, required bool active}) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.toggleReferral);

    late final http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'active': active ? 1 : 0,
            }),
          )
          .timeout(ApiConfig.timeout);
    } catch (e) {
      throw ReferralApiException('Could not reach the server: $e');
    }

    final body = _safeDecode(res.body);
    _assertSuccess(res, body);

    final returned = body['referral_active'];
    if (returned is num) return returned != 0;
    return active;
  }

  // --- internals ---

  Future<http.Response> _get(Uri uri) async {
    try {
      return await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw ReferralApiException('Could not reach the server: $e');
    }
  }

  void _assertSuccess(http.Response res, Map<String, dynamic> body) {
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw ReferralApiException(
        (body['message'] ?? 'Request failed (HTTP ${res.statusCode})').toString(),
      );
    }
  }

  Map<String, dynamic> _safeDecode(String raw) {
    if (raw.isEmpty) {
      return {'status': 'error', 'message': 'Empty response from server'};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {'status': 'error', 'message': 'Unexpected response format'};
    } catch (_) {
      return {'status': 'error', 'message': 'Server returned invalid JSON'};
    }
  }

  dynamic _pick(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (json.containsKey(k) && json[k] != null) return json[k];
    }
    return null;
  }
}

class ReferralReportBundle {
  final ReferralSummary summary;
  final List<EliteReferrer> eliteReferrers;
  ReferralReportBundle({required this.summary, required this.eliteReferrers});
}