// auditor_cashback_model.dart — models for /auditor/summary.php and /auditor/ledger.php

double _d(dynamic v) =>
    v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);

int _i(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

/// GET /auditor/summary.php -> data
class CashbackSummary {
  final double revenue;
  final double taxable;
  final double gstCollected;
  final double cgst;
  final double sgst;
  final int invoiceCount;

  final double payoutsNet;
  final double payoutsGross;
  final double tdsWithheld;
  final double chargesWithheld;
  final double cashbackNet;
  final double referralNet;

  final double walletLiability;
  final double withdrawnPaid;
  final double withdrawPending;

  final int customers;
  final int activeCycles;
  final int transactions;

  final String? lastMonthlyRun;
  final String? lastDailyRun;

  final List<MonthlyStatement> monthlyStatement;

  const CashbackSummary({
    required this.revenue,
    required this.taxable,
    required this.gstCollected,
    required this.cgst,
    required this.sgst,
    required this.invoiceCount,
    required this.payoutsNet,
    required this.payoutsGross,
    required this.tdsWithheld,
    required this.chargesWithheld,
    required this.cashbackNet,
    required this.referralNet,
    required this.walletLiability,
    required this.withdrawnPaid,
    required this.withdrawPending,
    required this.customers,
    required this.activeCycles,
    required this.transactions,
    this.lastMonthlyRun,
    this.lastDailyRun,
    required this.monthlyStatement,
  });

  factory CashbackSummary.fromJson(Map<String, dynamic> j) => CashbackSummary(
        revenue: _d(j['revenue']),
        taxable: _d(j['taxable']),
        gstCollected: _d(j['gst_collected']),
        cgst: _d(j['cgst']),
        sgst: _d(j['sgst']),
        invoiceCount: _i(j['invoice_count']),
        payoutsNet: _d(j['payouts_net']),
        payoutsGross: _d(j['payouts_gross']),
        tdsWithheld: _d(j['tds_withheld']),
        chargesWithheld: _d(j['charges_withheld']),
        cashbackNet: _d(j['cashback_net']),
        referralNet: _d(j['referral_net']),
        walletLiability: _d(j['wallet_liability']),
        withdrawnPaid: _d(j['withdrawn_paid']),
        withdrawPending: _d(j['withdraw_pending']),
        customers: _i(j['customers']),
        activeCycles: _i(j['active_cycles']),
        transactions: _i(j['transactions']),
        lastMonthlyRun: j['last_monthly_run'] as String?,
        lastDailyRun: j['last_daily_run'] as String?,
        monthlyStatement: (j['monthly_statement'] as List<dynamic>? ?? [])
            .map((e) => MonthlyStatement.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  factory CashbackSummary.empty() => const CashbackSummary(
        revenue: 0,
        taxable: 0,
        gstCollected: 0,
        cgst: 0,
        sgst: 0,
        invoiceCount: 0,
        payoutsNet: 0,
        payoutsGross: 0,
        tdsWithheld: 0,
        chargesWithheld: 0,
        cashbackNet: 0,
        referralNet: 0,
        walletLiability: 0,
        withdrawnPaid: 0,
        withdrawPending: 0,
        customers: 0,
        activeCycles: 0,
        transactions: 0,
        monthlyStatement: [],
      );
}

class MonthlyStatement {
  final String month; // 'YYYY-MM'
  final double revenue;
  final double gst;
  final double taxable;
  final double payouts;
  final double deductions;

  const MonthlyStatement({
    required this.month,
    required this.revenue,
    required this.gst,
    required this.taxable,
    required this.payouts,
    required this.deductions,
  });

  factory MonthlyStatement.fromJson(Map<String, dynamic> j) => MonthlyStatement(
        month: j['month'] as String? ?? '',
        revenue: _d(j['revenue']),
        gst: _d(j['gst']),
        taxable: _d(j['taxable']),
        payouts: _d(j['payouts']),
        deductions: _d(j['deductions']),
      );
}

/// One row of GET /auditor/ledger.php -> data[]
class LedgerTransaction {
  final int id;
  final String type; // credit | debit
  final String category; // cashback | referral | ...
  final double amount; // net
  final double grossAmount;
  final double tdsAmount;
  final double chargesAmount;
  final double deduction;
  final String description;
  final String status;
  final DateTime createdAt;
  final int userId;
  final String userName;
  final String customerId;

  const LedgerTransaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.grossAmount,
    required this.tdsAmount,
    required this.chargesAmount,
    required this.deduction,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.userId,
    required this.userName,
    required this.customerId,
  });

  bool get isCredit => type == 'credit';

  factory LedgerTransaction.fromJson(Map<String, dynamic> j) => LedgerTransaction(
        id: _i(j['id']),
        type: j['type'] as String? ?? '',
        category: j['category'] as String? ?? '',
        amount: _d(j['amount']),
        grossAmount: _d(j['gross_amount'] ?? j['amount']),
        tdsAmount: _d(j['tds_amount']),
        chargesAmount: _d(j['charges_amount']),
        deduction: _d(j['deduction']),
        description: j['description'] as String? ?? '',
        status: j['status'] as String? ?? '',
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
        userId: _i(j['user_id']),
        userName: j['user_name'] as String? ?? '',
        customerId: j['customer_id']?.toString() ?? '',
      );
}

/// GET /auditor/ledger.php -> summary
class LedgerSummary {
  final int count;
  final double totalCredits;
  final double totalDebits;
  final double totalGross;
  final double totalTds;
  final double totalCharges;
  final double netFlow;
  final int shown;

  const LedgerSummary({
    required this.count,
    required this.totalCredits,
    required this.totalDebits,
    required this.totalGross,
    required this.totalTds,
    required this.totalCharges,
    required this.netFlow,
    required this.shown,
  });

  factory LedgerSummary.fromJson(Map<String, dynamic> j) => LedgerSummary(
        count: _i(j['count']),
        totalCredits: _d(j['total_credits']),
        totalDebits: _d(j['total_debits']),
        totalGross: _d(j['total_gross']),
        totalTds: _d(j['total_tds']),
        totalCharges: _d(j['total_charges']),
        netFlow: _d(j['net_flow']),
        shown: _i(j['shown']),
      );

  factory LedgerSummary.empty() => const LedgerSummary(
        count: 0,
        totalCredits: 0,
        totalDebits: 0,
        totalGross: 0,
        totalTds: 0,
        totalCharges: 0,
        netFlow: 0,
        shown: 0,
      );
}

/// Full GET /auditor/ledger.php response
class LedgerResponse {
  final List<LedgerTransaction> rows;
  final LedgerSummary summary;

  const LedgerResponse({required this.rows, required this.summary});

  factory LedgerResponse.fromJson(Map<String, dynamic> j) => LedgerResponse(
        rows: (j['data'] as List<dynamic>? ?? [])
            .map((e) => LedgerTransaction.fromJson(e as Map<String, dynamic>))
            .toList(),
        summary: LedgerSummary.fromJson(
            (j['summary'] as Map<String, dynamic>?) ?? const {}),
      );

  factory LedgerResponse.empty() =>
      LedgerResponse(rows: const [], summary: LedgerSummary.empty());
}