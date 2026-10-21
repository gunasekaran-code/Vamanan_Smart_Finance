// auditor_cashback_application_model.dart — models for /customer/cashback_application.php

double _d(dynamic v) =>
    v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);

int _i(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

String _s(dynamic v) => v?.toString() ?? '';

DateTime? _dt(dynamic v) {
  final s = v?.toString();
  if (s == null || s.isEmpty || s == '0000-00-00') return null;
  return DateTime.tryParse(s);
}

/// `data.user` from GET ?user_id= — live values straight from the `users` table.
class CashbackApplicant {
  final int id;
  final String customerId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String aadharNo;
  final String panNo;
  final String referralCode;
  final String bankName;
  final String accountNo;
  final String ifscCode;
  final String branchName;

  const CashbackApplicant({
    required this.id,
    required this.customerId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.aadharNo,
    required this.panNo,
    required this.referralCode,
    required this.bankName,
    required this.accountNo,
    required this.ifscCode,
    required this.branchName,
  });

  factory CashbackApplicant.fromJson(Map<String, dynamic> j) => CashbackApplicant(
        id: _i(j['id']),
        customerId: _s(j['customer_id']),
        name: _s(j['name']),
        email: _s(j['email']),
        phone: _s(j['phone']),
        address: _s(j['address']),
        aadharNo: _s(j['aadhar_no']),
        panNo: _s(j['pan_no']),
        referralCode: _s(j['referral_code']),
        bankName: _s(j['bank_name']),
        accountNo: _s(j['account_no']),
        ifscCode: _s(j['ifsc_code']),
        branchName: _s(j['branch_name']),
      );
}

/// A row from `cashback_applications` — `data.application` on GET (nullable),
/// or the record implied by a successful POST.
class CashbackApplication {
  final int? id;
  final int userId;
  final String customerName;
  final String address;
  final String phone;
  final String aadharNo;
  final String panNo;
  final String customerCode;
  final String customerEmail;
  final String referralId;
  final double purchaseAmount;
  final String purchasedProduct;
  final String productDetails;
  final DateTime? purchaseDate;
  final String bankAccountName;
  final String accountNo;
  final String ifscCode;
  final String bankName;
  final String bankBranch;
  final String agentName;
  final String agentId;
  final String place;
  final DateTime? applicationDate;
  final String status; // pending | approved | rejected
  final DateTime? createdAt;

  const CashbackApplication({
    this.id,
    required this.userId,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.aadharNo,
    required this.panNo,
    required this.customerCode,
    required this.customerEmail,
    required this.referralId,
    required this.purchaseAmount,
    required this.purchasedProduct,
    required this.productDetails,
    this.purchaseDate,
    required this.bankAccountName,
    required this.accountNo,
    required this.ifscCode,
    required this.bankName,
    required this.bankBranch,
    required this.agentName,
    required this.agentId,
    required this.place,
    this.applicationDate,
    required this.status,
    this.createdAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory CashbackApplication.fromJson(Map<String, dynamic> j) => CashbackApplication(
        id: j['id'] == null ? null : _i(j['id']),
        userId: _i(j['user_id']),
        customerName: _s(j['customer_name']),
        address: _s(j['address']),
        phone: _s(j['phone']),
        aadharNo: _s(j['aadhar_no']),
        panNo: _s(j['pan_no']),
        customerCode: _s(j['customer_code']),
        customerEmail: _s(j['customer_email']),
        referralId: _s(j['referral_id']),
        purchaseAmount: _d(j['purchase_amount']),
        purchasedProduct: _s(j['purchased_product']),
        productDetails: _s(j['product_details']),
        purchaseDate: _dt(j['purchase_date']),
        bankAccountName: _s(j['bank_account_name']),
        accountNo: _s(j['account_no']),
        ifscCode: _s(j['ifsc_code']),
        bankName: _s(j['bank_name']),
        bankBranch: _s(j['bank_branch']),
        agentName: _s(j['agent_name']),
        agentId: _s(j['agent_id']),
        place: _s(j['place']).isEmpty ? 'Krishnagiri' : _s(j['place']),
        applicationDate: _dt(j['application_date']),
        status: _s(j['status']).isEmpty ? 'pending' : _s(j['status']),
        createdAt: _dt(j['created_at']),
      );
}

/// Full GET response payload: { user, application }
class CashbackApplicationPrefill {
  final CashbackApplicant user;
  final CashbackApplication? application;

  const CashbackApplicationPrefill({required this.user, this.application});

  factory CashbackApplicationPrefill.fromJson(Map<String, dynamic> j) =>
      CashbackApplicationPrefill(
        user: CashbackApplicant.fromJson((j['user'] as Map<String, dynamic>?) ?? const {}),
        application: j['application'] == null
            ? null
            : CashbackApplication.fromJson(j['application'] as Map<String, dynamic>),
      );
}

/// Body for POST submit. `userId`, `customerName`, `phone`, `purchaseAmount`,
/// `accountNo`, `ifscCode` are required by the endpoint — everything else is optional.
class CashbackApplicationRequest {
  final int userId;
  final String customerName;
  final String phone;
  final double purchaseAmount;
  final String accountNo;
  final String ifscCode;

  final String? address;
  final String? aadharNo;
  final String? panNo;
  final String? customerCode;
  final String? customerEmail;
  final String? referralId;
  final String? purchasedProduct;
  final String? productDetails;
  final String? purchaseDate; // 'YYYY-MM-DD'
  final String? bankAccountName;
  final String? bankName;
  final String? bankBranch;
  final String? agentName;
  final String? agentId;
  final String? place;
  final String? applicationDate; // 'YYYY-MM-DD'

  const CashbackApplicationRequest({
    required this.userId,
    required this.customerName,
    required this.phone,
    required this.purchaseAmount,
    required this.accountNo,
    required this.ifscCode,
    this.address,
    this.aadharNo,
    this.panNo,
    this.customerCode,
    this.customerEmail,
    this.referralId,
    this.purchasedProduct,
    this.productDetails,
    this.purchaseDate,
    this.bankAccountName,
    this.bankName,
    this.bankBranch,
    this.agentName,
    this.agentId,
    this.place,
    this.applicationDate,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'customer_name': customerName,
        'phone': phone,
        'purchase_amount': purchaseAmount,
        'account_no': accountNo,
        'ifsc_code': ifscCode,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (aadharNo != null && aadharNo!.isNotEmpty) 'aadhar_no': aadharNo,
        if (panNo != null && panNo!.isNotEmpty) 'pan_no': panNo,
        if (customerCode != null && customerCode!.isNotEmpty) 'customer_code': customerCode,
        if (customerEmail != null && customerEmail!.isNotEmpty) 'customer_email': customerEmail,
        if (referralId != null && referralId!.isNotEmpty) 'referral_id': referralId,
        if (purchasedProduct != null && purchasedProduct!.isNotEmpty)
          'purchased_product': purchasedProduct,
        if (productDetails != null && productDetails!.isNotEmpty)
          'product_details': productDetails,
        if (purchaseDate != null && purchaseDate!.isNotEmpty) 'purchase_date': purchaseDate,
        if (bankAccountName != null && bankAccountName!.isNotEmpty)
          'bank_account_name': bankAccountName,
        if (bankName != null && bankName!.isNotEmpty) 'bank_name': bankName,
        if (bankBranch != null && bankBranch!.isNotEmpty) 'bank_branch': bankBranch,
        if (agentName != null && agentName!.isNotEmpty) 'agent_name': agentName,
        if (agentId != null && agentId!.isNotEmpty) 'agent_id': agentId,
        if (place != null && place!.isNotEmpty) 'place': place,
        if (applicationDate != null && applicationDate!.isNotEmpty)
          'application_date': applicationDate,
      };
}

/// Response after POST.
class CashbackApplicationSubmitResult {
  final bool success;
  final String message;
  final int? applicationId;

  const CashbackApplicationSubmitResult({
    required this.success,
    required this.message,
    this.applicationId,
  });

  factory CashbackApplicationSubmitResult.fromJson(Map<String, dynamic> j) =>
      CashbackApplicationSubmitResult(
        success: j['status'] == 'success',
        message: _s(j['message']),
        applicationId: j['application_id'] == null ? null : _i(j['application_id']),
      );
}