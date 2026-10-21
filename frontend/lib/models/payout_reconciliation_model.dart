/// One row parsed from the uploaded bank response file.
/// Matches the DOCUMENT SPECIFICATION: Transaction ID | Status | Failure Reason
class ReconciliationRow {
  final String transactionId;
  final String status; // 'success' | 'failed'
  final String? failureReason;

  ReconciliationRow({
    required this.transactionId,
    required this.status,
    this.failureReason,
  });

  bool get isSuccess => status.toLowerCase() == 'success';

  Map<String, dynamic> toJson() => {
        'transaction_id': transactionId,
        'status': status.toLowerCase(),
        'reason': failureReason,
      };

  factory ReconciliationRow.fromRawRow(List<dynamic> cells) {
    final id = cells.isNotEmpty ? (cells[0]?.toString().trim() ?? '') : '';
    final status = cells.length > 1 ? (cells[1]?.toString().trim() ?? '') : '';
    final reason = cells.length > 2 ? cells[2]?.toString().trim() : null;
    return ReconciliationRow(
      transactionId: id,
      status: status,
      failureReason: (reason == null || reason.isEmpty) ? null : reason,
    );
  }
}

/// Response shape of POST admin/reconcile_payouts.php
class ReconciliationSummary {
  final int successCount;
  final int failedCount;
  final String message;
  final List<ReconciliationRow> failedRows;

  ReconciliationSummary({
    required this.successCount,
    required this.failedCount,
    required this.message,
    this.failedRows = const [],
  });

  int get totalProcessed => successCount + failedCount;

  factory ReconciliationSummary.fromJson(
    Map<String, dynamic> json, {
    List<ReconciliationRow> failedRows = const [],
  }) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ReconciliationSummary(
      successCount: int.tryParse('${data['success'] ?? 0}') ?? 0,
      failedCount: int.tryParse('${data['failed'] ?? 0}') ?? 0,
      message: json['message']?.toString() ?? '',
      failedRows: failedRows,
    );
  }
}

class ReconciliationException implements Exception {
  final String message;
  ReconciliationException(this.message);
  @override
  String toString() => message;
}
/// One cashback payout in the STATUS MATRIX — a `transactions` row from
/// `GET admin/payout_reports.php` (`t.*` joined to the payee). These are the
/// rows `reconcile_payouts.php` updates, so their ids are what goes in
/// column 1 of the bank response file.
class ReconciliationLedgerRow {
  final String transactionId;
  final String investorName;

  /// The payee's `users.id` — shown as "ID: 45" and used to open their
  /// ledger. payout_reports.php doesn't return it, so the service joins it in
  /// from auditor/ledger.php by transaction id; empty if that lookup fails.
  final String investorId;
  final String? email;
  final String? bankName;
  final String? accountNo;
  final String? ifscCode;
  final String? description;
  final double amount;

  /// Raw `transactions.status` — 'completed', 'success', 'pending', 'failed'.
  final String status;
  final String? failureReason;
  final DateTime? createdAt;

  const ReconciliationLedgerRow({
    required this.transactionId,
    required this.investorName,
    this.investorId = '',
    this.email,
    this.bankName,
    this.accountNo,
    this.ifscCode,
    this.description,
    this.amount = 0,
    required this.status,
    this.failureReason,
    this.createdAt,
  });

  factory ReconciliationLedgerRow.fromJson(Map<String, dynamic> json,
      {String? userId}) {
    String text(Object? v) {
      final s = (v ?? '').toString().trim();
      return s == 'null' ? '' : s;
    }

    String? optional(Object? v) => text(v).isEmpty ? null : text(v);

    final reason = text(json['failure_reason']);
    return ReconciliationLedgerRow(
      transactionId: text(json['id']),
      investorName: text(json['user_name']).isEmpty
          ? 'UNKNOWN'
          : text(json['user_name']),
      investorId: userId ?? text(json['user_id']),
      email: optional(json['user_email']),
      bankName: optional(json['bank_name']),
      accountNo: optional(json['account_no']),
      ifscCode: optional(json['ifsc_code']),
      description: optional(json['description']),
      amount: double.tryParse(text(json['amount'])) ?? 0,
      status: text(json['status']).isEmpty
          ? 'pending'
          : text(json['status']).toLowerCase(),
      failureReason: reason.isEmpty ? null : reason,
      createdAt: DateTime.tryParse(text(json['created_at'])),
    );
  }

  bool get isSuccess => status == 'completed' || status == 'success';
  bool get isFailed => status == 'failed';
  bool get isPending => !isSuccess && !isFailed;

  static final RegExp _month =
      RegExp(r'month\s+(\d+)\s+of\s+(\d+)', caseSensitive: false);

  /// "Month 2 of 10" from the payout's description, or null.
  String? get monthLabel {
    final m = _month.firstMatch(description ?? '');
    return m == null ? null : 'Month ${m.group(1)} of ${m.group(2)}';
  }
}
