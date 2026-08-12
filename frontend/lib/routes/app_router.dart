import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_toast.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/members/members_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/unauthorized_screen.dart';
import '../screens/verify/verify_screen.dart';
import '../services/permission_service.dart';
import '../services/session_service.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';

/// Central router config.
///
/// The `redirect` callback below is the whole RBAC/auth guard: it runs
/// before every navigation (including deep links and browser
/// back/forward on web) so there is exactly one place that decides
/// whether a route is reachable — pages themselves never need to
/// re-check "am I allowed to be here?".
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: ToastService.navigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    // GoRouter re-evaluates `redirect` whenever SessionService calls
    // notifyListeners() (login, logout, role switch) — no manual
    // context.go() needed elsewhere in the app for those transitions.
    refreshListenable: SessionService.instance,
    redirect: _redirect,
    routes: [
      // Bare root and unknown paths both fall back through here rather
      // than rendering a blank/invalid screen.
      GoRoute(path: AppRoutes.root, redirect: (_, __) => AppRoutes.splash),
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.unauthorized, builder: (_, __) => const UnauthorizedScreen()),

      // StatefulShellRoute.indexedStack keeps AppShell (header + bottom
      // nav) mounted once, and swaps only the active branch's Navigator
      // underneath it — this is what gives the SPA "content-only"
      // navigation the brief asks for. Branch order must match
      // PermissionService.navEntries order.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.dashboard, builder: (_, __) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.members, builder: (_, __) => const MembersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.verify, builder: (_, __) => const VerifyScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.reports, builder: (_, __) => const ReportsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
    // Any path that doesn't match a route above (typo, stale link,
    // removed page) lands here instead of crashing or showing a blank
    // screen.
    errorBuilder: (_, __) => const NotFoundScreen(),
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final loggedIn = SessionService.instance.isLoggedIn;
    final path = state.matchedLocation;

    // Let the splash screen finish restoring the session before any
    // guard logic runs against it.
    if (path == AppRoutes.splash) return null;

    final isPublic = path == AppRoutes.login || path == AppRoutes.unauthorized;

    if (!loggedIn) {
      return isPublic ? null : AppRoutes.login;
    }

    final role = SessionService.instance.currentUser!.role;

    // Signed in: never show the login screen again.
    if (path == AppRoutes.login) {
      return PermissionService.landingRouteFor(role);
    }

    // Role guard: a direct/deep link to a page this role can't see
    // gets redirected instead of rendering a disallowed page.
    if (path != AppRoutes.unauthorized && !PermissionService.canAccess(path, role)) {
      return AppRoutes.unauthorized;
    }

    return null;
  }
}
