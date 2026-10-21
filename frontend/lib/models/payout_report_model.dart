/// Aggregate totals from the `summary` key of admin/payout_reports.php
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

  double get totalAmount => successAmount + pendingAmount + failedAmount;

  /// Share of disbursed value that succeeded, 0–100. Used for the
  /// "MARKET TRAJECTORY" percentage card.
  double get successRate =>
      totalAmount == 0 ? 0 : (successAmount / totalAmount) * 100;

  factory PayoutSummary.empty() => PayoutSummary(
        successAmount: 0,
        pendingAmount: 0,
        failedAmount: 0,
        totalCount: 0,
        successCount: 0,
        pendingCount: 0,
        failedCount: 0,
      );

  factory PayoutSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PayoutSummary.empty();
    double asDouble(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
    int asInt(dynamic v) => int.tryParse('${v ?? 0}') ?? 0;

    return PayoutSummary(
      successAmount: asDouble(json['success_amount']),
      pendingAmount: asDouble(json['pending_amount']),
      failedAmount: asDouble(json['failed_amount']),
      totalCount: asInt(json['total_count']),
      successCount: asInt(json['success_count']),
      pendingCount: asInt(json['pending_count']),
      failedCount: asInt(json['failed_count']),
    );
  }
}

/// One point of the `chart` array: a day's total disbursement.
class PayoutChartPoint {
  final DateTime date;
  final double totalAmount;

  PayoutChartPoint({required this.date, required this.totalAmount});

  factory PayoutChartPoint.fromJson(Map<String, dynamic> json) {
    return PayoutChartPoint(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      totalAmount: double.tryParse('${json['total_amount'] ?? 0}') ?? 0,
    );
  }
}

/// One row of the `history` array — a transaction joined to its payee.
class PayoutHistoryRecord {
  final String id;
  final String? userName;
  final String? userEmail;
  final String? bankName;
  final String? accountNo;
  final String? ifscCode;
  final double amount;
  final String status;
  final String category;
  final DateTime? createdAt;

  PayoutHistoryRecord({
    required this.id,
    this.userName,
    this.userEmail,
    this.bankName,
    this.accountNo,
    this.ifscCode,
    required this.amount,
    required this.status,
    required this.category,
    this.createdAt,
  });

  factory PayoutHistoryRecord.fromJson(Map<String, dynamic> json) {
    return PayoutHistoryRecord(
      id: json['id']?.toString() ?? '',
      userName: json['user_name']?.toString(),
      userEmail: json['user_email']?.toString(),
      bankName: json['bank_name']?.toString(),
      accountNo: json['account_no']?.toString(),
      ifscCode: json['ifsc_code']?.toString(),
      amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
      status: (json['status']?.toString() ?? 'unknown').toLowerCase(),
      category: json['category']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  /// True if this row matches a free-text search over the fields the
  /// registry search box is meant to cover.
  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase();
    return id.toLowerCase().contains(q) ||
        (userName ?? '').toLowerCase().contains(q) ||
        (userEmail ?? '').toLowerCase().contains(q) ||
        (bankName ?? '').toLowerCase().contains(q) ||
        status.contains(q);
  }
}

/// Full payload of admin/payout_reports.php.
class PayoutReportsData {
  final PayoutSummary summary;
  final List<PayoutChartPoint> chart;
  final List<PayoutHistoryRecord> history;

  PayoutReportsData({
    required this.summary,
    required this.chart,
    required this.history,
  });

  factory PayoutReportsData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return PayoutReportsData(
      summary: PayoutSummary.fromJson(data['summary'] as Map<String, dynamic>?),
      chart: (data['chart'] as List<dynamic>? ?? [])
          .map((e) => PayoutChartPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      history: (data['history'] as List<dynamic>? ?? [])
          .map((e) => PayoutHistoryRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PayoutReportsException implements Exception {
  final String message;
  PayoutReportsException(this.message);
  @override
  String toString() => message;
}