import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/core/routing/app_routes.dart';
import 'package:frontend/core/services/permission_service.dart';

void main() {
  group('UserRole.customer', () {
    test('parses the value the users.role enum actually stores', () {
      expect(UserRole.fromApiValue('customer'), UserRole.customer);
      expect(UserRole.fromApiValue('CUSTOMER'), UserRole.customer);
      expect(UserRole.fromApiValue('  Customer '), UserRole.customer);
    });

    test('a self-registered account is a customer, not staff', () {
      // auth/register.php inserts without a `role` column, so the column
      // default ('customer') applies. Before this role existed the app read
      // that back as STAFF and handed out the staff menu.
      final user = AppUser.fromJson(const {
        'id': '7',
        'name': 'New Signup',
        'email': 'new@example.com',
        'role': 'customer',
      });
      expect(user.role, UserRole.customer);
    });

    test('an unrecognised role falls back to the least-privileged portal', () {
      expect(UserRole.fromApiValue('wizard'), UserRole.customer);
      expect(UserRole.fromApiValue(''), UserRole.customer);
    });

    test('still parses every other role', () {
      for (final role in UserRole.values) {
        expect(UserRole.fromApiValue(role.apiValue), role);
      }
    });

    test('round-trips through the cached session', () {
      const user = AppUser(
        id: '7',
        name: 'New Signup',
        email: 'new@example.com',
        role: UserRole.customer,
      );
      expect(AppUser.fromJson(user.toJson()).role, UserRole.customer);
    });
  });

  group('customer permissions', () {
    test('lands on the dashboard', () {
      expect(
        PermissionService.landingRouteFor(UserRole.customer),
        AppRoutes.dashboard,
      );
    });

    test('reaches its own portal', () {
      for (final route in const [
        AppRoutes.dashboard,
        '/auditor-buy',
        '/auditor-request',
        AppRoutes.customerCashback,
        '/auditor-cashback-application',
        '/auditor-referral',
        '/auditor-wallets',
        '/auditor-transaction',
        '/auditor-withdrawals',
        '/auditor-rules',
        '/auditor-kyc',
        '/auditor-agreements',
        AppRoutes.profile,
      ]) {
        expect(
          PermissionService.canAccess(route, UserRole.customer),
          isTrue,
          reason: '$route should be reachable by a customer',
        );
      }
    });

    test('cannot reach the auditor-only profile', () {
      // auditor/profile.php rejects any account whose role is not 'auditor',
      // so the customer has its own profile screen instead.
      expect(
        PermissionService.canAccess('/auditor-profile', UserRole.customer),
        isFalse,
      );
    });

    test('cannot reach back-office screens', () {
      for (final route in const [
        '/users',
        '/wallets',
        '/purchases',
        '/add-staff',
        '/cashback-applications',
        '/genealogy',
      ]) {
        expect(
          PermissionService.canAccess(route, UserRole.customer),
          isFalse,
          reason: '$route should be blocked for a customer',
        );
      }
    });

    test('every role has a landing route and a non-empty menu', () {
      for (final role in UserRole.values) {
        expect(PermissionService.menuFor(role), isNotEmpty, reason: '$role');
        expect(
          PermissionService.landingRouteFor(role),
          isNot(AppRoutes.unauthorized),
          reason: '$role',
        );
      }
    });
  });

  group('shell wiring', () {
    // AppBottomNav turns a route into a StatefulShellBranch index by looking
    // it up in shellBranchOrder; a tab whose route is missing there silently
    // does nothing when tapped.
    test('every bottom-nav route maps to a shell branch', () {
      for (final role in UserRole.values) {
        for (final entry in PermissionService.bottomNavFor(role)) {
          expect(
            AppRoutes.shellBranchOrder,
            contains(entry.route),
            reason: '${role.label} tab "${entry.label}" -> ${entry.route}',
          );
        }
      }
    });

    test('every customer menu route maps to a shell branch', () {
      final routes = PermissionService.menuFor(UserRole.customer)
          .expand((section) => section.items)
          .expand((item) => item.allRoutes);

      for (final route in routes) {
        expect(
          AppRoutes.shellBranchOrder,
          contains(route),
          reason: 'customer menu entry $route has no shell branch',
        );
      }
    });
  });
}
