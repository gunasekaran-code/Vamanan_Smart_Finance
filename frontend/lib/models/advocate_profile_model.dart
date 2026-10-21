// models/advocate_profile_models.dart
//
// Maps one row from GET admin/all_users.php -> data[]
//
// That endpoint's query (as shared) selects:
//   u.id, u.customer_id, u.referral_code, u.name, u.email, u.role, u.status,
//   u.kyc_status, u.kyc_document, u.created_at, u.referrer_id,
//   COALESCE(u.referral_active, 1) AS referral_active,
//   ref.name AS referrer_name, ref.customer_id AS referrer_customer_id,
//   ref.referral_code AS referrer_referral_code, COALESCE(w.balance, 0) as balance
//
// It does NOT select phone/bio columns, even if the `users` table has them.
// fromJson() below tries a few likely key names for phone/bio and falls back
// to null (rendered as "NOT SET" / a default bio in the UI) so the screen
// still works today. If your `users` table has real phone/bio columns,
// either add them to the all_users.php SELECT, or tell me the column names
// and I'll adjust the keys tried here — no other change needed.

class AdvocateProfile {
  final int id;
  final String? customerId;
  final String name;
  final String email;
  final String role;
  final String status;
  final String kycStatus;
  final String? phone;
  final String? bio;
  final String createdAt;
  final double balance;

  AdvocateProfile({
    required this.id,
    this.customerId,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.kycStatus,
    this.phone,
    this.bio,
    required this.createdAt,
    required this.balance,
  });

  factory AdvocateProfile.fromJson(Map<String, dynamic> json) {
    return AdvocateProfile(
      id: _asInt(json['id']) ?? 0,
      customerId: json['customer_id']?.toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      kycStatus: (json['kyc_status'] ?? '').toString(),
      phone: (json['phone'] ?? json['phone_number'] ?? json['mobile'])?.toString(),
      bio: (json['bio'] ?? json['about'] ?? json['description'])?.toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      balance: _asDouble(json['balance']) ?? 0,
    );
  }

  AdvocateProfile copyWith({String? phone, String? bio}) {
    return AdvocateProfile(
      id: id,
      customerId: customerId,
      name: name,
      email: email,
      role: role,
      status: status,
      kycStatus: kycStatus,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      balance: balance,
    );
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
}

/// Holds the id of the currently logged-in advocate for this session.
///
/// TODO: set this once, right after a successful login
/// (e.g. `AdvocateSession.currentUserId = loginResponse.userId;`),
/// wherever your app currently stores auth/session state.
class AdvocateSession {
  AdvocateSession._();
  static int? currentUserId;
}