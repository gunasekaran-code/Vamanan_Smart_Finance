/// Payload of `GET admin/reports.php?type=cashback`:
/// `{ summary, cycles_summary, history, cycles, chart }`.
class CashbackReport {
  final CashbackSummary summary;
  final CashbackCyclesSummary cyclesSummary;
  final List<CashbackTransaction> transactions;
  final List<CashbackCycle> cycles;
  final List<CashbackChartPoint> chart;

  const CashbackReport({
    required this.summary,
    required this.cyclesSummary,
    required this.transactions,
    required this.cycles,
    required this.chart,
  });

  factory CashbackReport.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> rows(String key) => (json[key] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return CashbackReport(
      summary: CashbackSummary.fromJson(_asMap(json['summary'])),
      cyclesSummary: CashbackCyclesSummary.fromJson(_asMap(json['cycles_summary'])),
      transactions: rows('history').map(CashbackTransaction.fromJson).toList(),
      cycles: rows('cycles').map(CashbackCycle.fromJson).toList(),
      chart: rows('chart').map(CashbackChartPoint.fromJson).toList(),
    );
  }

  factory CashbackReport.empty() => CashbackReport.fromJson(const {});
}

/// Aggregates over `transactions WHERE category = 'cashback'`.
class CashbackSummary {
  final int totalCount;
  final double totalAmount;
  final double successAmount; // completed payouts — lifetime distribution
  final double pendingAmount;
  final double dailyAmount; // credited today
  final double monthlyAmount; // credited this calendar month
  final double grossAmount;
  final double tdsAmount;
  final double chargesAmount;
  final double totalDeduction;
  final double netAmount;
  final String efficiency; // e.g. "98.9%" — computed server-side
  final int registryCount;

  const CashbackSummary({
    required this.totalCount,
    required this.totalAmount,
    required this.successAmount,
    required this.pendingAmount,
    required this.dailyAmount,
    required this.monthlyAmount,
    required this.grossAmount,
    required this.tdsAmount,
    required this.chargesAmount,
    required this.totalDeduction,
    required this.netAmount,
    required this.efficiency,
    required this.registryCount,
  });

  factory CashbackSummary.fromJson(Map<String, dynamic> json) => CashbackSummary(
        totalCount: _asInt(json['total_count']),
        totalAmount: _asDouble(json['total_amount']),
        successAmount: _asDouble(json['success_amount']),
        pendingAmount: _asDouble(json['pending_amount']),
        dailyAmount: _asDouble(json['daily_amount']),
        monthlyAmount: _asDouble(json['monthly_amount']),
        grossAmount: _asDouble(json['gross_amount']),
        tdsAmount: _asDouble(json['tds_amount']),
        chargesAmount: _asDouble(json['charges_amount']),
        totalDeduction: _asDouble(json['total_deduction']),
        netAmount: _asDouble(json['net_amount']),
        efficiency: json['efficiency']?.toString() ?? '0%',
        registryCount: _asInt(json['registry_count']),
      );
}

/// Aggregates over `cashback_cycles`.
class CashbackCyclesSummary {
  final int totalCycles;
  final int activeCycles;
  final int completedCycles;
  final int pendingCycles;
  final double dailyLiability; // sum of daily_payout over active cycles

  const CashbackCyclesSummary({
    required this.totalCycles,
    required this.activeCycles,
    required this.completedCycles,
    required this.pendingCycles,
    required this.dailyLiability,
  });

  factory CashbackCyclesSummary.fromJson(Map<String, dynamic> json) => CashbackCyclesSummary(
        totalCycles: _asInt(json['total_cycles']),
        activeCycles: _asInt(json['active_cycles']),
        completedCycles: _asInt(json['completed_cycles']),
        pendingCycles: _asInt(json['pending_cycles']),
        dailyLiability: _asDouble(json['daily_liability']),
      );
}

/// A cashback credit from `transactions`, joined to the payee.
class CashbackTransaction {
  final int id;
  final String userName;
  final String userEmail;
  final double amount; // net credited
  final double? grossAmount;
  final double? tdsAmount;
  final double? chargesAmount;
  final String description;
  final String status; // pending | completed | failed
  final DateTime? createdAt;

  const CashbackTransaction({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.amount,
    required this.grossAmount,
    required this.tdsAmount,
    required this.chargesAmount,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  bool get hasDeductions => grossAmount != null && grossAmount! > 0;

  factory CashbackTransaction.fromJson(Map<String, dynamic> json) => CashbackTransaction(
        id: _asInt(json['id']),
        userName: json['user_name']?.toString() ?? '',
        userEmail: json['user_email']?.toString() ?? '',
        amount: _asDouble(json['amount']),
        grossAmount: _asNullableDouble(json['gross_amount']),
        tdsAmount: _asNullableDouble(json['tds_amount']),
        chargesAmount: _asNullableDouble(json['charges_amount']),
        description: json['description']?.toString() ?? '',
        status: (json['status']?.toString() ?? 'completed').toLowerCase(),
        createdAt: _asDate(json['created_at']),
      );
}

/// A row from `cashback_cycles`, joined to the owner.
class CashbackCycle {
  final int id;
  final String userName;
  final String userEmail;
  final String assetType; // gold | silver | product
  final double weight;
  final String? productName;
  final double totalValue;
  final double dailyPayout;
  final double paidAmount;
  final String? transactionId;
  final String status; // active | completed | paused | pending | rejected | cancelled
  final DateTime? createdAt;

  const CashbackCycle({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.assetType,
    required this.weight,
    required this.productName,
    required this.totalValue,
    required this.dailyPayout,
    required this.paidAmount,
    required this.transactionId,
    required this.status,
    required this.createdAt,
  });

  factory CashbackCycle.fromJson(Map<String, dynamic> json) => CashbackCycle(
        id: _asInt(json['id']),
        userName: json['user_name']?.toString() ?? '',
        userEmail: json['user_email']?.toString() ?? '',
        assetType: (json['asset_type']?.toString() ?? 'gold').toLowerCase(),
        weight: _asDouble(json['weight']),
        productName: _blankToNull(json['product_name']),
        totalValue: _asDouble(json['total_value']),
        dailyPayout: _asDouble(json['daily_payout']),
        paidAmount: _asDouble(json['paid_amount']),
        transactionId: _blankToNull(json['transaction_id']),
        status: (json['status']?.toString() ?? 'pending').toLowerCase(),
        createdAt: _asDate(json['created_at']),
      );
}

class CashbackChartPoint {
  final DateTime? date;
  final double totalAmount;

  const CashbackChartPoint({required this.date, required this.totalAmount});

  factory CashbackChartPoint.fromJson(Map<String, dynamic> json) => CashbackChartPoint(
        date: _asDate(json['date']),
        totalAmount: _asDouble(json['total_amount']),
      );
}

Map<String, dynamic> _asMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : const {};

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? double.tryParse(v.toString())?.toInt() ?? 0;
}

double _asDouble(dynamic v) => _asNullableDouble(v) ?? 0;

double? _asNullableDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

DateTime? _asDate(dynamic v) {
  final s = v?.toString() ?? '';
  return s.isEmpty ? null : DateTime.tryParse(s);
}

String? _blankToNull(dynamic v) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? null : s;
}
