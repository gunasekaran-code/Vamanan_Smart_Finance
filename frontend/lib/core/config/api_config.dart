import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Where the PHP backend in `api/` lives.
///
/// The host is resolved in this order:
///   1. `--dart-define=API_BASE_URL=https://your-host/api` — always wins, and
///      is what CI / staging / production builds should pass.
///   2. A per-platform localhost default, because "localhost" does not mean
///      the same machine everywhere: the Android emulator reaches the host
///      machine on 10.0.2.2, while web/desktop/iOS-simulator reach it on
///      127.0.0.1.
///
/// Port 8889 is MAMP's default Apache port, matching the MAMP MySQL port
/// (8889) that `api/config.php` connects to.
class ApiConfig {
  ApiConfig._();

  static const String _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// MAMP's *Apache* port. Note this is deliberately not 8889 — that is
  /// MAMP's MySQL port, which `api/config.php` uses to reach the database
  /// from inside PHP. It speaks the MySQL wire protocol, not HTTP, so the
  /// app can never talk to it directly.
  static const String _defaultPort = '8888';

  /// Path from MAMP's document root (`/Applications/MAMP/htdocs`) to the
  /// `api/` folder. The project lives outside htdocs, so it is reached via a
  /// symlink:
  ///
  ///     ln -sfn "/Users/guna/Cloud Hawk/Vamanan V" /Applications/MAMP/htdocs/vamanan
  ///
  /// The link name avoids the space in the folder name, which otherwise has
  /// to be percent-encoded in every URL. Override together with the host when
  /// the backend is deployed somewhere else.
  static const String _apiPath = '/vamanan/api';

  /// e.g. `http://127.0.0.1:8889/Vamanan%20V/api`
  static String get baseUrl {
    if (_override.isNotEmpty) return _stripTrailingSlash(_override);
    return 'http://$_host:$_defaultPort$_apiPath';
  }

  static String get _host {
    if (kIsWeb) return '127.0.0.1';
    try {
      if (Platform.isAndroid) return '10.0.2.2';
    } catch (_) {
      // Platform is unavailable on some targets; fall through to loopback.
    }
    return '127.0.0.1';
  }

  static String _stripTrailingSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;

  /// Builds a full endpoint URI from a path relative to `api/`,
  /// e.g. `endpoint('auth/login.php')`.
  static Uri endpoint(String path) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseUrl/$clean');
  }

  /// How long a single request may take before it is treated as a
  /// connectivity failure.
  static const Duration timeout = Duration(seconds: 20);
}

/// Every auth endpoint this app talks to, in one place so a rename on the
/// backend is a one-line change here rather than a grep across screens.
class AuthEndpoints {
  AuthEndpoints._();

  static const String login = 'auth/login.php';
  static const String register = 'auth/register.php';
  static const String forgotPassword = 'auth/forgot_password.php';
  static const String verifyOtp = 'auth/verify_otp.php';
  static const String resetPassword = 'auth/reset_password.php';
}
