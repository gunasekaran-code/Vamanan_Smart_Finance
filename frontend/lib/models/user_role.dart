/// The four roles the app knows about. Add a new role here first —
/// PermissionService and every RBAC check downstream reads from this
/// enum, so nothing else needs a new "if role == ..." branch.
enum UserRole {
  superAdmin,
  admin,
  staff,
  customer;

  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Staff';
      case UserRole.customer:
        return 'Customer';
    }
  }

  /// The string a real backend would send/expect for this role
  /// (e.g. a JWT claim or a `role` field on the login response).
  String get apiValue {
    switch (this) {
      case UserRole.superAdmin:
        return 'SUPERADMIN';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.staff:
        return 'STAFF';
      case UserRole.customer:
        return 'CUSTOMER';
    }
  }

  static UserRole fromApiValue(String value) {
    return UserRole.values.firstWhere(
      (r) => r.apiValue == value.trim().toUpperCase(),
      orElse: () => UserRole.customer,
    );
  }
}
