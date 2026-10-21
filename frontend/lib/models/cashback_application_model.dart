/// Mirrors the `cashback_applications` table created in
/// api/admin/cashback_applications.php.
class CashbackApplication {
  final int id;
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
  final CashbackStatus status;
  final DateTime? createdAt;

  const CashbackApplication({
    required this.id,
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
    required this.purchaseDate,
    required this.bankAccountName,
    required this.accountNo,
    required this.ifscCode,
    required this.bankName,
    required this.bankBranch,
    required this.agentName,
    required this.agentId,
    required this.place,
    required this.applicationDate,
    required this.status,
    required this.createdAt,
  });

  factory CashbackApplication.fromJson(Map<String, dynamic> json) {
    return CashbackApplication(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      customerName: _asString(json['customer_name']),
      address: _asString(json['address']),
      phone: _asString(json['phone']),
      aadharNo: _asString(json['aadhar_no']),
      panNo: _asString(json['pan_no']),
      customerCode: _asString(json['customer_code']),
      customerEmail: _asString(json['customer_email']),
      referralId: _asString(json['referral_id']),
      purchaseAmount: _asDouble(json['purchase_amount']),
      purchasedProduct: _asString(json['purchased_product']),
      productDetails: _asString(json['product_details']),
      purchaseDate: _asDate(json['purchase_date']),
      bankAccountName: _asString(json['bank_account_name']),
      accountNo: _asString(json['account_no']),
      ifscCode: _asString(json['ifsc_code']),
      bankName: _asString(json['bank_name']),
      bankBranch: _asString(json['bank_branch']),
      agentName: _asString(json['agent_name']),
      agentId: _asString(json['agent_id']),
      place: _asString(json['place']).isEmpty ? 'Krishnagiri' : _asString(json['place']),
      applicationDate: _asDate(json['application_date']),
      status: CashbackStatusX.fromApi(json['status']?.toString()),
      createdAt: _asDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_name': customerName,
      'address': address,
      'phone': phone,
      'aadhar_no': aadharNo,
      'pan_no': panNo,
      'customer_code': customerCode,
      'customer_email': customerEmail,
      'referral_id': referralId,
      'purchase_amount': purchaseAmount,
      'purchased_product': purchasedProduct,
      'product_details': productDetails,
      'purchase_date': purchaseDate?.toIso8601String().split('T').first,
      'bank_account_name': bankAccountName,
      'account_no': accountNo,
      'ifsc_code': ifscCode,
      'bank_name': bankName,
      'bank_branch': bankBranch,
      'agent_name': agentName,
      'agent_id': agentId,
      'place': place,
      'application_date': applicationDate?.toIso8601String().split('T').first,
      'status': status.apiValue,
    };
  }

  /// ₹8,40,000 style Indian grouping, no external intl dependency required.
  String get formattedPurchaseValue => '₹${_indianGroup(purchaseAmount)}';

  String get formattedPurchaseDate =>
      purchaseDate == null ? '—' : purchaseDate!.toIso8601String().split('T').first;

  static String _indianGroup(double amount) {
    final isNegative = amount < 0;
    final whole = amount.abs().truncate().toString();
    final decimals = (amount.abs() - amount.abs().truncate());
    String result;
    if (whole.length <= 3) {
      result = whole;
    } else {
      final last3 = whole.substring(whole.length - 3);
      var remaining = whole.substring(0, whole.length - 3);
      final parts = <String>[];
      while (remaining.length > 2) {
        parts.insert(0, remaining.substring(remaining.length - 2));
        remaining = remaining.substring(0, remaining.length - 2);
      }
      if (remaining.isNotEmpty) parts.insert(0, remaining);
      result = '${parts.join(',')},$last3';
    }
    if (decimals > 0) {
      result += '.${(decimals * 100).round().toString().padLeft(2, '0')}';
    }
    return isNegative ? '-$result' : result;
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }

  static String _asString(dynamic v) => v == null ? '' : v.toString();

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty || s == '0000-00-00') return null;
    return DateTime.tryParse(s);
  }
}

enum CashbackStatus { pending, approved, rejected }

extension CashbackStatusX on CashbackStatus {
  String get apiValue {
    switch (this) {
      case CashbackStatus.pending:
        return 'pending';
      case CashbackStatus.approved:
        return 'approved';
      case CashbackStatus.rejected:
        return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case CashbackStatus.pending:
        return 'PENDING REVIEW';
      case CashbackStatus.approved:
        return 'APPROVED';
      case CashbackStatus.rejected:
        return 'REJECTED';
    }
  }

  static CashbackStatus fromApi(String? value) {
    switch (value) {
      case 'approved':
        return CashbackStatus.approved;
      case 'rejected':
        return CashbackStatus.rejected;
      case 'pending':
      default:
        return CashbackStatus.pending;
    }
  }
}