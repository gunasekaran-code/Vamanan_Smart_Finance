// models/advocate_archive_models.dart
//
// Maps one row of the `agreements` array returned by
// GET /api/advocate/stats.php  ->  data.agreements
//
// The PHP query is:
//   SELECT a.*, u.name as user_name, u.email as user_email,
//          u.aadhar_no, u.pan_no, p.name as product_name, p.price, p.weight
//   FROM agreements a
//   JOIN users u ON a.user_id = u.id
//   LEFT JOIN products p ON a.product_id = p.id
//
// `a.*` means every column of the `agreements` table comes through under
// its own name. I don't have your exact column list for things like the
// agreement type, branch, company name/address or the human-readable
// reference id, so fromJson() below tries several likely key names and
// falls back to a sensible default. If the UI shows blanks/placeholders,
// tell me the real column names and I'll tighten this up.

class AgreementArchiveItem {
  final int id;
  final String referenceId;
  final int? userId;
  final String customerName;
  final String customerEmail;
  final String? aadharNo;
  final String? panNo;
  final String agreementType;
  final String status;
  final String date;
  final String branch;
  final String companyName;
  final String companyAddress;
  final String? productName;
  final double? price;
  final double? weight;

  /// `agreements.signed_at` — stamped when the advocate approves.
  final DateTime? advocateSignedAt;

  /// `agreements.customer_signed_at` — stamped when the customer signs.
  final DateTime? customerSignedAt;

  AgreementArchiveItem({
    required this.id,
    required this.referenceId,
    this.userId,
    required this.customerName,
    required this.customerEmail,
    this.aadharNo,
    this.panNo,
    required this.agreementType,
    required this.status,
    required this.date,
    required this.branch,
    required this.companyName,
    required this.companyAddress,
    this.productName,
    this.price,
    this.weight,
    this.advocateSignedAt,
    this.customerSignedAt,
  });

  factory AgreementArchiveItem.fromJson(Map<String, dynamic> json) {
    final rawId = _asInt(json['id']) ?? 0;

    return AgreementArchiveItem(
      id: rawId,
      // `agreement_id` holds the real reference, e.g. AGR-1790168414-43.
      referenceId: (_nonEmpty(json['agreement_id']) ??
              json['reference_id'] ??
              json['agreement_ref'] ??
              json['ref_id'] ??
              json['agreement_number'] ??
              'AGR-$rawId')
          .toString(),
      userId: _asInt(json['user_id']),
      customerName:
          (json['user_name'] ?? json['customer_name'] ?? '—').toString(),
      customerEmail: (json['user_email'] ?? '').toString(),
      aadharNo: json['aadhar_no']?.toString(),
      panNo: json['pan_no']?.toString(),
      agreementType:
          (json['agreement_type'] ?? json['type'] ?? 'GOLD ACQUISITION DEED')
              .toString()
              .toUpperCase(),
      status: (json['status'] ?? '').toString(),
      date: _formatDate(_nonEmpty(json['agreement_date']) ??
          json['created_at'] ??
          json['date'] ??
          json['issued_at']),
      // No branch/company columns exist on `agreements`; the deed is issued
      // from the Krishnagiri head office.
      branch: (_nonEmpty(json['branch']) ??
              _nonEmpty(json['branch_name']) ??
              'KRISHNAGIRI BRANCH')
          .toUpperCase(),
      companyName: (_nonEmpty(json['company_name']) ?? 'VAMANAN ENTERPRISES')
          .toUpperCase(),
      companyAddress: (_nonEmpty(json['company_address']) ??
              'KRISHNAGIRI OPERATIONS CENTER, TAMIL NADU – 635 002.')
          .toUpperCase(),
      productName: json['product_name']?.toString(),
      price: _asDouble(json['price']),
      weight: _asDouble(json['weight']),
      advocateSignedAt: _asDateTime(json['signed_at']),
      customerSignedAt: _asDateTime(json['customer_signed_at']),
    );
  }

  /// Approved by the advocate: stamped, or moved to an approved status.
  bool get isAdvocateApproved =>
      advocateSignedAt != null ||
      const {'ratified', 'active', 'approved'}.contains(status.toLowerCase());

  bool get isCustomerSigned => customerSignedAt != null;

  /// "XXXX XXXX 1234 / XXXXXX234X", or "--- / ---" when neither is on file.
  String get maskedIdentity {
    final aadhar =
        (aadharNo == null || aadharNo!.length < 4) ? '---' : maskedAadhar;
    final pan = maskedPan.isEmpty ? '---' : maskedPan;
    return '$aadhar / $pan';
  }

  static String? _nonEmpty(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime? _asDateTime(dynamic v) {
    final s = _nonEmpty(v);
    if (s == null || s.startsWith('0000')) return null;
    return DateTime.tryParse(s);
  }

  /// Masked aadhar, e.g. "XXXX XXXX 1234"
  String get maskedAadhar {
    if (aadharNo == null || aadharNo!.length < 4) return '*** / ***';
    final last4 = aadharNo!.substring(aadharNo!.length - 4);
    return 'XXXX XXXX $last4';
  }

  /// Masked PAN, e.g. "XXXXX1234X"
  String get maskedPan {
    if (panNo == null || panNo!.length < 4) return '';
    final visibleStart = panNo!.length >= 9 ? panNo!.substring(0, 0) : '';
    final last4 = panNo!.substring(panNo!.length - 4);
    return '${'X' * (panNo!.length - 4)}$last4$visibleStart';
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final str = raw.toString();
    final parsed = DateTime.tryParse(str);
    if (parsed == null) return str;
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }
}
