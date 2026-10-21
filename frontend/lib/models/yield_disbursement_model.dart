/// Powers the four stat cards at the top of YieldDisbursementsScreen.
///
/// Built from the `stats` block of `admin/payout_history.php`, whose keys are
/// `today` / `monthly` / `active_cycles` / `total_paid`. The longer
/// `dispatched_today`-style names are kept as fallbacks so a future purpose
/// built endpoint can be swapped in without touching this class.
class YieldSummary {
  final double dispatchedToday;
  final double currentMonthTotal;
  final int activeCycles;
  final double cumulativeTotal;

  const YieldSummary({
    this.dispatchedToday = 0,
    this.currentMonthTotal = 0,
    this.activeCycles = 0,
    this.cumulativeTotal = 0,
  });

  factory YieldSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const YieldSummary();
    return YieldSummary(
      dispatchedToday: _toDouble(json['today'] ?? json['dispatched_today']),
      currentMonthTotal: _toDouble(json['monthly'] ?? json['current_month_total']),
      activeCycles: _toInt(json['active_cycles']),
      cumulativeTotal: _toDouble(json['total_paid'] ?? json['cumulative_total']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

/// A single row in the disbursements table — one `transactions` entry of
/// category `cashback` or `referral`, as credited by
/// `api/cron/daily_yield_engine.php`.
class YieldDisbursement {
  final String id;
  final String userId;
  final String customerName;
  final String? customerEmail;

  /// 'cashback' or 'referral'.
  final String category;

  final double grossAmount;
  final double tdsAmount;
  final double chargesAmount;
  final double netAmount;

  /// The human-readable note the engine writes, e.g. "Monthly 10% cashback
  /// on ₹50,000.00 (excl. GST) — Month 3 of 10 ...".
  final String? description;

  /// 'completed', 'pending', or 'failed'.
  final String status;

  /// Settlement/payout target, joined in from `users` by the backend. All
  /// nullable — a customer who has not filed bank details yet comes back with
  /// these empty.
  final String? bankName;
  final String? bankAccountHolder;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? upiId;

  final DateTime? createdAt;

  /// Months already paid on the cycle this payout belongs to (`days_paid`,
  /// repurposed). Only known for engine payouts, whose description carries
  /// "Cycle #N" — joined in from `admin/payout_history.php`.
  final int? cycleMonthsPaid;

  const YieldDisbursement({
    required this.id,
    required this.userId,
    required this.customerName,
    this.customerEmail,
    required this.category,
    required this.grossAmount,
    required this.tdsAmount,
    required this.chargesAmount,
    required this.netAmount,
    this.description,
    this.status = 'completed',
    this.bankName,
    this.bankAccountHolder,
    this.bankAccountNumber,
    this.bankIfsc,
    this.upiId,
    this.createdAt,
    this.cycleMonthsPaid,
  });

  /// Parses a `history` row from `admin/payout_reports.php`, which returns
  /// `t.*` joined to the user — so `user_name` / `user_email` / `amount`
  /// (already NET of deductions) / `account_no` / `ifsc_code`. The
  /// alternative key on each line is what a purpose-built
  /// `yield_disbursements.php` would more naturally return, kept so either
  /// shape parses.
  factory YieldDisbursement.fromJson(Map<String, dynamic> json,
      {int? cycleMonthsPaid}) {
    final gross = _toDouble(json['gross_amount']);
    final tds = _toDouble(json['tds_amount']);
    final charges = _toDouble(json['charges_amount']);

    // `amount` on a transactions row is what was actually credited.
    final net = json['net_amount'] ?? json['amount'];

    return YieldDisbursement(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      customerName: (json['user_name'] ?? json['customer_name'] ?? 'Unknown').toString(),
      customerEmail: (json['user_email'] ?? json['customer_email'])?.toString(),
      category: (json['category'] ?? 'cashback').toString(),
      grossAmount: gross,
      tdsAmount: tds,
      chargesAmount: charges,
      netAmount: net != null ? _toDouble(net) : (gross - tds - charges),
      description: json['description']?.toString(),
      status: (json['status'] ?? 'completed').toString(),
      bankName: json['bank_name']?.toString(),
      bankAccountHolder: json['account_holder_name']?.toString(),
      bankAccountNumber: (json['account_no'] ?? json['bank_account_number'])?.toString(),
      bankIfsc: (json['ifsc_code'] ?? json['bank_ifsc'])?.toString(),
      upiId: json['upi_id']?.toString(),
      createdAt: _parseDate(json['created_at']),
      cycleMonthsPaid: cycleMonthsPaid,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static final RegExp _monthPattern =
      RegExp(r'month\s+(\d+)\s+of\s+(\d+)', caseSensitive: false);

  /// "Month 3 of 10" as written into the description by the yield engine and
  /// by the wallet-adjustment cashback payout; null for anything else.
  (int month, int of)? get descriptionMonth {
    final m = _monthPattern.firstMatch(description ?? '');
    if (m == null) return null;
    return (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  bool get isCashback => category.toLowerCase() == 'cashback';
  bool get isReferral => category.toLowerCase() == 'referral';

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isPending => status.toLowerCase() == 'pending';

  /// Short label for the "YIELD DETAILS" column, e.g. "CASHBACK · ₹5,000.00".
  String get categoryLabel => category.toUpperCase();

  /// Human summary for the "SETTLEMENT TARGET (BANK)" column.
  String get settlementTargetLabel {
    if (upiId != null && upiId!.isNotEmpty) return upiId!;
    if (bankAccountNumber != null && bankAccountNumber!.isNotEmpty) {
      final last4 = bankAccountNumber!.length > 4
          ? bankAccountNumber!.substring(bankAccountNumber!.length - 4)
          : bankAccountNumber!;
      final masked = 'A/C ••••$last4';
      final bank = bankName?.trim() ?? '';
      return bank.isEmpty ? masked : '$bank · $masked';
    }
    return 'No payout method on file';
  }
}

/// Combined payload for the dashboard: the stat-card summary from
/// `admin/payout_history.php` plus the disbursement rows from
/// `admin/payout_reports.php`, merged by YieldService.
class YieldDashboardData {
  final YieldSummary summary;
  final List<YieldDisbursement> disbursements;

  const YieldDashboardData({
    required this.summary,
    required this.disbursements,
  });

  factory YieldDashboardData.fromJson(Map<String, dynamic> json) {
    return YieldDashboardData(
      summary: YieldSummary.fromJson(json['summary'] as Map<String, dynamic>?),
      disbursements: parseRows(
        json['disbursements'] ?? json['history'] ?? json['data'],
      ),
    );
  }

  /// Maps a raw JSON list of ledger rows into models, skipping anything that
  /// is not a JSON object rather than throwing on a malformed row.
  static List<YieldDisbursement> parseRows(dynamic raw,
      {Map<String, int> monthsPaidByTxId = const {}}) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) {
      final json = e.cast<String, dynamic>();
      return YieldDisbursement.fromJson(json,
          cycleMonthsPaid: monthsPaidByTxId[json['id']?.toString()]);
    }).toList();
  }

  /// `admin/payout_history.php` rows → { transaction id: cycle months paid }.
  static Map<String, int> monthsPaidIndex(dynamic raw) {
    if (raw is! List) return const {};
    final index = <String, int>{};
    for (final row in raw.whereType<Map>()) {
      final id = row['id']?.toString();
      final paid = int.tryParse('${row['current_day']}');
      if (id != null && paid != null) index[id] = paid;
    }
    return index;
  }

  /// Plan length used for "Month X of N" when a row's description doesn't
  /// say — taken from any engine description in the data, else 10.
  int get planMonths {
    for (final row in disbursements) {
      final m = row.descriptionMonth;
      if (m != null && m.$2 > 0) return m.$2;
    }
    return 10;
  }
}