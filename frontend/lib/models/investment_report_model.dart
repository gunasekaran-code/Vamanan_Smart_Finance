// lib/features/admin/models/investment_model.dart
//
// Model for a single cashback_cycles row as returned by:
//   - GET admin/investments.php          (status == 'pending')
//   - GET admin/investment_history.php   (status != 'pending')
//
// Both endpoints return the same shape (investments.php additionally
// aliases id -> cycle_id / status -> cycle_status server-side, but we
// handle both key variants here defensively either way).

enum InvestmentStatus { pending, active, rejected, unknown }

InvestmentStatus investmentStatusFromString(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'pending':
      return InvestmentStatus.pending;
    case 'active':
      return InvestmentStatus.active;
    case 'rejected':
      return InvestmentStatus.rejected;
    default:
      return InvestmentStatus.unknown;
  }
}

String investmentStatusLabel(InvestmentStatus status) {
  switch (status) {
    case InvestmentStatus.pending:
      return 'PENDING';
    case InvestmentStatus.active:
      return 'ACTIVE';
    case InvestmentStatus.rejected:
      return 'REJECTED';
    case InvestmentStatus.unknown:
      return 'UNKNOWN';
  }
}

class Investment {
  final int cycleId;
  final int userId;
  final String userName;
  final String userEmail;
  final String? userPhone;

  final InvestmentStatus status;
  final double totalValue;
  final double cashbackEligibleAmount;
  final double dailyPayout; // repurposed as monthly installment once active
  final double monthlyInstallment; // eligible / plan months (pending list only)
  final String assetType; // 'gold' | 'silver' | 'product'
  final double? weight;
  final String? productName;
  final double? productAmount;

  final String? transactionId;
  final String? paymentScreenshot;

  final DateTime? createdAt;
  final DateTime? lastPaidAt;
  final DateTime? processedDate; // only present in history response

  Investment({
    required this.cycleId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    required this.status,
    required this.totalValue,
    required this.cashbackEligibleAmount,
    required this.dailyPayout,
    this.monthlyInstallment = 0,
    required this.assetType,
    this.weight,
    this.productName,
    this.productAmount,
    this.transactionId,
    this.paymentScreenshot,
    this.createdAt,
    this.lastPaidAt,
    this.processedDate,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      cycleId: _asInt(json['cycle_id'] ?? json['id']),
      userId: _asInt(json['user_id']),
      userName: (json['user_name'] ?? '').toString(),
      userEmail: (json['user_email'] ?? '').toString(),
      userPhone: json['user_phone']?.toString(),
      status: investmentStatusFromString(
        (json['cycle_status'] ?? json['status'])?.toString(),
      ),
      totalValue: _asDouble(json['total_value']),
      cashbackEligibleAmount: _asDouble(json['cashback_eligible_amount']),
      dailyPayout: _asDouble(json['daily_payout']),
      monthlyInstallment: _asDouble(json['monthly_installment']),
      assetType: (json['asset_type'] ?? '').toString(),
      weight: json['weight'] == null ? null : _asDouble(json['weight']),
      productName: json['product_name']?.toString(),
      productAmount:
          json['product_amount'] == null ? null : _asDouble(json['product_amount']),
      transactionId: (json['transaction_id']?.toString().isEmpty ?? true)
          ? null
          : json['transaction_id'].toString(),
      paymentScreenshot: json['payment_screenshot']?.toString(),
      createdAt: _asDate(json['created_at']),
      lastPaidAt: _asDate(json['last_paid_at']),
      processedDate: _asDate(json['processed_date']),
    );
  }

  String get initial => userName.isNotEmpty ? userName[0].toUpperCase() : '?';

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty || s == '0000-00-00 00:00:00') return null;
    return DateTime.tryParse(s);
  }
}