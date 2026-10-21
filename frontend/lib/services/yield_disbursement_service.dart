import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';

// Reusing WalletServiceException here rather than a new type — a "failed to
// reach/parse the backend" error means the same thing regardless of which
// feature hit it, and the UI-facing message shape is identical.
import '../../../services/wallet_account_service.dart' show WalletServiceException;

import '../models/yield_disbursement_model.dart';

/// Backs YieldDisbursementsScreen.
///
/// There is no `admin/yield_disbursements.php` on the backend — it 404s. The
/// screen's data is split across two endpoints that DO exist, so this service
/// calls both in parallel and merges them:
///
///  - `admin/payout_reports.php` → the table rows. Every `cashback` and
///    `referral` transaction (last 500) with gross / TDS / charges and the
///    payee's bank details, which is exactly what YieldDisbursement models.
///  - `admin/payout_history.php` → the four stat cards. Its `stats` block is
///    computed with unbounded SQL aggregates (today, this month, active
///    cycles, all-time), so the totals stay correct no matter how many rows
///    the table itself is limited to.
///
/// Caveat worth knowing: `payout_history.php` aggregates `category =
/// 'cashback'` only, while the rows below include referral commission too, so
/// the stat cards can read slightly lower than the sum of the visible table.
/// Fixing that properly needs a backend change.
class YieldService {
  Future<YieldDashboardData> fetchDashboard() async {
    try {
      final responses = await Future.wait([
        _getJson(AdminEndpoints.payoutReports),
        _getJson(AdminEndpoints.payoutHistory),
      ]);

      final reports = responses[0];
      final history = responses[1];

      // payout_reports.php nests everything under `data`.
      final reportData = reports['data'] as Map<String, dynamic>? ?? const {};

      return YieldDashboardData(
        // payout_history.php returns its aggregates under a top-level `stats`.
        summary: YieldSummary.fromJson(history['stats'] as Map<String, dynamic>?),
        disbursements: YieldDashboardData.parseRows(
          reportData['history'],
          monthsPaidByTxId: YieldDashboardData.monthsPaidIndex(history['data']),
        ),
      );
    } on WalletServiceException {
      rethrow;
    } catch (_) {
      throw WalletServiceException(
        'Could not reach the server. Please try again.',
      );
    }
  }

  Future<Map<String, dynamic>> _getJson(String endpoint) async {
    final uri = ApiConfig.endpoint(endpoint);
    final response = await http.get(uri).timeout(ApiConfig.timeout);
    final body = _decode(response);

    if (response.statusCode != 200 || body['status'] != 'success') {
      throw WalletServiceException(
        body['message']?.toString() ?? 'Failed to load yield disbursements.',
      );
    }
    return body;
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw WalletServiceException('Unexpected response from server.');
    }
  }
}
