import 'package:frontend/core/config/api_config.dart';

/// KYC is not a table of its own — it is a set of columns on `users`
/// (`kyc_status`, `kyc_document`, `aadhar_no`, `pan_no`, address and the bank
/// fields). So one request is one user, assembled from two endpoints:
///
///  * `admin/all_users.php` — the list: id, customer_id, name, email, role,
///    status, kyc_status, kyc_document, created_at, balance.
///  * `customer/kyc.php?user_id=N` — the detail: phone, address, aadhar_no,
///    pan_no, bank_name, account_no, ifsc_code, branch_name.
///
/// [IdentityRequest.fromListJson] builds the first, [withDetails] folds in the
/// second when a reviewer opens a request.
class IdentityRequest {
  final String id;
  final String customerId;
  final String name;
  final String email;
  final String role;

  /// The account's own state ('ACTIVE' / …), not the KYC state.
  final String accountStatus;

  /// Raw backend value: pending | verified | rejected.
  final String kycStatus;
  final String? kycDocument;
  final DateTime? submittedAt;

  // --- Detail fields, null until `customer/kyc.php` has been read. ---
  final String? phone;
  final String? address;
  final String? aadharNo;
  final String? panNo;
  final String? bankName;
  final String? accountNo;
  final String? ifscCode;
  final String? branchName;

  /// Whether the detail fetch has run, so the UI can tell "not loaded yet"
  /// apart from "loaded and genuinely empty".
  final bool detailsLoaded;

  const IdentityRequest({
    required this.id,
    this.customerId = '',
    required this.name,
    required this.email,
    this.role = '',
    this.accountStatus = '',
    this.kycStatus = 'pending',
    this.kycDocument,
    this.submittedAt,
    this.phone,
    this.address,
    this.aadharNo,
    this.panNo,
    this.bankName,
    this.accountNo,
    this.ifscCode,
    this.branchName,
    this.detailsLoaded = false,
  });

  bool get isPending => kycStatus == 'pending';
  bool get isVerified => kycStatus == 'verified';
  bool get isRejected => kycStatus == 'rejected';

  String get statusLabel {
    switch (kycStatus) {
      case 'verified':
        return 'VERIFIED';
      case 'rejected':
        return 'REJECTED';
      default:
        return 'PENDING';
    }
  }

  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  bool get hasDocument => (kycDocument ?? '').trim().isNotEmpty;

  /// `kyc_document` is stored relative to the document root
  /// ('uploads/kyc/kyc_65_1700000000.jpg'), so it joins to the site root
  /// rather than to the API base.
  String? get documentUrl =>
      hasDocument ? ApiConfig.fileUrl(kycDocument!.trim()) : null;

  /// A value the review sheet can print, or '—' when the field is blank.
  static String display(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? '—' : v;
  }

  /// One row of `admin/all_users.php`.
  factory IdentityRequest.fromListJson(Map<String, dynamic> json) {
    return IdentityRequest(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      name: (json['name']?.toString().trim().isNotEmpty ?? false)
          ? json['name'].toString().trim()
          : 'Unknown',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      accountStatus: json['status']?.toString() ?? '',
      kycStatus: _normaliseStatus(json['kyc_status']),
      kycDocument: json['kyc_document']?.toString(),
      submittedAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  /// Folds in a `customer/kyc.php?user_id=N` payload. That endpoint also
  /// returns `kyc_status` and `kyc_document`, which are fresher than the list
  /// row, so they are taken from here when present.
  IdentityRequest withDetails(Map<String, dynamic> json) {
    String? pick(String key) {
      final v = json[key]?.toString().trim();
      return (v == null || v.isEmpty || v == 'null') ? null : v;
    }

    return IdentityRequest(
      id: id,
      customerId: customerId,
      name: name,
      email: email,
      role: role,
      accountStatus: accountStatus,
      kycStatus: json['kyc_status'] == null
          ? kycStatus
          : _normaliseStatus(json['kyc_status']),
      kycDocument: pick('kyc_document') ?? kycDocument,
      submittedAt: submittedAt,
      phone: pick('phone'),
      address: pick('address'),
      aadharNo: pick('aadhar_no'),
      panNo: pick('pan_no'),
      bankName: pick('bank_name'),
      accountNo: pick('account_no'),
      ifscCode: pick('ifsc_code'),
      branchName: pick('branch_name'),
      detailsLoaded: true,
    );
  }

  IdentityRequest copyWithStatus(String status) => IdentityRequest(
        id: id,
        customerId: customerId,
        name: name,
        email: email,
        role: role,
        accountStatus: accountStatus,
        kycStatus: _normaliseStatus(status),
        kycDocument: kycDocument,
        submittedAt: submittedAt,
        phone: phone,
        address: address,
        aadharNo: aadharNo,
        panNo: panNo,
        bankName: bankName,
        accountNo: accountNo,
        ifscCode: ifscCode,
        branchName: branchName,
        detailsLoaded: detailsLoaded,
      );

  /// The column is a free-text varchar, so anything unrecognised — including
  /// the empty string a never-submitted user carries — reads as 'pending'.
  static String _normaliseStatus(dynamic raw) {
    final value = raw?.toString().trim().toLowerCase() ?? '';
    switch (value) {
      case 'verified':
      case 'approved':
        return 'verified';
      case 'rejected':
      case 'declined':
        return 'rejected';
      default:
        return 'pending';
    }
  }
}

/// Which slice of the register the screen is showing.
enum IdentityFilter {
  pending('pending', 'PENDING'),
  verified('verified', 'VERIFIED'),
  rejected('rejected', 'REJECTED'),
  all('all', 'ALL');

  const IdentityFilter(this.wire, this.label);
  final String wire;
  final String label;

  bool matches(IdentityRequest request) =>
      this == IdentityFilter.all || request.kycStatus == wire;
}

class IdentityVerificationException implements Exception {
  final String message;
  IdentityVerificationException(this.message);
  @override
  String toString() => message;
}
