// lib/features/auditor/models/referral_summary.dart
//
// Adjust the package path above to wherever your project keeps feature
// models (e.g. lib/features/auditor/models/, lib/models/, etc).

class ReferralSummary {
  final String referralCode;
  final bool referralActive;
  final String dailyCashbackRate; // e.g. "2%"
  final String commissionRate; // e.g. "2%"
  final double commissionRateNum; // e.g. 2.0
  final int directCount;
  final double tdsRate;
  final double serviceChargeRate;
  final double totalDeductionRate;
  final double totalNetworkEarnings; // net credited
  final double totalNetworkGross;
  final double totalNetworkTds;
  final double totalNetworkCharges;
  final double totalNetworkDeduction;
  final double todayEarnings;
  final int progress; // == directCount, kept separate to match API
  final bool eligible;
  final List<DirectReferral> directReferrals;
  final double userInvestment;
  final List<ReferralTransaction> history;

  const ReferralSummary({
    required this.referralCode,
    required this.referralActive,
    required this.dailyCashbackRate,
    required this.commissionRate,
    required this.commissionRateNum,
    required this.directCount,
    required this.tdsRate,
    required this.serviceChargeRate,
    required this.totalDeductionRate,
    required this.totalNetworkEarnings,
    required this.totalNetworkGross,
    required this.totalNetworkTds,
    required this.totalNetworkCharges,
    required this.totalNetworkDeduction,
    required this.todayEarnings,
    required this.progress,
    required this.eligible,
    required this.directReferrals,
    required this.userInvestment,
    required this.history,
  });

  /// A 10-member cap is baked into the current commission rules card.
  /// Exposed here so the UI doesn't hardcode the number twice.
  static const int directLinkCap = 10;

  factory ReferralSummary.empty() => const ReferralSummary(
        referralCode: 'N/A',
        referralActive: true,
        dailyCashbackRate: '0%',
        commissionRate: '0%',
        commissionRateNum: 0,
        directCount: 0,
        tdsRate: 0,
        serviceChargeRate: 0,
        totalDeductionRate: 0,
        totalNetworkEarnings: 0,
        totalNetworkGross: 0,
        totalNetworkTds: 0,
        totalNetworkCharges: 0,
        totalNetworkDeduction: 0,
        todayEarnings: 0,
        progress: 0,
        eligible: true,
        directReferrals: [],
        userInvestment: 0,
        history: [],
      );

  factory ReferralSummary.fromJson(Map<String, dynamic> json) {
    return ReferralSummary(
      referralCode: (json['referral_code'] ?? 'N/A').toString(),
      referralActive: _toBool(json['referral_active']),
      dailyCashbackRate: (json['daily_cashback_rate'] ?? '0%').toString(),
      commissionRate: (json['commission_rate'] ?? '0%').toString(),
      commissionRateNum: _toDouble(json['commission_rate_num']),
      directCount: _toInt(json['direct_count']),
      tdsRate: _toDouble(json['tds_rate']),
      serviceChargeRate: _toDouble(json['service_charge_rate']),
      totalDeductionRate: _toDouble(json['total_deduction_rate']),
      totalNetworkEarnings: _toDouble(json['total_network_earnings']),
      totalNetworkGross: _toDouble(json['total_network_gross']),
      totalNetworkTds: _toDouble(json['total_network_tds']),
      totalNetworkCharges: _toDouble(json['total_network_charges']),
      totalNetworkDeduction: _toDouble(json['total_network_deduction']),
      todayEarnings: _toDouble(json['today_earnings']),
      progress: _toInt(json['progress']),
      eligible: json['eligible'] == true,
      directReferrals: ((json['direct_referrals'] as List?) ?? [])
          .map((e) => DirectReferral.fromJson(e as Map<String, dynamic>))
          .toList(),
      userInvestment: _toDouble(json['user_investment']),
      history: ((json['history'] as List?) ?? [])
          .map((e) => ReferralTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static bool _toBool(dynamic v) {
    return v == true || v == 1 || v == '1';
  }
}

class DirectReferral {
  final int id;
  final String? customerId;
  final String name;
  final DateTime? createdAt;
  final String kycStatus;
  final double invested;

  const DirectReferral({
    required this.id,
    required this.customerId,
    required this.name,
    required this.createdAt,
    required this.kycStatus,
    required this.invested,
  });

  factory DirectReferral.fromJson(Map<String, dynamic> json) {
    return DirectReferral(
      id: ReferralSummary._toInt(json['id']),
      customerId: json['customer_id']?.toString(),
      name: (json['name'] ?? 'Unnamed').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      kycStatus: (json['kyc_status'] ?? 'pending').toString(),
      invested: ReferralSummary._toDouble(json['invested']),
    );
  }
}

class ReferralTransaction {
  final int id;
  final double amount;
  final double grossAmount;
  final double tdsAmount;
  final double chargesAmount;
  final double deduction;
  final String description;
  final DateTime? createdAt;
  final String status;

  const ReferralTransaction({
    required this.id,
    required this.amount,
    required this.grossAmount,
    required this.tdsAmount,
    required this.chargesAmount,
    required this.deduction,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  factory ReferralTransaction.fromJson(Map<String, dynamic> json) {
    return ReferralTransaction(
      id: ReferralSummary._toInt(json['id']),
      amount: ReferralSummary._toDouble(json['amount']),
      grossAmount: ReferralSummary._toDouble(json['gross_amount']),
      tdsAmount: ReferralSummary._toDouble(json['tds_amount']),
      chargesAmount: ReferralSummary._toDouble(json['charges_amount']),
      deduction: ReferralSummary._toDouble(json['deduction']),
      description: (json['description'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      status: (json['status'] ?? '').toString(),
    );
  }
}