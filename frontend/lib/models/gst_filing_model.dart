double _asDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final s = value.toString().trim();
  return s.isEmpty ? fallback : s;
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatShortDate(DateTime? dt) {
  if (dt == null) return '—';
  final year2 = (dt.year % 100).toString().padLeft(2, '0');
  return '${dt.day.toString().padLeft(2, '0')} ${_kMonths[dt.month - 1]} $year2';
}

String _groupIndian(String digits) {
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}

/// Formats a value as an Indian-grouped rupee amount, e.g. ₹1,26,000.93
String formatInr(double value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final grouped = _groupIndian(parts[0]);
  return '${negative ? '-' : ''}₹$grouped.${parts[1]}';
}

/// One outward-supply order line (B2C invoice-wise breakdown for GSTR-1).
class GstOrder {
  final int id;
  final String invoiceNo;
  final DateTime? createdAt;
  final String status;
  final String customerName;
  final String? customerCode;
  final String productName;
  final double taxable;
  final double rate; // GST % for this order
  final double cgst;
  final double sgst;
  final double gst;
  final double total;

  const GstOrder({
    required this.id,
    required this.invoiceNo,
    required this.createdAt,
    required this.status,
    required this.customerName,
    required this.customerCode,
    required this.productName,
    required this.taxable,
    required this.rate,
    required this.cgst,
    required this.sgst,
    required this.gst,
    required this.total,
  });

  factory GstOrder.fromJson(Map<String, dynamic> json) {
    return GstOrder(
      id: _asInt(json['id']),
      invoiceNo: _asString(json['invoice_no'], fallback: 'INV-${json['id']}'),
      createdAt: _asDate(json['created_at']),
      status: _asString(json['status']),
      customerName: _asString(json['customer_name'], fallback: 'UNKNOWN'),
      customerCode: (json['customer_code'] == null ||
              json['customer_code'].toString().trim().isEmpty)
          ? null
          : json['customer_code'].toString().trim(),
      productName: _asString(json['product_name'], fallback: 'Product'),
      taxable: _asDouble(json['taxable']),
      rate: _asDouble(json['rate']),
      cgst: _asDouble(json['cgst']),
      sgst: _asDouble(json['sgst']),
      gst: _asDouble(json['gst']),
      total: _asDouble(json['total']),
    );
  }

  String get dateDisplay => _formatShortDate(createdAt);
  String get taxableDisplay => formatInr(taxable);
  String get rateDisplay => '${rate % 1 == 0 ? rate.toInt() : rate}%';
  String get cgstDisplay => formatInr(cgst);
  String get sgstDisplay => formatInr(sgst);
  String get totalDisplay => formatInr(total);
}

/// One GST-rate slab bucket (used for the GSTR-1 rate-wise summary table).
class GstRateSlab {
  final double rate;
  final double taxable;
  final double cgst;
  final double sgst;
  final double gst;
  final int orders;

  const GstRateSlab({
    required this.rate,
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.gst,
    required this.orders,
  });

  factory GstRateSlab.fromJson(Map<String, dynamic> json) {
    return GstRateSlab(
      rate: _asDouble(json['rate']),
      taxable: _asDouble(json['taxable']),
      cgst: _asDouble(json['cgst']),
      sgst: _asDouble(json['sgst']),
      gst: _asDouble(json['gst']),
      orders: _asInt(json['orders']),
    );
  }

  String get rateLabel {
    final half = rate / 2;
    final rateStr = rate % 1 == 0 ? rate.toInt().toString() : rate.toStringAsFixed(1);
    final halfStr = half % 1 == 0 ? half.toInt().toString() : half.toStringAsFixed(1);
    return '$rateStr% (CGST $halfStr% + SGST $halfStr%)';
  }

  String get taxableDisplay => formatInr(taxable);
  String get cgstDisplay => formatInr(cgst);
  String get sgstDisplay => formatInr(sgst);
  String get totalGstDisplay => formatInr(gst);
  String get ordersDisplay => '$orders';
}

/// Top-line totals across the whole (optionally month-filtered) report.
class GstSummary {
  final int orders;
  final double taxable;
  final double cgst;
  final double sgst;
  final double totalGst;
  final double totalInvoice;

  const GstSummary({
    required this.orders,
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.totalGst,
    required this.totalInvoice,
  });

  factory GstSummary.fromJson(Map<String, dynamic> json) {
    return GstSummary(
      orders: _asInt(json['orders']),
      taxable: _asDouble(json['taxable']),
      cgst: _asDouble(json['cgst']),
      sgst: _asDouble(json['sgst']),
      totalGst: _asDouble(json['total_gst']),
      totalInvoice: _asDouble(json['total_invoice']),
    );
  }

  static const empty = GstSummary(
    orders: 0,
    taxable: 0,
    cgst: 0,
    sgst: 0,
    totalGst: 0,
    totalInvoice: 0,
  );

  String get taxableDisplay => formatInr(taxable);
  String get cgstDisplay => formatInr(cgst);
  String get sgstDisplay => formatInr(sgst);
  String get totalGstDisplay => formatInr(totalGst);
  String get totalInvoiceDisplay => formatInr(totalInvoice);
  String get ordersDisplay => '$orders ORDERS';
}

/// The full report returned by admin/gst_filing.php.
class GstFilingReport {
  final String period;
  final GstSummary summary;
  final List<GstOrder> orders;
  final List<GstRateSlab> rateSlabs;
  final List<String> months;

  const GstFilingReport({
    required this.period,
    required this.summary,
    required this.orders,
    required this.rateSlabs,
    required this.months,
  });

  factory GstFilingReport.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};

    final gstr1 = (data['gstr1'] as Map?)?.cast<String, dynamic>() ?? const {};
    final ordersJson = (gstr1['b2c_outward_supplies'] as List?) ??
        (data['orders'] as List?) ??
        const [];
    final slabsJson = (gstr1['rate_slabs'] as List?) ??
        (data['slabs'] as List?) ??
        const [];
    final summaryJson = (data['summary'] as Map?)?.cast<String, dynamic>();
    final monthsJson = (data['months'] as List?) ?? const [];

    return GstFilingReport(
      period: _asString(data['period'], fallback: 'All Time'),
      summary: summaryJson != null
          ? GstSummary.fromJson(summaryJson)
          : GstSummary.empty,
      orders: ordersJson
          .map((e) => GstOrder.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      rateSlabs: slabsJson
          .map((e) => GstRateSlab.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      months: monthsJson.map((e) => e.toString()).toList(),
    );
  }

  static const empty = GstFilingReport(
    period: 'All Time',
    summary: GstSummary.empty,
    orders: [],
    rateSlabs: [],
    months: [],
  );

  /// Total invoice value inclusive of GST — used for the "INVOICE TOTAL" stat card.
  double get invoiceTotal => summary.totalInvoice;
  String get invoiceTotalDisplay => formatInr(invoiceTotal);
}