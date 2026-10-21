import 'package:flutter/material.dart';

/// -----------------------------------------------------------------------
/// ROLES
/// -----------------------------------------------------------------------
/// Mirrors `$allowedRoles` in api/admin/add_staff.php exactly. Keep this in
/// sync with the backend — if you add a role here without adding it to the
/// PHP allow-list (or vice versa), registration will fail with
/// "Invalid staff role."
class StaffRole {
  final String value; // sent to backend, lowercase
  final String label; // shown in UI, uppercase to match existing style

  const StaffRole._(this.value, this.label);

  static const manager = StaffRole._('manager', 'MANAGER');
  static const staff = StaffRole._('staff', 'STAFF');
  static const advocate = StaffRole._('advocate', 'ADVOCATE');
  static const auditor = StaffRole._('auditor', 'AUDITOR');

  static const List<StaffRole> all = [manager, staff, advocate, auditor];

  static StaffRole fromValue(String value) {
    return all.firstWhere(
      (r) => r.value == value,
      orElse: () => staff,
    );
  }
}

/// -----------------------------------------------------------------------
/// PERMISSIONS
/// -----------------------------------------------------------------------
/// Mirrors `$allowedPermissions` in api/admin/add_staff.php. Only a curated
/// subset is exposed in the onboarding grid (the ones that make sense to
/// grant at staff-creation time); the rest (fiscal_reports, agreements,
/// etc.) can be added the same way if/when they need a toggle here.
class StaffPermission {
  final String id; // sent to backend, must match $allowedPermissions
  final String label;
  final IconData icon;

  const StaffPermission._(this.id, this.label, this.icon);

  static const overview = StaffPermission._('overview', 'DASHBOARD', Icons.bar_chart);
  static const investments = StaffPermission._('investments', 'INVESTMENTS', Icons.shopping_cart_outlined);
  static const inventory = StaffPermission._('inventory', 'ASSETS', Icons.shopping_bag_outlined);
  static const users = StaffPermission._('users', 'ENTITIES', Icons.people_outline);
  static const genealogy = StaffPermission._('genealogy', 'GENEALOGY', Icons.account_tree_outlined);
  static const walletsView = StaffPermission._('wallets_view', 'WALLETS', Icons.account_balance_wallet_outlined);
  static const kyc = StaffPermission._('kyc', 'KYC', Icons.verified_user_outlined);
  static const withdrawals = StaffPermission._('withdrawals', 'WITHDRAWALS', Icons.account_balance_outlined);
  static const tickets = StaffPermission._('tickets', 'TICKETS', Icons.confirmation_number_outlined);
  static const marketRates = StaffPermission._('market_rates', 'MARKET RATES', Icons.trending_up);
  static const recruitment = StaffPermission._('recruitment', 'STAFFING', Icons.person_add_outlined);
  static const settings = StaffPermission._('settings', 'SETTINGS', Icons.language);

  static const List<StaffPermission> all = [
    overview,
    investments,
    inventory,
    users,
    genealogy,
    walletsView,
    kyc,
    withdrawals,
    tickets,
    marketRates,
    recruitment,
    settings,
  ];

  /// Sensible defaults for a brand-new operations hire.
  static const Set<String> defaultSelectedIds = {'overview', 'kyc'};
}

/// -----------------------------------------------------------------------
/// REQUEST
/// -----------------------------------------------------------------------
class StaffRegistrationRequest {
  final String name;
  final String email;
  final String password;
  final String role; // StaffRole.value
  final List<String> permissions; // StaffPermission.id values

  const StaffRegistrationRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.permissions,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'permissions': permissions,
      };
}

/// -----------------------------------------------------------------------
/// RESULT
/// -----------------------------------------------------------------------
class StaffRegistrationResult {
  final String userId;
  final String message;
  final String name;
  final String email;
  final String role;
  final List<String> permissions;

  const StaffRegistrationResult({
    required this.userId,
    required this.message,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
  });

  factory StaffRegistrationResult.fromJson(
    Map<String, dynamic> json, {
    required StaffRegistrationRequest request,
  }) {
    // add_staff.php only echoes back {status, message, user_id} on success,
    // so the rest of the display fields are filled in from what we sent.
    return StaffRegistrationResult(
      userId: (json['user_id'] ?? '').toString(),
      message: (json['message'] ?? 'Staff account created successfully.').toString(),
      name: request.name,
      email: request.email,
      role: request.role,
      permissions: request.permissions,
    );
  }
}

/// -----------------------------------------------------------------------
/// LIST-ROW MODEL (unchanged shape from the original screen, kept here so
/// staff_add_screen.dart has a single import for everything staff-related)
/// -----------------------------------------------------------------------
class Member {
  final String id;
  final String name;
  final String phone;
  final String branch;
  final String status;
  final String accountType;
  final String dateJoined;
  final String role;

  const Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.branch,
    required this.status,
    required this.accountType,
    required this.dateJoined,
    this.role = '',
  });

  bool get isStaff => role != 'customer';

  factory Member.fromUser(Map<String, dynamic> user) {
    final rawDate = (user['created_at'] ?? '').toString();
    final date = DateTime.tryParse(rawDate);
    final formattedDate = date == null
        ? (rawDate.isEmpty ? 'Unknown' : rawDate)
        : '${_monthName(date.month)} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
    final role = (user['role'] ?? '').toString().toLowerCase();
    final status = (user['status'] ?? 'active').toString();

    return Member(
      id: (user['id'] ?? '').toString(),
      name: (user['name'] ?? 'Unnamed').toString(),
      phone: (user['phone'] ?? 'N/A').toString(),
      branch: 'Main Office',
      status: status.isEmpty ? 'Active' : _titleCase(status),
      accountType: 'Portal Active',
      dateJoined: formattedDate,
      role: role,
    );
  }

  /// Builds a row from a fresh registration result when the registration
  /// dialog returns to its caller.
  factory Member.fromRegistration(StaffRegistrationResult result) {
    return Member(
      id: result.userId,
      name: result.name,
      phone: 'N/A',
      branch: 'Main Office',
      status: 'Active',
      accountType: 'Portal Active',
      dateJoined: 'Today',
      role: result.role,
    );
  }

  static String _monthName(int month) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][month];

  static String _titleCase(String value) => value.isEmpty
      ? value
      : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}