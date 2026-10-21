/// The six roles the app knows about — one per value of the `role` enum on
/// the `users` table. Add a new role here first — PermissionService and every
/// RBAC check downstream reads from this enum, so nothing else needs a new
/// "if role == ..." branch.
enum UserRole {
  admin,
  staff,
  manager,
  advocate,
  auditor,
  customer;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Staff';
      case UserRole.manager:
        return 'Manager';
      case UserRole.advocate:
        return 'Advocate';
      case UserRole.auditor:
        return 'Auditor';
      case UserRole.customer:
        return 'Customer';
    }
  }

  /// The string a real backend would send/expect for this role
  /// (e.g. a JWT claim or a `role` field on the login response).
  String get apiValue {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.staff:
        return 'STAFF';
      case UserRole.manager:
        return 'MANAGER';
      case UserRole.advocate:
        return 'ADVOCATE';
      case UserRole.auditor:
        return 'AUDITOR';
      case UserRole.customer:
        return 'CUSTOMER';
    }
  }

  /// Unknown role strings fall back to [UserRole.customer] — the least
  /// privileged portal. `users.role` defaults to `'customer'` and
  /// `auth/register.php` omits the column entirely, so a self-registered
  /// account arrives here as `customer`; anything unrecognised is likelier
  /// to be a new end-user role than a staff one, and guessing low is the
  /// safe direction to guess.
  static UserRole fromApiValue(String value) {
    return UserRole.values.firstWhere(
      (r) => r.apiValue == value.trim().toUpperCase(),
      orElse: () => UserRole.customer,
    );
  }
}
