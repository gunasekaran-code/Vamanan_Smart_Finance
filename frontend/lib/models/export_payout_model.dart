import 'dart:convert';

/// One payout awaiting a real bank transfer — a row from the `withdrawals`
/// table as returned by `GET admin/withdrawals.php`, joined to the user's
/// name/email and current wallet balance.
///
/// The customer's money is already debited (locked) at request time, so a
/// pending row represents capital that has left the wallet but not yet the
/// bank. Approving finalises it; rejecting refunds it.
class PendingPayout {
  /// Primary key of the `withdrawals` row.
  ///
  /// IMPORTANT: this is NOT a `transactions.id`. Do not feed it to
  /// export_payouts.php's `transaction_ids`, which blind-updates
  /// `transactions` by id and would flip unrelated ledger rows.
  final String withdrawalId;

  final String userId;
  final String customerName;
  final String? customerEmail;

  /// Free-form bank details captured when the customer filed the request.
  /// The customer app may send either a JSON object or a plain string, so
  /// both are handled — see [bankDetailsLabel].
  final String? rawBankDetails;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;

  /// e.g. 'Bank Transfer' (the column default).
  final String? paymentMethod;

  final double amount;

  /// The payee's wallet balance right now, for context in the UI.
  final double currentBalance;

  /// 'pending', 'approved', or 'rejected' — the `withdrawals.status` enum.
  final String status;

  /// Bank UTR / reference stamped when the transfer was processed.
  final String? utr;

  final DateTime? createdAt;
  final DateTime? processedAt;

  const PendingPayout({
    required this.withdrawalId,
    required this.userId,
    required this.customerName,
    this.customerEmail,
    this.rawBankDetails,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.paymentMethod,
    required this.amount,
    this.currentBalance = 0,
    this.status = 'pending',
    this.utr,
    this.createdAt,
    this.processedAt,
  });

  factory PendingPayout.fromJson(Map<String, dynamic> json) {
    // `bank_details` is a TEXT column written verbatim from the customer
    // app, so it may be a JSON object or just a typed-in string.
    final raw = json['bank_details']?.toString();
    Map<String, dynamic> parsed = const {};
    if (raw != null && raw.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) parsed = decoded.cast<String, dynamic>();
      } catch (_) {
        // Not JSON after all — fall through and show the raw text.
      }
    }

    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = parsed[k] ?? json[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return null;
    }

    return PendingPayout(
      withdrawalId: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      customerName: (json['user_name'] ?? json['customer_name'] ?? 'Unknown').toString(),
      customerEmail: (json['user_email'] ?? json['customer_email'])?.toString(),
      rawBankDetails: raw,
      bankName: pick(['bank_name', 'bank']),
      accountNumber: pick(['account_no', 'account_number', 'acc_no']),
      ifscCode: pick(['ifsc_code', 'ifsc']),
      paymentMethod: json['payment_method']?.toString(),
      amount: _toDouble(json['amount']),
      currentBalance: _toDouble(json['current_balance']),
      status: (json['status'] ?? 'pending').toString(),
      utr: json['transaction_id']?.toString(),
      createdAt: _parseDate(json['created_at']),
      processedAt: _parseDate(json['processed_at']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty || s == 'null') return null;
    return DateTime.tryParse(s);
  }

  bool get hasBankDetails =>
      (accountNumber != null && accountNumber!.isNotEmpty) &&
      (ifscCode != null && ifscCode!.isNotEmpty);

  /// What shows in the BANK DETAILS column.
  String get bankDetailsLabel {
    if (hasBankDetails) {
      final last4 = accountNumber!.length > 4
          ? accountNumber!.substring(accountNumber!.length - 4)
          : accountNumber!;
      return '${bankName ?? 'Bank'} · ••••$last4 · $ifscCode';
    }
    // Unstructured but present — better to show it than claim there is none.
    final raw = rawBankDetails?.trim() ?? '';
    if (raw.isNotEmpty) return raw;
    return 'No bank details on file';
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  /// A row can only be exported into a bank file if it is still pending.
  bool get isExportable => isPending;

  /// One line of the bank bulk-transfer file.
  List<String> toCsvRow() => [
        withdrawalId,
        customerName,
        customerEmail ?? '',
        bankName ?? '',
        accountNumber ?? '',
        ifscCode ?? '',
        amount.toStringAsFixed(2),
        paymentMethod ?? 'Bank Transfer',
      ];

  static const List<String> csvHeader = [
    'WITHDRAWAL_ID',
    'BENEFICIARY_NAME',
    'EMAIL',
    'BANK_NAME',
    'ACCOUNT_NUMBER',
    'IFSC',
    'AMOUNT',
    'MODE',
  ];
}

/// The four stat cards, from the `stats` block of
/// `GET admin/payout_history.php`.
class PayoutStats {
  final double todayYield;
  final int activeCycles;
  final double totalPaid;

  /// `Never` when no cycle has ever paid out.
  final String lastPayout;

  const PayoutStats({
    this.todayYield = 0,
    this.activeCycles = 0,
    this.totalPaid = 0,
    this.lastPayout = 'Never',
  });

  factory PayoutStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PayoutStats();
    final last = json['last_run']?.toString();
    return PayoutStats(
      todayYield: PendingPayout._toDouble(json['today']),
      activeCycles: int.tryParse('${json['active_cycles']}') ?? 0,
      totalPaid: PendingPayout._toDouble(json['total_paid']),
      lastPayout: (last == null || last.isEmpty || last == 'null') ? 'Never' : last,
    );
  }
}

/// One row from the real `export_history` table, as returned by
/// `GET admin/export_payouts.php`.
class ExportHistoryRecord {
  final String id;
  final String? filename;
  final String? exportType;
  final double totalAmount;
  final int totalRecords;
  final DateTime? createdAt;

  const ExportHistoryRecord({
    required this.id,
    this.filename,
    this.exportType,
    this.totalAmount = 0,
    this.totalRecords = 0,
    this.createdAt,
  });

  factory ExportHistoryRecord.fromJson(Map<String, dynamic> json) {
    return ExportHistoryRecord(
      id: json['id']?.toString() ?? '',
      filename: json['filename']?.toString(),
      exportType: json['export_type']?.toString(),
      totalAmount: PendingPayout._toDouble(json['total_amount']),
      totalRecords: int.tryParse('${json['total_records']}') ?? 0,
      createdAt: PendingPayout._parseDate(json['created_at']),
    );
  }

  /// "12 SEP 2026, 1:46 PM" — matches how the rest of the app stamps rows.
  String get createdAtLabel {
    final d = createdAt;
    if (d == null) return '—';
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}, '
        '$hour12:$minute $period';
  }
}

/// One cashback payout, a `transactions` row from `GET admin/payout_history.php`
/// joined to the payee's name, email and bank details.
///
/// Unlike [PendingPayout], [transactionId] IS a `transactions.id`, so these
/// are the ids export_payouts.php's `transaction_ids` expects.
class PayoutTransfer {
  final String transactionId;
  final String customerName;
  final String? customerEmail;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final double amount;

  /// 'completed', 'pending' or 'failed'.
  final String status;
  final String? description;
  final DateTime? createdAt;

  /// Installments already paid on the matched cycle (`days_paid`, the
  /// backend's `current_day`). Null when the payout couldn't be tied to a
  /// cycle — e.g. manual payouts, whose description has no "Cycle #N".
  final int? cycleDay;

  const PayoutTransfer({
    required this.transactionId,
    required this.customerName,
    this.customerEmail,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    required this.amount,
    this.status = 'completed',
    this.description,
    this.createdAt,
    this.cycleDay,
  });

  factory PayoutTransfer.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final v = json[key]?.toString().trim();
      return (v == null || v.isEmpty || v == 'null') ? null : v;
    }

    return PayoutTransfer(
      transactionId: json['id']?.toString() ?? '',
      customerName: text('user_name') ?? 'Unknown',
      customerEmail: text('user_email'),
      bankName: text('bank_name'),
      accountNumber: text('account_no'),
      ifscCode: text('ifsc_code'),
      amount: PendingPayout._toDouble(json['amount']),
      status: (text('status') ?? 'completed').toLowerCase(),
      description: text('description'),
      createdAt: PendingPayout._parseDate(json['created_at']),
      cycleDay: int.tryParse('${json['current_day']}'),
    );
  }

  bool get hasBankDetails =>
      (accountNumber ?? '').isNotEmpty && (ifscCode ?? '').isNotEmpty;

  bool get isCompleted => status == 'completed' || status == 'success';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';

  /// "DAY 2 YIELD" — or "DAY YIELD" when no cycle could be matched.
  String get yieldLabel =>
      cycleDay == null || cycleDay == 0 ? 'DAY YIELD' : 'DAY $cycleDay YIELD';
}

/// `GET admin/payout_history.php` — stat cards and payout rows come back
/// from the same request.
class PayoutHistoryBundle {
  final PayoutStats stats;
  final List<PayoutTransfer> transfers;

  const PayoutHistoryBundle({required this.stats, required this.transfers});
}
