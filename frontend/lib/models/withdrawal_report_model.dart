/// Model for a single row returned by `api/admin/withdrawals.php`.
///
/// The PHP query joins `withdrawals` with `users` and `wallets`, so this
/// model carries both the withdrawal's own columns and the joined
/// user_name / user_email / current_balance fields. Field set mirrors the
/// self-healing schema in the PHP file exactly.
class WithdrawalRecord {
  final int id;
  final int userId;
  final double amount;
  final String? bankDetails;
  final String paymentMethod;
  final WithdrawalStatus status;
  final String? transactionId;
  final DateTime? createdAt;
  final DateTime? processedAt;
  final String? userName;
  final String? userEmail;
  final double? currentBalance;

  const WithdrawalRecord({
    required this.id,
    required this.userId,
    required this.amount,
    this.bankDetails,
    this.paymentMethod = 'Bank Transfer',
    this.status = WithdrawalStatus.pending,
    this.transactionId,
    this.createdAt,
    this.processedAt,
    this.userName,
    this.userEmail,
    this.currentBalance,
  });

  factory WithdrawalRecord.fromJson(Map<String, dynamic> json) {
    return WithdrawalRecord(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      amount: _asDouble(json['amount']),
      bankDetails: json['bank_details'] as String?,
      paymentMethod: (json['payment_method'] as String?) ?? 'Bank Transfer',
      status: WithdrawalStatus.fromString(json['status'] as String?),
      transactionId: json['transaction_id'] as String?,
      createdAt: _asDate(json['created_at']),
      processedAt: _asDate(json['processed_at']),
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
      currentBalance: json['current_balance'] == null ? null : _asDouble(json['current_balance']),
    );
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}

/// Mirrors the ENUM('pending','approved','rejected') column on `withdrawals`.
enum WithdrawalStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  final String value;
  const WithdrawalStatus(this.value);

  static WithdrawalStatus fromString(String? raw) {
    return WithdrawalStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => WithdrawalStatus.pending,
    );
  }
}

/// Wraps the endpoint's `{ status, data }` payload. There is no `summary`
/// block in this PHP file (unlike cashback_applications.php), so totals are
/// derived client-side from the list — see WithdrawalReportsScreen.
class WithdrawalListResult {
  final List<WithdrawalRecord> withdrawals;

  const WithdrawalListResult({required this.withdrawals});

  factory WithdrawalListResult.fromJson(Map<String, dynamic> json) {
    final rawList = (json['data'] as List<dynamic>? ?? [])
        .map((e) => WithdrawalRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    return WithdrawalListResult(withdrawals: rawList);
  }

  factory WithdrawalListResult.empty() => const WithdrawalListResult(withdrawals: []);
}