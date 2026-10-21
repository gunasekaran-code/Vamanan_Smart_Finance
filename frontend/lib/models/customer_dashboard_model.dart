/// Models the JSON returned by `api/customer/dashboard.php`.
///
/// GET /customer/dashboard.php?user_id=N
///   -> { status, data: { user, balance, cycles, active_cycle, transactions,
///                        incentive_breakdown, referrals_count, customer_id,
///                        referral_code, agreement_id, notifications } }
///
/// Every figure here is scoped to the one `user_id` in the query string. That
/// is the whole reason this exists alongside the auditor dashboard model:
/// `auditor/summary.php` reports platform-wide revenue, GST and wallet
/// liability, which a customer must never see.
class CustomerDashboard {
  final double balance;
  final CustomerPlan plan;
  final IncentiveBreakdown incentives;
  final int referralsCount;
  final String customerId;
  final String referralCode;
  final String? agreementId;
  final List<CustomerTransaction> transactions;
  final List<CustomerNotice> notifications;

  /// Every `cashback_cycles` row for this user — one per purchase. Backs the
  /// ORDERS & INVOICES list.
  final List<CustomerCycle> cycles;

  const CustomerDashboard({
    this.balance = 0,
    this.plan = const CustomerPlan(),
    this.incentives = const IncentiveBreakdown(),
    this.referralsCount = 0,
    this.customerId = '',
    this.referralCode = '',
    this.agreementId,
    this.transactions = const [],
    this.notifications = const [],
    this.cycles = const [],
  });

  bool get hasAgreement => (agreementId ?? '').isNotEmpty;

  factory CustomerDashboard.fromJson(Map<String, dynamic> json) {
    return CustomerDashboard(
      balance: asDouble(json['balance']),
      plan: CustomerPlan.fromJson(_map(json['active_cycle'])),
      incentives: IncentiveBreakdown.fromJson(_map(json['incentive_breakdown'])),
      referralsCount: asInt(json['referrals_count']),
      customerId: (json['customer_id'] ?? '').toString(),
      referralCode: (json['referral_code'] ?? '').toString(),
      agreementId: json['agreement_id']?.toString(),
      transactions: _list(json['transactions'])
          .map(CustomerTransaction.fromJson)
          .toList(growable: false),
      notifications: _list(json['notifications'])
          .map(CustomerNotice.fromJson)
          .toList(growable: false),
      cycles: _list(json['cycles'])
          .map(CustomerCycle.fromJson)
          .toList(growable: false),
    );
  }

  static Map<String, dynamic> _map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : const {};

  static List<Map<String, dynamic>> _list(Object? v) => v is List
      ? v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false)
      : const [];

  /// PHP hands numerics back as strings often enough (PDO returns column
  /// values as strings unless emulation is off) that every numeric read goes
  /// through these rather than a cast.
  static double asDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse((v ?? '').toString()) ?? 0;
  }

  static int asInt(Object? v) {
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '').toString()) ?? 0;
  }
}

/// The aggregated `active_cycle` block — the customer's cashback plan as a
/// whole, not a single row of `cashback_cycles`.
///
/// dashboard.php repurposed the legacy daily fields into monthly ones and
/// emits both spellings (`days_remaining` / `months_remaining`,
/// `daily_payout` / `monthly_payout`). The monthly aliases are read first and
/// the daily ones kept as the fallback, so this parses an older backend too.
class CustomerPlan {
  /// Total paid, GST inclusive.
  final double totalValue;

  /// Ex-GST product value — the base cashback is measured against.
  final double eligibleAmount;
  final double gstAmount;
  final double totalEarned;
  final double remainingValue;
  final double cashbackPercentage;

  final int planMonths;
  final int monthsCompleted;
  final int monthsRemaining;

  /// Gross monthly installment, and what actually lands after TDS + charges.
  final double monthlyPayout;
  final double monthlyPayoutNet;
  final double monthlyRate;

  final double tdsRate;
  final double serviceChargeRate;

  final int activePlansCount;
  final String status;
  final String assetType;
  final String productName;
  final double weight;

  final double todayEarning;
  final double totalReferralEarned;
  final bool isClosingSoon;

  const CustomerPlan({
    this.totalValue = 0,
    this.eligibleAmount = 0,
    this.gstAmount = 0,
    this.totalEarned = 0,
    this.remainingValue = 0,
    this.cashbackPercentage = 0,
    this.planMonths = 10,
    this.monthsCompleted = 0,
    this.monthsRemaining = 0,
    this.monthlyPayout = 0,
    this.monthlyPayoutNet = 0,
    this.monthlyRate = 0,
    this.tdsRate = 0,
    this.serviceChargeRate = 0,
    this.activePlansCount = 0,
    this.status = 'none',
    this.assetType = 'gold',
    this.productName = 'Investment Portfolio',
    this.weight = 0,
    this.todayEarning = 0,
    this.totalReferralEarned = 0,
    this.isClosingSoon = false,
  });

  bool get hasPlan => status != 'none' && totalValue > 0;

  /// 0..1, for the progress bar. Derived from [cashbackPercentage] so the bar
  /// and the headline figure can never disagree.
  double get progress => (cashbackPercentage / 100).clamp(0.0, 1.0);

  factory CustomerPlan.fromJson(Map<String, dynamic> json) {
    double d(String key, [String? fallbackKey]) {
      final v = json[key] ?? (fallbackKey == null ? null : json[fallbackKey]);
      return CustomerDashboard.asDouble(v);
    }

    int i(String key, String fallbackKey, int fallback) {
      final raw = json[key] ?? json[fallbackKey];
      if (raw == null) return fallback;
      return CustomerDashboard.asInt(raw);
    }

    return CustomerPlan(
      totalValue: d('total_value'),
      eligibleAmount: d('cashback_eligible', 'product_amount'),
      gstAmount: d('gst_amount'),
      totalEarned: d('total_earned'),
      remainingValue: d('remaining_value'),
      cashbackPercentage: d('cashback_percentage'),
      planMonths: i('plan_months', 'plan_months', 10),
      monthsCompleted: i('months_completed', 'days_completed', 0),
      monthsRemaining: i('months_remaining', 'days_remaining', 0),
      monthlyPayout: d('monthly_payout', 'daily_payout'),
      monthlyPayoutNet: d('monthly_payout_net', 'daily_payout_net'),
      monthlyRate: d('monthly_rate', 'daily_rate'),
      tdsRate: d('tds_rate'),
      serviceChargeRate: d('service_charge_rate'),
      activePlansCount: CustomerDashboard.asInt(json['active_plans_count']),
      status: (json['status'] ?? 'none').toString(),
      assetType: (json['asset_type'] ?? 'gold').toString(),
      productName:
          (json['product_name'] ?? 'Investment Portfolio').toString(),
      weight: d('weight'),
      todayEarning: d('today_earning'),
      totalReferralEarned: d('total_referral_earned'),
      isClosingSoon: json['is_closing_soon'] == true ||
          (json['is_closing_soon'] ?? '').toString() == '1',
    );
  }
}

/// Realised cashback + referral credits, and what was withheld from them.
class IncentiveBreakdown {
  final double gross;
  final double tds;
  final double charges;
  final double deduction;
  final double net;

  const IncentiveBreakdown({
    this.gross = 0,
    this.tds = 0,
    this.charges = 0,
    this.deduction = 0,
    this.net = 0,
  });

  bool get hasDeductions => deduction > 0;

  factory IncentiveBreakdown.fromJson(Map<String, dynamic> json) {
    return IncentiveBreakdown(
      gross: CustomerDashboard.asDouble(json['gross']),
      tds: CustomerDashboard.asDouble(json['tds']),
      charges: CustomerDashboard.asDouble(json['charges']),
      deduction: CustomerDashboard.asDouble(json['deduction']),
      net: CustomerDashboard.asDouble(json['net']),
    );
  }
}

/// One row of the wallet ledger, as `models/Wallet.php::getTransactions`
/// returns it.
class CustomerTransaction {
  final String id;
  final String type; // credit | debit
  final String category; // cashback | referral | withdrawal | purchase | ...
  final double amount;
  final String status;
  final String description;
  final DateTime? createdAt;

  const CustomerTransaction({
    this.id = '',
    this.type = 'credit',
    this.category = '',
    this.amount = 0,
    this.status = '',
    this.description = '',
    this.createdAt,
  });

  bool get isCredit => type.toLowerCase() == 'credit';

  factory CustomerTransaction.fromJson(Map<String, dynamic> json) {
    return CustomerTransaction(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'credit').toString().toLowerCase(),
      category: (json['category'] ?? '').toString(),
      amount: CustomerDashboard.asDouble(json['amount']),
      status: (json['status'] ?? '').toString(),
      description: (json['description'] ?? json['remarks'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}

/// A broadcast or personal notification. dashboard.php selects only
/// `title, message, created_at`, so there is no id to mark-as-read with here.
class CustomerNotice {
  final String title;
  final String message;
  final DateTime? createdAt;

  const CustomerNotice({
    this.title = '',
    this.message = '',
    this.createdAt,
  });

  factory CustomerNotice.fromJson(Map<String, dynamic> json) {
    return CustomerNotice(
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}

/// One row of `cashback_cycles` — a single purchase and the plan running off
/// it. `dashboard.php` returns these under `cycles`, newest first.
class CustomerCycle {
  final String id;
  final String productName;
  final String assetType;
  final double weight;

  /// GST-inclusive total paid, and the ex-GST base cashback is measured on.
  final double totalValue;
  final double gstAmount;
  final double eligibleAmount;

  final double paidAmount;
  final double monthlyPayout;
  final int monthsPaid;
  final String status;
  final String transactionId;
  final DateTime? createdAt;

  const CustomerCycle({
    this.id = '',
    this.productName = '',
    this.assetType = 'gold',
    this.weight = 0,
    this.totalValue = 0,
    this.gstAmount = 0,
    this.eligibleAmount = 0,
    this.paidAmount = 0,
    this.monthlyPayout = 0,
    this.monthsPaid = 0,
    this.status = 'pending',
    this.transactionId = '',
    this.createdAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isPending => status.toLowerCase() == 'pending';

  /// A tax invoice only exists once the purchase has been approved.
  bool get hasInvoice => !isPending && status.toLowerCase() != 'rejected';

  /// dashboard.php splits GST evenly into CGST and SGST for an intra-state
  /// sale, which is what every invoice in this system is.
  double get cgst => gstAmount / 2;
  double get sgst => gstAmount / 2;

  /// Falls back to the asset when the row carries no product name, matching
  /// how dashboard.php labels a plain bullion buy.
  String get displayName {
    if (productName.trim().isNotEmpty) return productName.trim();
    return assetType.toLowerCase() == 'silver'
        ? 'Pure Silver Asset'
        : '22K Gold Asset';
  }

  factory CustomerCycle.fromJson(Map<String, dynamic> json) {
    final eligible = CustomerDashboard.asDouble(
        json['cashback_eligible_amount'] ?? json['product_amount']);
    final total = CustomerDashboard.asDouble(json['total_value']);

    return CustomerCycle(
      id: (json['id'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      assetType: (json['asset_type'] ?? 'gold').toString(),
      weight: CustomerDashboard.asDouble(json['weight']),
      totalValue: total,
      gstAmount: CustomerDashboard.asDouble(json['gst_amount']),
      // Legacy rows predate the GST split and carry no eligible amount.
      eligibleAmount: eligible > 0 ? eligible : total,
      paidAmount: CustomerDashboard.asDouble(json['paid_amount']),
      monthlyPayout: CustomerDashboard.asDouble(json['daily_payout']),
      monthsPaid: CustomerDashboard.asInt(json['days_paid']),
      status: (json['status'] ?? 'pending').toString(),
      transactionId: (json['transaction_id'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}
