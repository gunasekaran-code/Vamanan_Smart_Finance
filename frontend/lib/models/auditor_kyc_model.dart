class KycDetails {
  final String phone;
  final String address;
  final String aadharNo;
  final String panNo;
  final String kycStatus;
  final String? kycDocument;
  final String bankName;
  final String accountNo;
  final String ifscCode;
  final String branchName;

  const KycDetails({
    required this.phone,
    required this.address,
    required this.aadharNo,
    required this.panNo,
    required this.kycStatus,
    required this.kycDocument,
    required this.bankName,
    required this.accountNo,
    required this.ifscCode,
    required this.branchName,
  });

  factory KycDetails.empty() => const KycDetails(
        phone: '',
        address: '',
        aadharNo: '',
        panNo: '',
        kycStatus: 'not_submitted',
        kycDocument: null,
        bankName: '',
        accountNo: '',
        ifscCode: '',
        branchName: '',
      );

  factory KycDetails.fromJson(Map<String, dynamic> json) {
    return KycDetails(
      phone: (json['phone'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      aadharNo: (json['aadhar_no'] ?? '').toString(),
      panNo: (json['pan_no'] ?? '').toString(),
      kycStatus: (json['kyc_status'] ?? 'not_submitted').toString(),
      // The POST response's SELECT doesn't include kyc_document, so callers
      // that just submitted should carry the previous value forward with
      // copyWith rather than expect it back from that response.
      kycDocument: json['kyc_document']?.toString(),
      bankName: (json['bank_name'] ?? '').toString(),
      accountNo: (json['account_no'] ?? '').toString(),
      ifscCode: (json['ifsc_code'] ?? '').toString(),
      branchName: (json['branch_name'] ?? '').toString(),
    );
  }

  KycDetails copyWith({
    String? phone,
    String? address,
    String? aadharNo,
    String? panNo,
    String? kycStatus,
    String? kycDocument,
    String? bankName,
    String? accountNo,
    String? ifscCode,
    String? branchName,
  }) {
    return KycDetails(
      phone: phone ?? this.phone,
      address: address ?? this.address,
      aadharNo: aadharNo ?? this.aadharNo,
      panNo: panNo ?? this.panNo,
      kycStatus: kycStatus ?? this.kycStatus,
      kycDocument: kycDocument ?? this.kycDocument,
      bankName: bankName ?? this.bankName,
      accountNo: accountNo ?? this.accountNo,
      ifscCode: ifscCode ?? this.ifscCode,
      branchName: branchName ?? this.branchName,
    );
  }

  bool get hasDocument => (kycDocument ?? '').isNotEmpty;
  bool get isApproved => kycStatus.toLowerCase() == 'approved';
  bool get isPending => kycStatus.toLowerCase() == 'pending';
  bool get isRejected => kycStatus.toLowerCase() == 'rejected';
  bool get isSubmitted => kycStatus.toLowerCase() != 'not_submitted';
}