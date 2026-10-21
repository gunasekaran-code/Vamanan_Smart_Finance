/// Maps 1:1 to the row shape returned by `admin/withdrawals.php`:
/// w.* (id, user_id, amount, bank_details, payment_method, status,
/// transaction_id, created_at, processed_at) joined with
/// u.name/u.email and wal.balance as current_balance.
class WithdrawalRequest {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final double amount;
  final String? bankDetails;
  final String paymentMethod;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? processedAt;
  final double currentBalance;

  const WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.amount,
    this.bankDetails,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    required this.createdAt,
    this.processedAt,
    required this.currentBalance,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      userName: (json['user_name'] ?? '').toString(),
      userEmail: (json['user_email'] ?? '').toString(),
      amount: _asDouble(json['amount']),
      bankDetails: json['bank_details']?.toString(),
      paymentMethod: (json['payment_method'] ?? 'Bank Transfer').toString(),
      status: (json['status'] ?? 'pending').toString(),
      transactionId: (json['transaction_id'] == null ||
              json['transaction_id'].toString().isEmpty)
          ? null
          : json['transaction_id'].toString(),
      createdAt: _asDate(json['created_at']) ?? DateTime.now(),
      processedAt: _asDate(json['processed_at']),
      currentBalance: _asDouble(json['current_balance']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'amount': amount,
        'bank_details': bankDetails,
        'payment_method': paymentMethod,
        'status': status,
        'transaction_id': transactionId,
        'created_at': createdAt.toIso8601String(),
        'processed_at': processedAt?.toIso8601String(),
        'current_balance': currentBalance,
      };

  WithdrawalRequest copyWith({
    String? status,
    String? transactionId,
    DateTime? processedAt,
  }) {
    return WithdrawalRequest(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      amount: amount,
      bankDetails: bankDetails,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt,
      processedAt: processedAt ?? this.processedAt,
      currentBalance: currentBalance,
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  // PDO returns DECIMAL columns as strings, so amount/current_balance
  // arrive as e.g. "1500.00" rather than a JSON number.
  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty || s.startsWith('0000-00-00')) return null;
    // MySQL TIMESTAMP comes as "YYYY-MM-DD HH:MM:SS"; DateTime.tryParse
    // handles that directly.
    return DateTime.tryParse(s);
  }
}