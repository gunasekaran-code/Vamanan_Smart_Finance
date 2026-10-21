import 'package:frontend/core/config/api_config.dart';

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
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime? dt) {
  if (dt == null) return '—';
  return '${dt.day.toString().padLeft(2, '0')} ${_kMonths[dt.month - 1]} ${dt.year}';
}

String _formatTime(DateTime? dt) {
  if (dt == null) return '—';
  var hour = dt.hour % 12;
  if (hour == 0) hour = 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '${hour.toString().padLeft(2, '0')}:$minute $period';
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

String formatInr(double value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final grouped = _groupIndian(parts[0]);
  return '${negative ? '-' : ''}₹$grouped.${parts[1]}';
}

/// A processed (non-pending) cashback cycle, as returned by
/// admin/investment_history.php.
class InvestmentHistoryRecord {
  final int id; // cycle_id
  final int userId;
  final String customerName;
  final String customerEmail;

  final String assetType; // 'gold' | 'silver' | 'product'
  final double weight;
  final String? productName;
  final double productAmount;
  final double cashbackEligibleAmount;
  final double dailyPayout;
  final double totalValue;

  final String transactionId;
  final String? paymentScreenshot;

  final String status; // 'active' | 'rejected' | 'completed' | ...
  final DateTime? createdAt;
  final DateTime? lastPaidAt;
  final DateTime? processedDate;

  const InvestmentHistoryRecord({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
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

  factory InvestmentHistoryRecord.fromJson(Map<String, dynamic> json) {
    return InvestmentHistoryRecord(
      id: _asInt(json['cycle_id'] ?? json['id']),
      userId: _asInt(json['user_id']),
      customerName: _asString(json['user_name'], fallback: 'UNKNOWN'),
      customerEmail: _asString(json['user_email']),
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
      status: _asString(json['cycle_status'] ?? json['status'], fallback: 'unknown')
          .toLowerCase(),
      createdAt: _asDate(json['created_at']),
      lastPaidAt: _asDate(json['last_paid_at']),
      processedDate: _asDate(json['processed_date']) ?? _asDate(json['created_at']),
    );
  }

  // ---- Display helpers used directly by the UI ----

  String get processDateDisplay => _formatDate(processedDate);
  String get processTimeDisplay => _formatTime(processedDate);

  String get assetTypeDisplay {
    if (assetType == 'product') return productName ?? 'PRODUCT PURCHASE';
    return assetType == 'silver' ? 'PURE SILVER ASSET' : '22K GOLD ASSET';
  }

  String get weightDisplay => '${weight.toStringAsFixed(3)} GRAMS';

  double get displayAmount {
    if (totalValue > 0) return totalValue;
    if (cashbackEligibleAmount > 0) return cashbackEligibleAmount;
    return productAmount;
  }

  String get capitalAmountDisplay => formatInr(displayAmount);
  String get dailyAmountDisplay => 'DAILY: ${formatInr(dailyPayout)}';

  String get paymentMethodDisplay => 'BANK TRANSFER';
  String get utrDisplay => transactionId;

  String get statusDisplay => status.toUpperCase();

  String? get receiptImageUrl {
    final raw = paymentScreenshot;
    if (raw == null || raw.isEmpty) return null;
    return ApiConfig.fileUrl(raw);
  }
}