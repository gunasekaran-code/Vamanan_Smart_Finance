class CustomerKycModel {
  final int id; // internal users.id — used when calling approve/reject actions
  final String displayId; // users.customer_id (e.g. 'VEV099')
  final String name;
  final String email;
  final String phone;
  final String registrationDate;
  final String kycDocument; // raw path/filename from the backend, may be empty
  final String rawKycStatus; // 'pending' | 'verified' | 'rejected' (lowercase)
  String kycStatus; // UI label: KYC PENDING / KYC APPROVED / KYC REJECTED (mutable)

  CustomerKycModel({
    required this.id,
    required this.displayId,
    required this.name,
    required this.email,
    required this.phone,
    required this.registrationDate,
    required this.kycDocument,
    required this.rawKycStatus,
    required this.kycStatus,
  });

  factory CustomerKycModel.fromJson(Map<String, dynamic> json) {
    String toStr(dynamic v, [String fallback = '']) =>
        (v == null || v.toString().isEmpty) ? fallback : v.toString();

    final id = int.tryParse(toStr(json['id'], '0')) ?? 0;
    final raw = toStr(json['kyc_status'], 'pending').toLowerCase();

    String uiStatus;
    switch (raw) {
      case 'verified':
        uiStatus = 'KYC APPROVED';
        break;
      case 'rejected':
        uiStatus = 'KYC REJECTED';
        break;
      case 'pending':
        uiStatus = 'KYC PENDING';
        break;
      default:
        uiStatus = 'KYC ${raw.toUpperCase()}';
    }

    String formattedDate = toStr(json['created_at']);
    final parsed = DateTime.tryParse(formattedDate);
    if (parsed != null) {
      formattedDate = '${parsed.day}/${parsed.month}/${parsed.year}';
    }

    return CustomerKycModel(
      id: id,
      displayId: toStr(json['customer_id'], 'CUS$id'),
      name: toStr(json['name'], 'Unknown Customer'),
      email: toStr(json['email']),
      phone: toStr(json['phone']),
      registrationDate: formattedDate,
      kycDocument: toStr(json['kyc_document']),
      rawKycStatus: raw,
      kycStatus: uiStatus,
    );
  }
}