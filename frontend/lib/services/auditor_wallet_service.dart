import 'dart:convert';

import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/network/json_envelope.dart';
import 'package:http/http.dart' as http;

import '../models/auditor_wallet_model.dart';

class AuditorWalletService {
  AuditorWalletService._();
  static final instance = AuditorWalletService._();

  Future<WalletOverview> fetchOverview(String userId) async =>
      (await _fetchSnapshot(userId)).overview;

  Future<List<WalletTransactionRecord>> fetchTransactions(
    String userId, {
    String? category,
    int limit = 100,
  }) async {
    var transactions = (await _fetchSnapshot(userId)).transactions;
    if (category != null && category.isNotEmpty) {
      transactions = transactions
          .where((transaction) =>
              transaction.category.toLowerCase() == category.toLowerCase())
          .toList();
    }
    return transactions.take(limit).toList();
  }

  Future<List<WithdrawalRecord>> fetchWithdrawals(String userId) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.withdrawals)
        .replace(queryParameters: {'user_id': userId});
    final response = await http.get(uri).timeout(ApiConfig.timeout);
    final body = _decode(response);
    if (response.statusCode != 200 || body['status'] != 'success') {
      throw AuditorWalletException(
        body['message']?.toString() ?? 'Could not load withdrawal history.',
      );
    }
    final records = body['data'];
    return records is List
        ? records
            .whereType<Map>()
            .map((item) =>
                WithdrawalRecord.fromJson(item.cast<String, dynamic>()))
            .toList()
        : <WithdrawalRecord>[];
  }

  Future<void> submitWithdrawal({
    required String userId,
    required double amount,
    required String bankName,
    required String accountNo,
    required String ifscCode,
  }) async {
    final response = await http
        .post(
          ApiConfig.endpoint(CustomerEndpoints.requestWithdrawal),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'amount': amount,
            'bank_details':
                'Bank: $bankName | Account: $accountNo | IFSC: $ifscCode',
          }),
        )
        .timeout(ApiConfig.timeout);
    final body = _decode(response);
    if (response.statusCode != 200 || body['status'] != 'success') {
      throw AuditorWalletException(
        body['message']?.toString() ?? 'Could not submit withdrawal request.',
      );
    }
  }

  Future<WalletSnapshot> _fetchSnapshot(String userId) async {
    final uri = ApiConfig.endpoint(CustomerEndpoints.wallet)
        .replace(queryParameters: {'user_id': userId});
    final response = await http.get(uri).timeout(ApiConfig.timeout);
    final body = _decode(response);
    if (response.statusCode != 200 || body['status'] != 'success') {
      throw AuditorWalletException(
        body['message']?.toString() ?? 'Could not load wallet data.',
      );
    }
    return WalletSnapshot.fromJson(body);
  }

  /// Tolerates the PHP notices `config.php` can print ahead of the JSON, and
  /// surfaces what actually came back instead of a generic message.
  Map<String, dynamic> _decode(http.Response response) {
    try {
      return decodeJsonEnvelope(response);
    } on ServerEnvelopeException catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}

class AuditorWalletException implements Exception {
  final String message;
  AuditorWalletException(this.message);
  @override
  String toString() => message;
}
