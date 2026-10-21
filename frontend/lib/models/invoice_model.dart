import 'package:intl/intl.dart';

double _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

String _inr(double v) =>
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)
        .format(v);

class InvoiceModel {
  final int id;
  final String invoiceId;
  final DateTime issuedAt;
  final String customerName;
  final String customerCode;
  final String customerPhone;
  final String customerEmail;
  final String productName;
  final String assetType;
  final double weight;
  final double taxableAmount;
  final double gstRate;
  final double cgstAmount;
  final double sgstAmount;
  final double gstAmount;
  final double totalAmount;
  final String paymentMethod;
  final String transactionId;
  final String status;

  const InvoiceModel({
    required this.id,
    required this.invoiceId,
    required this.issuedAt,
    required this.customerName,
    required this.customerCode,
    required this.customerPhone,
    required this.customerEmail,
    required this.productName,
    required this.assetType,
    required this.weight,
    required this.taxableAmount,
    required this.gstRate,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.gstAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.transactionId,
    required this.status,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> j) {
    final taxable = _num(j['taxable']);
    final cgst = _num(j['cgst']);
    final sgst = _num(j['sgst']);
    final gst = _num(j['gst_amount']);
    // admin/invoices.php returns the frozen `total_amount`. Older rows written
    // before that column was populated come back as 0 — rebuild the grand total
    // from the taxable base + GST so the summary card never under-reports.
    var total = _num(j['total_amount']);
    if (total <= 0) {
      total = taxable + (gst > 0 ? gst : cgst + sgst);
    }

    return InvoiceModel(
      id: (j['id'] as num).toInt(),
      invoiceId: j['invoice_no']?.toString() ?? '-',
      issuedAt:
          DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
      customerName: j['customer_name']?.toString() ?? 'Unknown',
      customerCode: j['customer_id']?.toString() ?? '',
      customerPhone: j['phone']?.toString() ?? '',
      customerEmail: j['email']?.toString() ?? '',
      productName: j['product_name']?.toString() ?? '',
      assetType: j['asset_type']?.toString() ?? '',
      weight: _num(j['weight']),
      taxableAmount: taxable,
      gstRate: _num(j['gst_rate']),
      cgstAmount: cgst,
      sgstAmount: sgst,
      gstAmount: gst,
      totalAmount: total,
      paymentMethod: j['payment_method']?.toString().trim().isNotEmpty == true
          ? j['payment_method'].toString()
          : 'Bank Transfer',
      transactionId: j['transaction_id']?.toString() ?? '',
      status: (j['status']?.toString() ?? 'issued').toUpperCase(),
    );
  }

  String get dateDay => DateFormat('dd').format(issuedAt);
  String get dateMonthYear =>
      DateFormat('MMM yyyy').format(issuedAt).toUpperCase();
  String get taxableValue => _inr(taxableAmount);
  String get gstRateLabel =>
      '${gstRate == gstRate.truncateToDouble() ? gstRate.toStringAsFixed(0) : gstRate.toStringAsFixed(1)}%';
  String get cgst => _inr(cgstAmount);
  String get sgst => _inr(sgstAmount);
  String get total => _inr(totalAmount);

  // --- Tax-invoice document fields -----------------------------------------
  // The printed invoice mirrors the frozen `items_json` snapshot the backend
  // writes in models/Invoice.php: one line item whose qty is the purchased
  // weight (falling back to 1) and whose rate is the taxable base.

  String get dateFull => DateFormat('dd MMM yyyy').format(issuedAt);

  double get qty => weight > 1 ? weight : 1;
  String get qtyLabel => qty == qty.truncateToDouble()
      ? qty.toStringAsFixed(0)
      : qty.toStringAsFixed(3);

  String get rate => _inr(taxableAmount);

  /// GST total from the server, or the CGST + SGST split when it is empty.
  double get gstTotal => gstAmount > 0 ? gstAmount : cgstAmount + sgstAmount;
  String get gstTotalDisplay => _inr(gstTotal);

  double get cgstRate => gstRate / 2;
  double get sgstRate => gstRate / 2;
  String get cgstRateLabel => _pct(cgstRate);
  String get sgstRateLabel => _pct(sgstRate);

  String get paymentLabel =>
      paymentMethod.trim().isEmpty ? 'Bank Transfer' : paymentMethod.trim();
  String get transactionLabel =>
      transactionId.trim().isEmpty ? '-' : transactionId.trim();
  String get phoneLabel =>
      customerPhone.trim().isEmpty ? '-' : customerPhone.trim();

  String get descriptionLabel => productName.trim().isNotEmpty
      ? productName.trim()
      : (assetType.trim().isNotEmpty ? assetType.trim() : 'Order #$id');
}

String _pct(double v) {
  var text = v.toStringAsFixed(2);
  if (text.contains('.')) {
    text =
        text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return '$text%';
}

class InvoiceSummary {
  final int count;
  final double taxable;
  final double cgst;
  final double sgst;
  final double grandTotal;

  const InvoiceSummary({
    required this.count,
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.grandTotal,
  });

  factory InvoiceSummary.fromJson(Map<String, dynamic> j) => InvoiceSummary(
        count: (j['count'] as num?)?.toInt() ?? 0,
        taxable: _num(j['total_taxable'] ?? j['taxable_amount']),
        cgst: _num(j['total_cgst'] ?? j['cgst_amount']),
        sgst: _num(j['total_sgst'] ?? j['sgst_amount']),
        grandTotal: _num(j['total_value'] ?? j['total_amount']),
      );

  factory InvoiceSummary.fromInvoices(List<InvoiceModel> list) =>
      InvoiceSummary(
        count: list.length,
        taxable: list.fold(0.0, (s, i) => s + i.taxableAmount),
        cgst: list.fold(0.0, (s, i) => s + i.cgstAmount),
        sgst: list.fold(0.0, (s, i) => s + i.sgstAmount),
        grandTotal: list.fold(0.0, (s, i) => s + i.totalAmount),
      );

  String get taxableDisplay => _inr(taxable);
  String get cgstDisplay => _inr(cgst);
  String get sgstDisplay => _inr(sgst);
  String get grandTotalDisplay => _inr(grandTotal);
}
