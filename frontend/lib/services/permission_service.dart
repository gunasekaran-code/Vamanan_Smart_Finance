import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../routes/app_routes.dart';

/// One persistent-shell tab: where it goes, what it's called, and who
/// is allowed to see it.
class NavEntry {
  final String route;
  final String label;
  final IconData icon;
  final List<UserRole> allowedRoles;

  const NavEntry({
    required this.route,
    required this.label,
    required this.icon,
    required this.allowedRoles,
  });

  bool isAllowedFor(UserRole role) => allowedRoles.contains(role);
}

/// Single source of truth for role-based access control.
///
/// To add a new tab: add one [NavEntry] below and one branch in
/// AppRouter. The bottom nav, the drawer, and the router's redirect
/// guard all read from [navEntries] — nothing else needs to change.
class PermissionService {
  PermissionService._();

  static const List<UserRole> _everyone = UserRole.values;
  static const List<UserRole> _staffAndUp = [
    UserRole.superAdmin,
    UserRole.admin,
    UserRole.staff,
  ];
  static const List<UserRole> _adminAndUp = [
    UserRole.superAdmin,
    UserRole.admin,
  ];

  static const List<NavEntry> navEntries = [
    NavEntry(
      route: AppRoutes.dashboard,
      label: 'Dashboard',
      icon: Icons.grid_view_rounded,
      allowedRoles: _everyone,
    ),
    NavEntry(
      route: AppRoutes.members,
      label: 'Members',
      icon: Icons.people_outline_rounded,
      allowedRoles: _staffAndUp, // superadmin, admin, staff
    ),
    NavEntry(
      route: AppRoutes.verify,
      label: 'Verify',
      icon: Icons.verified_outlined,
      allowedRoles: _staffAndUp, // superadmin, admin, staff
    ),
    NavEntry(
      route: AppRoutes.reports,
      label: 'Reports',
      icon: Icons.bar_chart_rounded,
      allowedRoles: _adminAndUp, // superadmin, admin only
    ),
    NavEntry(
      route: AppRoutes.profile,
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      allowedRoles: _everyone,
    ),
  ];

  static List<NavEntry> entriesFor(UserRole role) =>
      navEntries.where((e) => e.isAllowedFor(role)).toList(growable: false);

  /// True for routes not listed in [navEntries] (login, splash, ...) —
  /// those are gated separately by auth state, not by role.
  static bool canAccess(String route, UserRole role) {
    final matches = navEntries.where((e) => e.route == route);
    if (matches.isEmpty) return true;
    return matches.first.isAllowedFor(role);
  }

  /// First tab a role is allowed to land on. Used by the router redirect
  /// and the login screen instead of hard-coding "/dashboard" (which
  /// every role can reach here, but wouldn't necessarily in a future
  /// permission set).
  static String landingRouteFor(UserRole role) {
    final entries = entriesFor(role);
    return entries.isEmpty ? AppRoutes.unauthorized : entries.first.route;
  }
}
