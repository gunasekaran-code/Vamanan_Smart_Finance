/// The five roles the app knows about. Add a new role here first —
/// PermissionService and every RBAC check downstream reads from this
/// enum, so nothing else needs a new "if role == ..." branch.
enum UserRole {
  admin,
  staff,
  manager,
  advocate,
  auditor;

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
    }
  }

  static UserRole fromApiValue(String value) {
    return UserRole.values.firstWhere(
      (r) => r.apiValue == value.trim().toUpperCase(),
      orElse: () => UserRole.staff,
    );
  }
}
