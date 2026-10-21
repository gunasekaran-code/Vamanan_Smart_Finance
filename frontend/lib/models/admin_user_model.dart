/// Mirrors the row shape returned by api/admin/all_users.php
/// (users LEFT JOIN wallets LEFT JOIN users AS ref).
class AdminUserModel {
  final int id;
  final String customerId; // u.customer_id  (e.g. "VEV100")
  final String referralCode; // u.referral_code
  final String name;
  final String email;
  final String role; // e.g. CUSTOMER, STAFF, MANAGER, ADVOCATE, AUDITOR
  final String status; // e.g. ACTIVE, PENDING REVIEW, SUSPENDED
  final String kycStatus;
  final String? kycDocument;
  final DateTime? createdAt;
  final int? referrerId;
  final bool referralActive;
  final String? referrerName;
  final String? referrerCustomerId;
  final String? referrerReferralCode;
  final double balance; // COALESCE(w.balance, 0)

  bool isSelected; // UI-only, not part of the API payload

  AdminUserModel({
    required this.id,
    required this.customerId,
    required this.referralCode,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.kycStatus,
    required this.kycDocument,
    required this.createdAt,
    required this.referrerId,
    required this.referralActive,
    required this.referrerName,
    required this.referrerCustomerId,
    required this.referrerReferralCode,
    required this.balance,
    this.isSelected = false,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: _asInt(json['id']),
      customerId: _asString(json['customer_id']),
      referralCode: _asString(json['referral_code']),
      name: _asString(json['name']),
      email: _asString(json['email']),
      role: _asString(json['role']).toUpperCase(),
      status: _asString(json['status']).toUpperCase(),
      kycStatus: _asString(json['kyc_status']),
      kycDocument: json['kyc_document']?.toString(),
      createdAt: _asDate(json['created_at']),
      referrerId: json['referrer_id'] == null ? null : _asInt(json['referrer_id']),
      referralActive: _asBool(json['referral_active']),
      referrerName: (json['referrer_name'] as String?)?.trim().isNotEmpty == true
          ? json['referrer_name'] as String
          : null,
      referrerCustomerId: json['referrer_customer_id']?.toString(),
      referrerReferralCode: json['referrer_referral_code']?.toString(),
      balance: _asDouble(json['balance']),
    );
  }

  /// "21 AUG" style short label used on the card.
  String get joinedLabel {
    if (createdAt == null) return '—';
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return '${createdAt!.day} ${months[createdAt!.month - 1]}';
  }

  String get referredByLabel =>
      referrerName != null ? '$referrerName (${referrerCustomerId ?? "—"})' : 'DIRECT — NO REFERRER';

  static int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
  static double _asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;
  static String _asString(dynamic v) => v == null ? '' : v.toString();
  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    final s = '$v';
    return s == '1' || s.toLowerCase() == 'true';
  }
  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty || s == '0000-00-00' || s.startsWith('0000-00-00')) return null;
    return DateTime.tryParse(s);
  }
}