import 'dart:convert';

import 'user_role.dart';

/// The account the backend returns from `auth/login.php` (and the same shape
/// `auth/verify_login_otp.php` sends), minus the password it strips out.
///
/// Every field past [role] is optional on the wire: `login.php` only selects
/// the columns that actually exist on the `users` table, so an older schema
/// simply omits them.
class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  final String phone;

  /// `active` | `pending` | `suspended`. Login already refuses the last two,
  /// so a user held here is normally `active`.
  final String status;

  /// Fine-grained grants stored as a JSON array in the `permissions` column.
  /// Empty for roles whose access is purely role-based.
  final List<String> permissions;

  /// Sequential public identifier, e.g. `VEV001`.
  final String customerId;

  final String referralCode;

  /// Manager notification preferences (`users.notify_email` /
  /// `users.notify_system`). Login doesn't return them, so they default to on
  /// until `manager/update_profile.php` sends back the stored values.
  final bool notifyEmail;
  final bool notifySystem;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.status = 'active',
    this.permissions = const [],
    this.customerId = '',
    this.referralCode = '',
    this.notifyEmail = true,
    this.notifySystem = true,
  });

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  bool get isActive => status.toLowerCase() == 'active';

  bool hasPermission(String permission) => permissions.contains(permission);

  /// Builds an AppUser from the `user` object on a login response, or from
  /// the copy cached in shared_preferences (see [toJson]).
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['full_name'] ?? 'User').toString(),
      email: (json['email'] ?? '').toString(),
      role: UserRole.fromApiValue((json['role'] ?? 'STAFF').toString()),
      phone: (json['phone'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      permissions: _parsePermissions(json['permissions']),
      customerId: (json['customer_id'] ?? '').toString(),
      referralCode: (json['referral_code'] ?? '').toString(),
      notifyEmail: _parseFlag(json['notify_email']),
      notifySystem: _parseFlag(json['notify_system']),
    );
  }

  /// Round-trips through [AppUser.fromJson], so the cached session restores
  /// into exactly the user the backend sent.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.apiValue,
        'phone': phone,
        'status': status,
        'permissions': permissions,
        'customer_id': customerId,
        'referral_code': referralCode,
        'notify_email': notifyEmail ? 1 : 0,
        'notify_system': notifySystem ? 1 : 0,
      };

  AppUser copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? status,
    List<String>? permissions,
    String? customerId,
    String? referralCode,
    bool? notifyEmail,
    bool? notifySystem,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      customerId: customerId ?? this.customerId,
      referralCode: referralCode ?? this.referralCode,
      notifyEmail: notifyEmail ?? this.notifyEmail,
      notifySystem: notifySystem ?? this.notifySystem,
    );
  }

  /// MySQL sends TINYINT flags as `1`/`0` or `"1"`/`"0"`; a missing value
  /// means the column was never returned, so keep the default (on).
  static bool _parseFlag(Object? value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final raw = value.toString().trim().toLowerCase();
    return !(raw == '0' || raw == 'false' || raw.isEmpty);
  }

  /// The `permissions` column is written as a JSON array by the admin
  /// endpoints, but legacy rows hold a comma-separated string and fresh rows
  /// hold `''` — accept all three rather than losing the grants.
  static List<String> _parsePermissions(Object? value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    final raw = value.toString().trim();
    if (raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // Not JSON — fall through to the comma-separated reading.
    }

    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
