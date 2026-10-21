/// A single investor wallet row, as returned by `api/admin/wallets.php`.
class WalletAccount {
  final String walletId;
  final String userId;
  final double balance;
  final double totalEarned;
  final double totalWithdrawn;
  final String userName;
  final String? userEmail;
  final String? userPhone;
  final String? role;
  final String? kycStatus;
  final int activeCycles;
  final DateTime? lastPayoutAt;
  final int txCount;

  const WalletAccount({
    required this.walletId,
    required this.userId,
    required this.balance,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.userName,
    this.userEmail,
    this.userPhone,
    this.role,
    this.kycStatus,
    this.activeCycles = 0,
    this.lastPayoutAt,
    this.txCount = 0,
  });

  factory WalletAccount.fromJson(Map<String, dynamic> json) {
    return WalletAccount(
      walletId: json['wallet_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      balance: _toDouble(json['balance']),
      totalEarned: _toDouble(json['total_earned']),
      totalWithdrawn: _toDouble(json['total_withdrawn']),
      userName: (json['user_name'] ?? '').toString(),
      userEmail: json['user_email']?.toString(),
      userPhone: json['user_phone']?.toString(),
      role: json['role']?.toString(),
      kycStatus: json['kyc_status']?.toString(),
      activeCycles: _toInt(json['active_cycles']),
      lastPayoutAt: _parseDate(json['last_payout_at']),
      txCount: _toInt(json['tx_count']),
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

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  bool get isKycVerified {
    final s = (kycStatus ?? '').toLowerCase();
    return s == 'verified' || s == 'approved';
  }

  /// "01 SEP" style short date for the last-yield column, or a placeholder
  /// when no cashback cycle has ever paid out.
  String get lastPayoutLabel {
    final d = lastPayoutAt;
    if (d == null) return '—';
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final day = d.day.toString().padLeft(2, '0');
    return '$day ${months[d.month - 1]}';
  }

  /// Indian-style digit grouping (₹4,22,991.71) matching how the platform
  /// displays currency elsewhere.
  String get formattedBalance => formatInr(balance);
  String get formattedEarned => formatInr(totalEarned);
  String get formattedWithdrawn => formatInr(totalWithdrawn);
}

/// Formats [value] as ₹ with Indian (lakh/crore) digit grouping, e.g.
/// 422991.71 -> "₹4,22,991.71".
String formatInr(double value) {
  final isNegative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  var whole = parts[0];
  final decimals = parts[1];

  String grouped;
  if (whole.length <= 3) {
    grouped = whole;
  } else {
    final last3 = whole.substring(whole.length - 3);
    final segments = <String>[];
    var remainder = whole.substring(0, whole.length - 3);
    while (remainder.length > 2) {
      segments.insert(0, remainder.substring(remainder.length - 2));
      remainder = remainder.substring(0, remainder.length - 2);
    }
    segments.insert(0, remainder);
    grouped = '${segments.join(',')},$last3';
  }

  return '${isNegative ? '-' : ''}₹$grouped.$decimals';
}

class WalletLedger {
  final List<WalletLedgerEntry> entries;
  final double credits, debits, tds, charges;

  /// The investor's VEV id (`users.customer_id`), taken from the rows.
  final String customerId;
  const WalletLedger(
      {required this.entries,
      required this.credits,
      required this.debits,
      required this.tds,
      required this.charges,
      this.customerId = ''});
  factory WalletLedger.fromJson(Map json, List<WalletLedgerEntry> entries,
          {String customerId = ''}) =>
      WalletLedger(
        entries: entries,
        customerId: customerId,
        credits: WalletAccount._toDouble(json['total_credits']),
        debits: WalletAccount._toDouble(json['total_debits']),
        tds: WalletAccount._toDouble(json['total_tds']),
        charges: WalletAccount._toDouble(json['total_charges']),
      );
}

class WalletLedgerEntry {
  final String type, category, description, status;
  final double amount, gross, tds, charges;
  final DateTime? createdAt;
  const WalletLedgerEntry(
      {required this.type,
      required this.category,
      required this.description,
      required this.status,
      required this.amount,
      required this.gross,
      required this.tds,
      required this.charges,
      this.createdAt});
  factory WalletLedgerEntry.fromJson(Map<String, dynamic> j) =>
      WalletLedgerEntry(
        type: j['type']?.toString() ?? '',
        category: j['category']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        amount: WalletAccount._toDouble(j['amount']),
        gross: WalletAccount._toDouble(j['gross_amount']),
        tds: WalletAccount._toDouble(j['tds_amount']),
        charges: WalletAccount._toDouble(j['charges_amount']),
        createdAt: WalletAccount._parseDate(j['created_at']),
      );
  bool get isCredit => type.toLowerCase() == 'credit';
}

/// One investor's live cashback plan, from `admin/get_user_daily_payout.php`.
///
/// The endpoint predates the move to monthly installments, so several keys
/// still say "daily" — each of them now holds the MONTHLY installment.
class WalletPayoutPlan {
  final double monthlyGross;
  final double monthlyTds;
  final double monthlyCharges;
  final double monthlyNet;
  final double totalInvested; // incl. GST — what the customer paid
  final double totalEligible; // ex-GST 100% cashback cap
  final double totalEarned;
  final double remaining; // cap still left to pay
  final double cashbackPct;
  final int monthsCompleted;
  final int planMonths;
  final int activeCycles;
  final double walletBalance;
  final double totalWithdrawn;
  final String assetLabel;

  const WalletPayoutPlan({
    required this.monthlyGross,
    required this.monthlyTds,
    required this.monthlyCharges,
    required this.monthlyNet,
    required this.totalInvested,
    required this.totalEligible,
    required this.totalEarned,
    required this.remaining,
    required this.cashbackPct,
    required this.monthsCompleted,
    required this.planMonths,
    required this.activeCycles,
    required this.walletBalance,
    required this.totalWithdrawn,
    required this.assetLabel,
  });

  factory WalletPayoutPlan.fromJson(Map<String, dynamic> j) {
    const d = WalletAccount._toDouble;
    const i = WalletAccount._toInt;
    final cycles = (j['cycles'] as List? ?? const []).whereType<Map>().toList();
    return WalletPayoutPlan(
      monthlyGross: d(j['total_monthly_payout'] ?? j['total_daily_payout']),
      monthlyTds: d(j['total_daily_tds']),
      monthlyCharges: d(j['total_daily_charges']),
      monthlyNet: d(j['total_monthly_net'] ?? j['total_daily_net']),
      totalInvested: d(j['total_invested']),
      totalEligible: d(j['total_eligible']),
      totalEarned: d(j['total_earned']),
      remaining: d(j['remaining_value']),
      cashbackPct: d(j['cashback_percentage']),
      monthsCompleted: i(j['months_completed'] ?? j['days_completed']),
      planMonths: i(j['plan_months']) < 1 ? 10 : i(j['plan_months']),
      activeCycles: i(j['active_cycles']),
      walletBalance: d(j['wallet_balance']),
      totalWithdrawn: d(j['total_withdrawn']),
      assetLabel: cycles.isEmpty ? '' : _assetLabel(cycles.first),
    );
  }

  static String _assetLabel(Map cycle) {
    final type = (cycle['asset_type'] ?? '').toString().toLowerCase();
    if (type == 'product') {
      final name = (cycle['product_name'] ?? '').toString().trim();
      return name.isEmpty ? 'PRODUCT PURCHASE' : name.toUpperCase();
    }
    return type == 'silver' ? 'PURE SILVER ASSET' : '22K GOLD ASSET';
  }

  bool get hasActivePlan => activeCycles > 0 && monthlyNet > 0;

  int get monthsLeft =>
      (planMonths - monthsCompleted).clamp(0, planMonths).toInt();

  /// Whole monthly installments that can still be paid — limited by both the
  /// months left on the plan and the remaining cashback cap.
  int get maxPayableMonths {
    if (!hasActivePlan) return 0;
    final byCap = ((remaining + 0.01) / monthlyNet).floor();
    return byCap < monthsLeft ? byCap : monthsLeft;
  }

  /// One installment as a % of principal, e.g. 10 for a 10-month plan.
  double get monthlyRatePct => 100 / planMonths;
}
