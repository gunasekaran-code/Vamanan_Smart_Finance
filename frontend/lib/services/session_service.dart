import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';

/// Frontend-only stand-in for a real auth/session layer.
///
/// It is a [ChangeNotifier] on purpose: [AppRouter] listens to it via
/// `refreshListenable`, so logging in, logging out, or switching role
/// re-runs the router's redirect logic automatically — no manual
/// navigation calls scattered around the app.
///
/// Swap the body of [login] and [restoreFromStorage] for real API calls
/// (e.g. `POST /auth/login`, reading a token from secure storage) when
/// the backend is ready. Everything downstream — redirects, RBAC, the
/// UI — already reacts to [currentUser] changing.
class SessionService extends ChangeNotifier {
  SessionService._();
  static final SessionService instance = SessionService._();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// One demo account per role so RBAC can be exercised without a
  /// backend. Password is ignored in this mock — replace [login] with
  /// a real request once an API exists.
  static final Map<String, AppUser> _demoDirectory = {
    'superadmin': const AppUser(
      id: 'u-1',
      name: 'Ava Rao',
      email: 'superadmin@smartfinance.dev',
      role: UserRole.superAdmin,
    ),
    'admin': const AppUser(
      id: 'u-2',
      name: 'CF Admin',
      email: 'admin@smartfinance.dev',
      role: UserRole.admin,
    ),
    'staff': const AppUser(
      id: 'u-3',
      name: 'Roki Field',
      email: 'staff@smartfinance.dev',
      role: UserRole.staff,
    ),
    'customer': const AppUser(
      id: 'u-4',
      name: 'Jessica Iyer',
      email: 'customer@smartfinance.dev',
      role: UserRole.customer,
    ),
  };

  /// Called once on cold start (see SplashScreen). TODO: replace with
  /// reading a persisted token (e.g. shared_preferences / secure
  /// storage), validating it against the backend, then setting
  /// [_currentUser] from the response instead of leaving it null.
  Future<void> restoreFromStorage() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  /// TODO: replace with a real `POST /auth/login` call once the
  /// backend exists; keep the same signature/return shape so callers
  /// (LoginScreen, ProfileScreen's demo role switcher) don't change.
  Future<bool> login({required String username, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500)); // simulate network
    final user = _demoDirectory[username.trim().toLowerCase()];
    if (user == null) return false;
    _currentUser = user;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
