/// A user row as returned by admin/all_users.php, filtered to those
/// with kyc_status == 'pending' for this screen.
class KycCustomer {
  final String id;
  final String name;
  final String email;
  final DateTime? submissionDate;
  final String status; // pending | verified | rejected (raw backend value)
  final String? kycDocument;
  final String? bankName;
  final String? accountNo;
  final String? ifscCode;
  final String? branchName;

  const KycCustomer({
    required this.id,
    required this.name,
    required this.email,
    this.submissionDate,
    required this.status,
    this.kycDocument,
    this.bankName,
    this.accountNo,
    this.ifscCode,
    this.branchName,
  });

  bool get isPending => status.toLowerCase() == 'pending';

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'verified':
        return 'VERIFIED';
      case 'rejected':
        return 'REJECTED';
      default:
        return 'PENDING REVIEW';
    }
  }

  String get credentialLabel =>
      (kycDocument != null && kycDocument!.isNotEmpty) ? 'DOCUMENT ON FILE' : 'NODE: NO DATA';

  factory KycCustomer.fromJson(Map<String, dynamic> json) {
    return KycCustomer(
      id: json['id']?.toString() ?? '',
      name: (json['name']?.toString().trim().isNotEmpty ?? false)
          ? json['name'].toString()
          : (json['user_name']?.toString() ?? 'Unknown'),
      email: json['email']?.toString() ?? json['user_email']?.toString() ?? '',
      submissionDate: DateTime.tryParse(
        json['kyc_submitted_at']?.toString() ??
            json['updated_at']?.toString() ??
            json['created_at']?.toString() ??
            '',
      ),
      status: (json['kyc_status']?.toString() ?? 'pending').toLowerCase(),
      kycDocument: json['kyc_document']?.toString(),
      bankName: json['bank_name']?.toString(),
      accountNo: json['account_no']?.toString(),
      ifscCode: json['ifsc_code']?.toString(),
      branchName: json['branch_name']?.toString(),
    );
  }
}

class KycActionResult {
  final bool success;
  final String message;

  KycActionResult({required this.success, required this.message});

  factory KycActionResult.fromJson(Map<String, dynamic> json) {
    return KycActionResult(
      success: json['status'] == 'success',
      message: json['message']?.toString() ?? '',
    );
  }
}

class KycRegistryException implements Exception {
  final String message;
  KycRegistryException(this.message);
  @override
  String toString() => message;
}