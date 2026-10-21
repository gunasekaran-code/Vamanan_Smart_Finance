import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../services/wallet_account_service.dart' show WalletServiceException;
import '../models/export_payout_model.dart';

/// Everything ExportPayoutsScreen needs, across four existing endpoints:
///
///  READ   `admin/withdrawals.php`        → the pending-transfer queue
///  READ   `admin/payout_history.php`     → the four stat cards + payout rows
///  READ   `admin/export_payouts.php`     → past export batches
///  CREATE `admin/export_payouts.php`     → log a new export batch
///  UPDATE `admin/process_withdrawal.php` → approve / reject one payout
///
/// There is no DELETE anywhere in this area: neither `export_history` rows
/// nor withdrawal requests can be removed through the API. Rejecting a
/// payout (which refunds the customer) is the closest thing, and that is a
/// status update, not a delete.
class ExportPayoutsService {
  /// READ — payouts awaiting a bank transfer.
  ///
  /// Returns every withdrawal request; the screen filters by status so the
  /// approved/rejected history stays visible. Pass [userId] to narrow to a
  /// single investor (the endpoint's `?user_id=` filter).
  Future<List<PendingPayout>> fetchPendingPayouts({String? userId}) async {
    var uri = ApiConfig.endpoint(AdminEndpoints.withdrawals);
    if (userId != null && userId.trim().isNotEmpty) {
      uri = uri.replace(queryParameters: {'user_id': userId.trim()});
    }
    final body = await _getJson(uri, 'Failed to load pending payouts.');
    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map>()
        .map((e) => PendingPayout.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// READ — the stat-card aggregates.
  Future<PayoutStats> fetchStats() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.payoutHistory);
    final body = await _getJson(uri, 'Failed to load payout statistics.');
    return PayoutStats.fromJson(body['stats'] as Map<String, dynamic>?);
  }

  /// READ — stat cards and the latest cashback payout transactions (the
  /// endpoint returns both in one response).
  Future<PayoutHistoryBundle> fetchPayoutHistory() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.payoutHistory);
    final body = await _getJson(uri, 'Failed to load payouts.');
    final data = body['data'] as List<dynamic>? ?? const [];
    return PayoutHistoryBundle(
      stats: PayoutStats.fromJson(body['stats'] as Map<String, dynamic>?),
      transfers: data
          .whereType<Map>()
          .map((e) => PayoutTransfer.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  /// READ — past export batches.
  Future<List<ExportHistoryRecord>> fetchExportHistory() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.exportPayouts);
    final body = await _getJson(uri, 'Failed to load export history.');
    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map>()
        .map((e) => ExportHistoryRecord.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// CREATE — logs one export batch into `export_history`.
  ///
  /// [transactionIds] must be `transactions.id` values (i.e. from
  /// [PayoutTransfer]); the backend marks those rows `completed`. Never pass
  /// `withdrawals.id` values ([PendingPayout]) — there is no FK between the
  /// two tables, so they would complete unrelated ledger rows.
  Future<void> recordExport({
    required String filename,
    required String exportType,
    required double totalAmount,
    required int totalRecords,
    List<int> transactionIds = const [],
  }) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.exportPayouts);
    final payload = {
      'filename': filename,
      'export_type': exportType,
      'total_amount': totalAmount,
      'total_records': totalRecords,
      if (transactionIds.isNotEmpty) 'transaction_ids': transactionIds,
    };

    final body = await _postJson(uri, payload, 'Failed to record export.');
    // POST returns {status: error} with a 200 on bad input, so _postJson's
    // status check is what catches it.
    if (body['status'] != 'success') {
      throw WalletServiceException(
        body['message']?.toString() ?? 'Failed to record export.',
      );
    }
  }

  /// UPDATE — approve or reject one withdrawal.
  ///
  /// [status] must be `'approved'` or `'rejected'`. Rejecting credits the
  /// locked capital back to the customer's wallet server-side. [utr] is the
  /// bank reference stamped onto the row when approving.
  Future<String> processWithdrawal({
    required String withdrawalId,
    required String status,
    String? utr,
  }) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.processWithdrawal);
    final payload = <String, dynamic>{
      'id': int.tryParse(withdrawalId) ?? withdrawalId,
      'status': status,
      if (utr != null && utr.trim().isNotEmpty) 'transaction_id': utr.trim(),
    };

    final body = await _postJson(uri, payload, 'Failed to process the payout.');
    if (body['status'] != 'success') {
      throw WalletServiceException(
        body['message']?.toString() ?? 'Failed to process the payout.',
      );
    }
    return body['message']?.toString() ?? 'Payout processed successfully.';
  }

  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _getJson(Uri uri, String fallbackError) async {
    try {
      final response = await http.get(uri).timeout(ApiConfig.timeout);
      final body = _decode(response);
      if (response.statusCode != 200 || body['status'] != 'success') {
        throw WalletServiceException(
          body['message']?.toString() ?? fallbackError,
        );
      }
      return body;
    } on WalletServiceException {
      rethrow;
    } catch (_) {
      throw WalletServiceException(
        'Could not reach the server. Please try again.',
      );
    }
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> payload,
    String fallbackError,
  ) async {
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(ApiConfig.timeout);
      final body = _decode(response);
      if (response.statusCode != 200) {
        throw WalletServiceException(
          body['message']?.toString() ?? fallbackError,
        );
      }
      return body;
    } on WalletServiceException {
      rethrow;
    } catch (_) {
      throw WalletServiceException(
        'Could not reach the server. Please try again.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw WalletServiceException('Unexpected response from server.');
    }
  }
}
