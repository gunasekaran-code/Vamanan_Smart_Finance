// lib/features/admin/models/payout_report_model.dart
//
// Backed by:
//   GET  admin/payout_reports.php  -> { summary, chart, history }
//   GET  admin/export_payouts.php  -> export_history rows
//   POST admin/export_payouts.php  -> records an export + marks transactions completed
//
// Field names here are taken directly from the PHP source (not guessed).

class PayoutSummary {
  final double successAmount;
  final double pendingAmount;
  final double failedAmount;
  final int totalCount;
  final int successCount;
  final int pendingCount;
  final int failedCount;

  PayoutSummary({
    required this.successAmount,
    required this.pendingAmount,
    required this.failedAmount,
    required this.totalCount,
    required this.successCount,
    required this.pendingCount,
    required this.failedCount,
  });

  factory PayoutSummary.empty() => PayoutSummary(
        successAmount: 0,
        pendingAmount: 0,
        failedAmount: 0,
        totalCount: 0,
        successCount: 0,
        pendingCount: 0,
        failedCount: 0,
      );

  factory PayoutSummary.fromJson(Map<String, dynamic> json) {
    return PayoutSummary(
      successAmount: _asDouble(json['success_amount']),
      pendingAmount: _asDouble(json['pending_amount']),
      failedAmount: _asDouble(json['failed_amount']),
      totalCount: _asInt(json['total_count']),
      successCount: _asInt(json['success_count']),
      pendingCount: _asInt(json['pending_count']),
      failedCount: _asInt(json['failed_count']),
    );
  }
}

class PayoutChartPoint {
  final DateTime date;
  final double totalAmount;

  PayoutChartPoint({required this.date, required this.totalAmount});

  factory PayoutChartPoint.fromJson(Map<String, dynamic> json) {
    return PayoutChartPoint(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      totalAmount: _asDouble(json['total_amount']),
    );
  }
}

class PayoutTransaction {
  final int id;
  final int? walletId;
  final String category; // 'cashback' | 'referral'
  final double amount;
  final String status; // 'success' | 'completed' | 'pending' | 'failed'
  final String? description;
  final DateTime? createdAt;

  final String userName;
  final String userEmail;
  final String? bankName;
  final String? accountNo;
  final String? ifscCode;

  PayoutTransaction({
    required this.id,
    this.walletId,
    required this.category,
    required this.amount,
    required this.status,
    this.description,
    this.createdAt,
    required this.userName,
    required this.userEmail,
    this.bankName,
    this.accountNo,
    this.ifscCode,
  });

  factory PayoutTransaction.fromJson(Map<String, dynamic> json) {
    return PayoutTransaction(
      id: _asInt(json['id']),
      walletId: json['wallet_id'] == null ? null : _asInt(json['wallet_id']),
      category: (json['category'] ?? '').toString(),
      amount: _asDouble(json['amount']),
      status: (json['status'] ?? 'unknown').toString(),
      description: json['description']?.toString(),
      createdAt: _asDate(json['created_at']),
      userName: (json['user_name'] ?? '').toString(),
      userEmail: (json['user_email'] ?? '').toString(),
      bankName: _emptyToNull(json['bank_name']?.toString()),
      accountNo: _emptyToNull(json['account_no']?.toString()),
      ifscCode: _emptyToNull(json['ifsc_code']?.toString()),
    );
  }

  String get initial => userName.isNotEmpty ? userName[0].toUpperCase() : '?';

  /// Masked account number for display, e.g. "•••• 4821".
  String get maskedAccount {
    if (accountNo == null || accountNo!.length < 4) return accountNo ?? '-';
    return '•••• ${accountNo!.substring(accountNo!.length - 4)}';
  }
}

class ExportRecord {
  final int id;
  final String filename;
  final String exportType;
  final double totalAmount;
  final int totalRecords;
  final DateTime? createdAt;

  ExportRecord({
    required this.id,
    required this.filename,
    required this.exportType,
    required this.totalAmount,
    required this.totalRecords,
    this.createdAt,
  });

  factory ExportRecord.fromJson(Map<String, dynamic> json) {
    return ExportRecord(
      id: _asInt(json['id']),
      filename: (json['filename'] ?? '').toString(),
      exportType: (json['export_type'] ?? '').toString(),
      totalAmount: _asDouble(json['total_amount']),
      totalRecords: _asInt(json['total_records']),
      createdAt: _asDate(json['created_at']),
    );
  }
}

class PayoutReportBundle {
  final PayoutSummary summary;
  final List<PayoutChartPoint> chart;
  final List<PayoutTransaction> history;

  PayoutReportBundle({required this.summary, required this.chart, required this.history});
}

// --- helpers ---

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  if (s.isEmpty || s == '0000-00-00 00:00:00') return null;
  return DateTime.tryParse(s);
}

String? _emptyToNull(String? s) => (s == null || s.isEmpty) ? null : s;