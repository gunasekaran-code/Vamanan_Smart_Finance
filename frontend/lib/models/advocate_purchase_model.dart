import 'package:frontend/core/config/api_config.dart';

class PurchaseModel {
  final int id;
  final DateTime? date;
  final String customerName;
  final String customerEmail;
  final String phone;
  final String aadhar;
  final String pan;
  final String productTitle;
  final String category;
  final String weight;
  final String paymentMethod;
  final String paymentTid;
  final double totalPrice; // inclusive of GST, where available
  final double exGst;
  final double gst;

  /// `cashback_cycles.payment_screenshot`, e.g. `uploads/payments/x.jpg`.
  final String? paymentScreenshot;
  String status; // PENDING, ACTIVE, REJECTED, COMPLETED (mutable for optimistic UI updates)

  PurchaseModel({
    required this.id,
    required this.date,
    required this.customerName,
    required this.customerEmail,
    required this.phone,
    required this.aadhar,
    required this.pan,
    required this.productTitle,
    required this.category,
    required this.weight,
    required this.paymentMethod,
    required this.paymentTid,
    required this.totalPrice,
    required this.exGst,
    required this.gst,
    this.paymentScreenshot,
    required this.status,
  });

  /// Full URL of the uploaded receipt, or null when none was uploaded.
  /// Receipts live under the site root, so [ApiConfig.fileUrl] resolves them.
  String? get receiptImageUrl {
    final raw = paymentScreenshot;
    if (raw == null) return null;
    final url = ApiConfig.fileUrl(raw);
    return url.isEmpty ? null : url;
  }

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    String toStr(dynamic v, [String fallback = '']) =>
        (v == null || v.toString().isEmpty) ? fallback : v.toString();

    final total = toDouble(
      json['total_value'] ?? json['product_amount'] ?? json['cashback_eligible_amount'],
    );
    // GST breakdown isn't explicitly returned by the current backend query.
    // These default to 0 / total so the UI still renders sensibly; wire up
    // real columns here (e.g. json['gst_amount']) once they exist.
    final gstAmount = toDouble(json['gst_amount'] ?? json['gst']);
    final exGstAmount = toDouble(json['ex_gst_amount'] ?? json['product_amount']) > 0
        ? toDouble(json['ex_gst_amount'] ?? json['product_amount'])
        : (total - gstAmount);

    final rawStatus = toStr(json['cycle_status'] ?? json['status'], 'pending');

    return PurchaseModel(
      id: int.tryParse(toStr(json['cycle_id'] ?? json['id'], '0')) ?? 0,
      date: DateTime.tryParse(toStr(json['created_at'])),
      customerName: toStr(json['user_name'], 'Unknown Customer'),
      customerEmail: toStr(json['user_email']),
      phone: toStr(json['user_phone']),
      aadhar: toStr(json['aadhar_no'], 'N/A'),
      pan: toStr(json['pan_no'], 'N/A'),
      productTitle: toStr(json['product_name'], 'Asset Purchase'),
      category: toStr(json['asset_type'], 'gold').toUpperCase(),
      weight: toStr(json['weight'], '-'),
      paymentMethod: toStr(json['payment_method'], 'BANK TRANSFER'),
      paymentTid: toStr(json['transaction_id'], 'N/A'),
      totalPrice: total,
      exGst: exGstAmount < 0 ? 0 : exGstAmount,
      gst: gstAmount,
      paymentScreenshot: toStr(json['payment_screenshot']).trim().isEmpty
          ? null
          : toStr(json['payment_screenshot']).trim(),
      status: rawStatus.toUpperCase(),
    );
  }
}