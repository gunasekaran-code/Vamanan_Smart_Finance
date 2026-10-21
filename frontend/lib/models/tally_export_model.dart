/// One row from the `cashback_applications` table (also what
/// tally_export.php turns into a Tally voucher).
class CashbackApplication {
  final int id;
  final String customerName;
  final String? customerEmail;
  final String? purchasedProduct;
  final double purchaseAmount;
  final double? gstAmount;
  final double? totalAmount;
  final DateTime? applicationDate;
  final DateTime? purchaseDate;
  final String status; // pending | approved | rejected
  final String? agentName;

  CashbackApplication({
    required this.id,
    required this.customerName,
    this.customerEmail,
    this.purchasedProduct,
    required this.purchaseAmount,
    this.gstAmount,
    this.totalAmount,
    this.applicationDate,
    this.purchaseDate,
    required this.status,
    this.agentName,
  });

  /// Same fallback tally_export.php uses: invoice = purchase + gst,
  /// or total_amount if the backend already computed it.
  double get invoiceAmount {
    if (totalAmount != null && totalAmount! > 0) return totalAmount!;
    return purchaseAmount + (gstAmount ?? 0);
  }

  String get voucherId => 'CBA-$id';

  factory CashbackApplication.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic v) =>
        v == null ? null : double.tryParse('$v');
    DateTime? asDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return CashbackApplication(
      id: int.tryParse('${json['id']}') ?? 0,
      customerName: (json['customer_name']?.toString().trim().isNotEmpty ?? false)
          ? json['customer_name'].toString()
          : 'Customer #${json['user_id'] ?? ''}',
      customerEmail: json['customer_email']?.toString(),
      purchasedProduct: json['purchased_product']?.toString(),
      purchaseAmount: asDouble(json['purchase_amount']) ?? 0,
      gstAmount: asDouble(json['gst_amount']),
      totalAmount: asDouble(json['total_amount']),
      applicationDate: asDate(json['application_date']),
      purchaseDate: asDate(json['purchase_date']),
      status: (json['status']?.toString() ?? 'pending').toLowerCase(),
      agentName: json['agent_name']?.toString(),
    );
  }
}

/// Fields the "TALLY SETTINGS" form controls, matching the GET params
/// tally_export.php reads.
class TallyExportSettings {
  final String company;
  final String salesLedger;
  final String cgstLedger;
  final String sgstLedger;
  final String voucherType;
  final String gateway;
  final String? statusFilter; // pending | approved | rejected | null (all)
  final int? id; // export a single application

  const TallyExportSettings({
    this.company = '',
    this.salesLedger = 'Sales Account',
    this.cgstLedger = 'Output CGST',
    this.sgstLedger = 'Output SGST',
    this.voucherType = 'Sales',
    this.gateway = 'http://localhost:9000',
    this.statusFilter,
    this.id,
  });

  Map<String, String> toQueryParams(String mode) {
    final map = <String, String>{
      'mode': mode,
      'sales_ledger': salesLedger,
      'cgst_ledger': cgstLedger,
      'sgst_ledger': sgstLedger,
      'voucher_type': voucherType,
    };
    if (company.trim().isNotEmpty) map['company'] = company;
    if (mode == 'push') map['gateway'] = gateway;
    if (statusFilter != null && statusFilter!.isNotEmpty) {
      map['status'] = statusFilter!;
    }
    if (id != null) map['id'] = '$id';
    return map;
  }
}

/// Parsed JSON result from mode=push (the only mode that returns JSON).
class TallyPushResult {
  final String status; // success | offline | error
  final String message;
  final int? created;
  final int? errors;
  final double totalAmount;
  final int? records;

  TallyPushResult({
    required this.status,
    required this.message,
    this.created,
    this.errors,
    required this.totalAmount,
    this.records,
  });

  bool get isSuccess => status == 'success';
  bool get isOffline => status == 'offline';

  factory TallyPushResult.fromJson(Map<String, dynamic> json) {
    return TallyPushResult(
      status: json['status']?.toString() ?? 'error',
      message: json['message']?.toString() ?? '',
      created: int.tryParse('${json['created']}'),
      errors: int.tryParse('${json['errors']}'),
      totalAmount: double.tryParse('${json['total_amount'] ?? 0}') ?? 0,
      records: int.tryParse('${json['records']}'),
    );
  }
}

class TallyExportException implements Exception {
  final String message;
  TallyExportException(this.message);
  @override
  String toString() => message;
}