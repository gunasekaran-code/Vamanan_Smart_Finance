import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/models/auth_models.dart';
import 'package:frontend/core/network/api_response.dart';
import 'package:frontend/core/services/auth_service.dart';

/// Holds the signed-in user and keeps a copy on disk.
///
/// It is a [ChangeNotifier] on purpose: [AppRouter] listens to it via
/// `refreshListenable`, so logging in or out re-runs the router's redirect
/// logic automatically — no manual navigation calls scattered around the app.
///
/// The backend is session-less (no token is issued; `auth/login.php` just
/// returns the user row), so "staying signed in" means caching that row and
/// restoring it on cold start. Swap [_cacheUser] for secure token storage if
/// the API ever starts issuing one.
class SessionService extends ChangeNotifier {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const String _userKey = 'auth.current_user';

  final AuthService _auth = AuthService.instance;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Called once on cold start (see SplashScreen): rehydrates the cached user
  /// so a returning user skips the login screen.
  Future<void> restoreFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      final user = AppUser.fromJson(decoded.cast<String, dynamic>());
      // A cached account that has since been suspended or reverted to pending
      // must not walk back in — drop the cache and let them sign in again.
      if (!user.isActive) {
        await prefs.remove(_userKey);
        return;
      }
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      debugPrint('SessionService: could not restore session ($e)');
    }
  }

  /// Signs in against `auth/login.php`.
  ///
  /// Returns the raw [ApiResponse] so the caller can show the backend's own
  /// message ("Incorrect password", "pending admin approval", …) rather than
  /// inventing one. The session is only established when it succeeds.
  Future<ApiResponse<AppUser>> login({
    required String email,
    required String password,
  }) async {
    final response = await _auth.login(
      LoginRequest(email: email, password: password),
    );

    final user = response.data;
    if (!response.success || user == null) {
      return response.success
          ? ApiResponse<AppUser>.failure(
              'Login succeeded but no account details were returned.')
          : response;
    }

    _currentUser = user;
    await _cacheUser(user);
    notifyListeners();
    return response;
  }

  /// Registers a new account. Deliberately does *not* sign the user in:
  /// `register.php` forces `status = 'pending'`, so the account cannot log in
  /// until an admin approves it.
  Future<ApiResponse<RegisterResult>> register(RegisterRequest request) {
    return _auth.register(request);
  }

  /// Replaces the cached user after a profile update elsewhere in the app.
  Future<void> updateCurrentUser(AppUser user) async {
    _currentUser = user;
    await _cacheUser(user);
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      debugPrint('SessionService: could not clear cached session ($e)');
    }
  }

  Future<void> _cacheUser(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } catch (e) {
      // Persisting is a convenience; a failure here must not break the login.
      debugPrint('SessionService: could not cache session ($e)');
    }
  }
}
