/// Model matching the JSON shape returned by `api/auditor/profile.php`.
///
/// GET  /auditor/profile.php?user_id=N
///   -> { id, name, email, phone, customer_id, role, status, created_at, wallet_balance }
/// POST /auditor/profile.php  (update)
///   -> { id, name, email, phone, customer_id, role, created_at }
///      (note: POST does not return `status` or `wallet_balance` — both are
///      nullable/defaulted here so parsing either response shape works.)
class AuditorProfile {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? customerId;
  final String role;
  final String? status;
  final DateTime? createdAt;
  final double walletBalance;

  const AuditorProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.customerId,
    required this.role,
    this.status,
    this.createdAt,
    this.walletBalance = 0,
  });

  factory AuditorProfile.fromJson(Map<String, dynamic> json) {
    return AuditorProfile(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: _orNotSet(json['phone']),
      customerId: json['customer_id']?.toString(),
      role: (json['role'] ?? 'auditor').toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      walletBalance:
          double.tryParse('${json['wallet_balance'] ?? 0}') ?? 0,
    );
  }

  static String _orNotSet(dynamic v) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? 'NOT SET' : s;
  }

  AuditorProfile copyWith({
    String? name,
    String? email,
    String? phone,
  }) {
    return AuditorProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      customerId: customerId,
      role: role,
      status: status,
      createdAt: createdAt,
      walletBalance: walletBalance,
    );
  }

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  String get dateJoinedLabel {
    final d = createdAt;
    if (d == null) return 'NOT SET';
    return '${d.day}/${d.month}/${d.year}';
  }
}