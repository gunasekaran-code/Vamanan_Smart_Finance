/// One row from admin/withdrawals.php — a withdrawal request joined to
/// the requesting user and their current wallet balance.
class WithdrawalRequest {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final double amount;
  final String? bankDetails;
  final String paymentMethod;
  final String status; // pending | approved | rejected
  final String? transactionId;
  final double currentBalance;
  final DateTime? createdAt;
  final DateTime? processedAt;

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.amount,
    this.bankDetails,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    required this.currentBalance,
    this.createdAt,
    this.processedAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;

    return WithdrawalRequest(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Unknown',
      userEmail: json['user_email']?.toString() ?? '',
      amount: asDouble(json['amount']),
      bankDetails: json['bank_details']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? 'Bank Transfer',
      status: (json['status']?.toString() ?? 'pending').toLowerCase(),
      transactionId: json['transaction_id']?.toString(),
      currentBalance: asDouble(json['current_balance']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      processedAt: DateTime.tryParse(json['processed_at']?.toString() ?? ''),
    );
  }
}

class WithdrawalActionResult {
  final bool success;
  final String message;

  WithdrawalActionResult({required this.success, required this.message});

  factory WithdrawalActionResult.fromJson(Map<String, dynamic> json) {
    return WithdrawalActionResult(
      success: json['status'] == 'success',
      message: json['message']?.toString() ?? '',
    );
  }
}

class WithdrawalsException implements Exception {
  final String message;
  WithdrawalsException(this.message);
  @override
  String toString() => message;
}