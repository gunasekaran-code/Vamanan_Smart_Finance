class AuditorDashboardSummary {
  final double revenue;
  final double taxable;
  final double payoutsNet;
  final double cashbackNet;
  final double referralNet;
  final double walletLiability;
  final double withdrawnPaid;
  final double withdrawPending;
  final int customers;
  final int activeCycles;
  final int transactions;

  const AuditorDashboardSummary({
    required this.revenue,
    required this.taxable,
    required this.payoutsNet,
    required this.cashbackNet,
    required this.referralNet,
    required this.walletLiability,
    required this.withdrawnPaid,
    required this.withdrawPending,
    required this.customers,
    required this.activeCycles,
    required this.transactions,
  });

  factory AuditorDashboardSummary.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int toInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return AuditorDashboardSummary(
      revenue: toDouble(json['revenue']),
      taxable: toDouble(json['taxable']),
      payoutsNet: toDouble(json['payouts_net']),
      cashbackNet: toDouble(json['cashback_net']),
      referralNet: toDouble(json['referral_net']),
      walletLiability: toDouble(json['wallet_liability']),
      withdrawnPaid: toDouble(json['withdrawn_paid']),
      withdrawPending: toDouble(json['withdraw_pending']),
      customers: toInt(json['customers']),
      activeCycles: toInt(json['active_cycles']),
      transactions: toInt(json['transactions']),
    );
  }
}
