/// Payload of `GET admin/reports.php?type=transaction`:
/// `{ summary: {count, total, efficiency, registry_count}, history, chart }`.
class TransactionReport {
  final int count; // every transaction in the ledger
  final double total; // sum of every transaction amount
  final String efficiency; // e.g. "98.9%" — computed server-side
  final int registryCount; // rows in [history]
  final List<TransactionReportRow> history;
  final List<TransactionChartPoint> chart; // last 15 active days

  const TransactionReport({
    required this.count,
    required this.total,
    required this.efficiency,
    required this.registryCount,
    required this.history,
    required this.chart,
  });

  factory TransactionReport.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> rows(String key) => (json[key] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final summary = json['summary'] is Map ? Map<String, dynamic>.from(json['summary']) : const <String, dynamic>{};

    return TransactionReport(
      count: _asInt(summary['count']),
      total: _asDouble(summary['total']),
      efficiency: summary['efficiency']?.toString() ?? '0%',
      registryCount: _asInt(summary['registry_count']),
      history: rows('history').map(TransactionReportRow.fromJson).toList(),
      chart: rows('chart').map(TransactionChartPoint.fromJson).toList(),
    );
  }

  factory TransactionReport.empty() => TransactionReport.fromJson(const {});
}

/// A `transactions` row joined to the wallet owner.
class TransactionReportRow {
  final int id;
  final String userName;
  final String userEmail;
  final String type; // credit | debit
  final String category; // cashback, referral, purchase_request, withdrawal, ...
  final double amount;
  final double? grossAmount;
  final double? tdsAmount;
  final double? chargesAmount;
  final String description;
  final String status; // pending | completed | failed
  final DateTime? createdAt;

  const TransactionReportRow({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.category,
    required this.amount,
    required this.grossAmount,
    required this.tdsAmount,
    required this.chargesAmount,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory TransactionReportRow.fromJson(Map<String, dynamic> json) => TransactionReportRow(
        id: _asInt(json['id']),
        userName: json['user_name']?.toString() ?? '',
        userEmail: json['user_email']?.toString() ?? '',
        type: (json['type']?.toString() ?? '').toLowerCase(),
        category: (json['category']?.toString() ?? '').toLowerCase(),
        amount: _asDouble(json['amount']),
        grossAmount: _asNullableDouble(json['gross_amount']),
        tdsAmount: _asNullableDouble(json['tds_amount']),
        chargesAmount: _asNullableDouble(json['charges_amount']),
        description: json['description']?.toString() ?? '',
        status: (json['status']?.toString() ?? 'completed').toLowerCase(),
        createdAt: _asDate(json['created_at']),
      );
}

class TransactionChartPoint {
  final DateTime? date;
  final double totalAmount;

  const TransactionChartPoint({required this.date, required this.totalAmount});

  factory TransactionChartPoint.fromJson(Map<String, dynamic> json) => TransactionChartPoint(
        date: _asDate(json['date']),
        totalAmount: _asDouble(json['total_amount']),
      );
}

int _asInt(dynamic v) {
  if (v == null) return 0;
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
