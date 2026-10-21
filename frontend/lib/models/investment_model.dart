import 'package:frontend/core/config/api_config.dart';

enum InvestmentStatus { pending, active, rejected, completed, unknown }

InvestmentStatus _statusFromString(String? raw) {
  switch ((raw ?? '').toLowerCase().trim()) {
    case 'pending':
      return InvestmentStatus.pending;
    case 'active':
      return InvestmentStatus.active;
    case 'rejected':
      return InvestmentStatus.rejected;
    case 'completed':
      return InvestmentStatus.completed;
    default:
      return InvestmentStatus.unknown;
  }
}

double _asDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final s = value.toString().trim();
  return s.isEmpty ? fallback : s;
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

const List<String> _kMonths = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

String _formatSubmitted(DateTime? dt) {
  if (dt == null) return '—';
  final day = dt.day.toString().padLeft(2, '0');
  final month = _kMonths[dt.month - 1];
  var hour = dt.hour % 12;
  if (hour == 0) hour = 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '$day $month AT ${hour.toString().padLeft(2, '0')}:$minute $period';
}

String _groupIndian(String digits) {
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}

/// Formats a value as an Indian-grouped rupee amount, e.g. ₹1,26,000.93
String formatInr(double value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final grouped = _groupIndian(parts[0]);
  return '${negative ? '-' : ''}₹$grouped.${parts[1]}';
}

/// A single investment / cashback cycle request, as returned by
/// admin/investments.php (pending) and admin/investment_history.php (processed).
class InvestmentRequest {
  final int id; // cashback_cycles.id (aka cycle_id)
  final int userId;
  final String userName;
  final String userEmail;
  final String userPhone;

  final String assetType; // 'gold' | 'silver' | 'product'
  final double weight; // grams
  final String? productName;
  final double productAmount;
  final double cashbackEligibleAmount; // GST-excluded value the daily payout is based on
  final double dailyPayout;
  final double totalValue;

  final String transactionId; // UTR
  final String? paymentScreenshot; // raw path/url from backend

  final InvestmentStatus status;
  final DateTime? createdAt;
  final DateTime? lastPaidAt;
  final DateTime? processedDate;

  const InvestmentRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.assetType,
    required this.weight,
    required this.productName,
    required this.productAmount,
    required this.cashbackEligibleAmount,
    required this.dailyPayout,
    required this.totalValue,
    required this.transactionId,
    required this.paymentScreenshot,
    required this.status,
    required this.createdAt,
    required this.lastPaidAt,
    required this.processedDate,
  });

  factory InvestmentRequest.fromJson(Map<String, dynamic> json) {
    return InvestmentRequest(
      id: _asInt(json['cycle_id'] ?? json['id']),
      userId: _asInt(json['user_id']),
      userName: _asString(json['user_name'], fallback: 'UNKNOWN'),
      userEmail: _asString(json['user_email']),
      userPhone: _asString(json['user_phone']),
      assetType: _asString(json['asset_type'], fallback: 'gold').toLowerCase(),
      weight: _asDouble(json['weight']),
      productName: (json['product_name'] == null ||
              json['product_name'].toString().trim().isEmpty)
          ? null
          : json['product_name'].toString().trim(),
      productAmount: _asDouble(json['product_amount']),
      cashbackEligibleAmount: _asDouble(json['cashback_eligible_amount']),
      dailyPayout: _asDouble(json['daily_payout']),
      totalValue: _asDouble(json['total_value']),
      transactionId: _asString(json['transaction_id'], fallback: 'N/A'),
      paymentScreenshot: (json['payment_screenshot'] == null ||
              json['payment_screenshot'].toString().trim().isEmpty)
          ? null
          : json['payment_screenshot'].toString().trim(),
      status: _statusFromString(
        (json['cycle_status'] ?? json['status'])?.toString(),
      ),
      createdAt: _asDate(json['created_at']),
      lastPaidAt: _asDate(json['last_paid_at']),
      processedDate: _asDate(json['processed_date']),
    );
  }

  // ---- Display helpers used directly by the UI ----

  String get displayAssetLabel {
    if (assetType == 'product') return productName ?? 'Product Purchase';
    return assetType == 'silver' ? 'PURE SILVER ASSET' : '22K GOLD ASSET';
  }

  String get weightDisplay => '${weight.toStringAsFixed(3)} GRAMS';

  /// Falls back through total_value -> cashback-eligible -> product amount,
  /// whichever is populated for this row.
  double get displayAmount {
    if (totalValue > 0) return totalValue;
    if (cashbackEligibleAmount > 0) return cashbackEligibleAmount;
    return productAmount;
  }

  String get amountDisplay => formatInr(displayAmount);

  String get dailyPayoutDisplay => 'DAILY PAYOUT: ${formatInr(dailyPayout)}';

  String get utrDisplay => transactionId;

  String get submittedTimeDisplay => _formatSubmitted(createdAt);

  /// Builds a full URL for the uploaded payment receipt, if any.
  /// Receipts are stored relative to the document root (e.g.
  /// `uploads/payments/...`), so they resolve against the site root.
  String? get receiptImageUrl {
    final raw = paymentScreenshot;
    if (raw == null || raw.isEmpty) return null;
    return ApiConfig.fileUrl(raw);
  }

  bool get isPending => status == InvestmentStatus.pending;
}