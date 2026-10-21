import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../models/wallet_account_model.dart';

/// Thrown for any failure talking to the wallet backend. [message] is safe
/// to show directly to the user.
class WalletServiceException implements Exception {
  final String message;
  WalletServiceException(this.message);

  @override
  String toString() => message;
}

class WalletService {
  /// All investor wallets with fintech metadata (balance, earned, withdrawn,
  /// active cycles, last payout, kyc/role).
  Future<List<WalletAccount>> fetchWallets() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.wallets);
    try {
      final response = await http.get(uri).timeout(ApiConfig.timeout);
      final body = _decode(response);

      if (response.statusCode != 200 || body['status'] != 'success') {
        throw WalletServiceException(
          body['message']?.toString() ?? 'Failed to load wallets.',
        );
      }

      final data = body['data'] as List<dynamic>? ?? const [];
      return data
          .map((e) => WalletAccount.fromJson(e as Map<String, dynamic>))
          .toList();
    } on WalletServiceException {
      rethrow;
    } catch (_) {
      throw WalletServiceException(
        'Could not reach the server. Please try again.',
      );
    }
  }

  /// Read the server ledger for one investor. `auditor/ledger.php` is an
  /// admin-readable, user-filterable ledger and returns both rows and totals.
  Future<WalletLedger> fetchLedger(String userId) async {
    final uri = ApiConfig.endpoint('auditor/ledger.php').replace(
      queryParameters: {'user_id': userId, 'limit': '300'},
    );
    try {
      final response = await http.get(uri).timeout(ApiConfig.timeout);
      final body = _decode(response);
      if (response.statusCode != 200 || body['status'] != 'success') {
        throw WalletServiceException(
          body['message']?.toString() ?? 'Failed to load the wallet ledger.',
        );
      }
      final raw = (body['data'] as List? ?? const []).whereType<Map>().toList();
      final rows = raw
          .map((row) => WalletLedgerEntry.fromJson(row.cast<String, dynamic>()))
          .toList();
      final customerId = raw
          .map((row) => (row['customer_id'] ?? '').toString().trim())
          .firstWhere((id) => id.isNotEmpty && id != 'null', orElse: () => '');
      return WalletLedger.fromJson(body['summary'] as Map? ?? const {}, rows,
          customerId: customerId);
    } on WalletServiceException {
      rethrow;
    } catch (_) {
      throw WalletServiceException(
          'Could not reach the server. Please try again.');
    }
  }

  /// One investor's live cashback plan — monthly installment (gross / TDS /
  /// charges / net at the current platform rates), months paid, remaining
  /// cap and wallet totals. Read-only: unlike customer/cashback_plan.php it
  /// does not trigger the lazy yield engine.
  Future<WalletPayoutPlan> fetchPayoutPlan(String userId) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.userPayoutPlan)
        .replace(queryParameters: {'user_id': userId});
    try {
      final response = await http.get(uri).timeout(ApiConfig.timeout);
      final body = _decode(response);
      if (response.statusCode != 200 || body['status'] != 'success') {
        throw WalletServiceException(
          body['message']?.toString() ?? 'Failed to load the payout plan.',
        );
      }
      return WalletPayoutPlan.fromJson(
          (body['data'] as Map? ?? const {}).cast<String, dynamic>());
    } on WalletServiceException {
      rethrow;
    } catch (_) {
      throw WalletServiceException(
          'Could not reach the server. Please try again.');
    }
  }

  /// Manual credit/debit adjustment on one user's wallet.
  ///
  /// [type] must be `'credit'` or `'debit'`. [amount] is the net amount
  /// applied to the wallet balance. The optional gross/TDS/charges fields
  /// let the ledger record a full breakdown (matches the automated yield
  /// engine's transaction shape) — pass them when adjusting a cashback
  /// payout; omit them for a plain manual credit/debit.
  Future<String> adjustWallet({
    required String userId,
    required double amount,
    required String type,
    String reason = 'System adjustment',
    String category = 'purchase',
    double? grossAmount,
    double? tdsAmount,
    double? chargesAmount,
    double? deduction,
  }) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.adjustWallet);
    final payload = <String, dynamic>{
      'user_id': userId,
      'amount': amount,
      'type': type,
      'reason': reason,
      'category': category,
      if (grossAmount != null) 'gross_amount': grossAmount,
      if (tdsAmount != null) 'tds_amount': tdsAmount,
      if (chargesAmount != null) 'charges_amount': chargesAmount,
      if (deduction != null) 'deduction': deduction,
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(ApiConfig.timeout);
      final body = _decode(response);

      if (response.statusCode != 200 || body['status'] != 'success') {
        throw WalletServiceException(
          body['message']?.toString() ?? 'Adjustment failed.',
        );
      }
      return body['message']?.toString() ??
          'Adjustment completed successfully.';
    } on WalletServiceException {
      rethrow;
    } catch (_) {
      throw WalletServiceException(
        'Could not reach the server. Please try again.',
      );
    }
  }

  /// Runs the cashback yield engine, crediting one installment to every cycle
  /// that is due. Idempotent server-side (a second run the same day is a
  /// no-op). Returns the server's summary message.
  Future<String> processMonthlyYield() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.processMonthlyYield);
    try {
      final response = await http.post(uri).timeout(ApiConfig.timeout);
      final body = _decode(response);

      if (response.statusCode != 200 || body['status'] != 'success') {
        throw WalletServiceException(
          body['message']?.toString() ?? 'Failed to process the yield run.',
        );
      }
      return body['message']?.toString() ?? 'Yield processed successfully.';
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
