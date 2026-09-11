import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/models/auth_models.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/network/api_response.dart';

/// Every call the app makes against `api/auth/*`.
///
/// Each method validates the request first, then returns an [ApiResponse]
/// whose [ApiResponse.message] is always safe to show the user — the backend's
/// own wording on a rejection, a local message on a validation miss or a
/// transport failure. Screens therefore never need a try/catch of their own.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ApiClient _client = ApiClient.instance;

  /// Signs in. On success [ApiResponse.data] is the authenticated [AppUser].
  ///
  /// `login.php` answers HTTP 200 for wrong passwords, unknown emails, and
  /// accounts still pending approval — all of those arrive as an unsuccessful
  /// response carrying the backend's explanation.
  Future<ApiResponse<AppUser>> login(LoginRequest request) {
    return _guard(
      request.validate(),
      () => _client.post<AppUser>(
        AuthEndpoints.login,
        body: request.toJson(),
        parser: (json) => AppUser.fromJson(
          (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      ),
    );
  }

  /// Creates an account. The new user lands in `pending` and cannot sign in
  /// until an admin approves it, so callers should route back to login with
  /// the returned message rather than trying to establish a session.
  Future<ApiResponse<RegisterResult>> register(RegisterRequest request) {
    return _guard(
      request.validate(),
      () => _client.post<RegisterResult>(
        AuthEndpoints.register,
        body: request.toJson(),
        parser: RegisterResult.fromJson,
      ),
    );
  }

  /// Step 1 of the reset: opens a 10-minute OTP session for the email.
  ///
  /// The backend rate-limits this to one request every 2 minutes and refuses
  /// unknown emails outright — both surface as the message on the response.
  Future<ApiResponse<PasswordResetChallenge>> forgotPassword(
    ForgotPasswordRequest request,
  ) {
    return _guard(
      request.validate(),
      () => _client.post<PasswordResetChallenge>(
        AuthEndpoints.forgotPassword,
        body: request.toJson(),
        parser: (json) =>
            PasswordResetChallenge.fromJson(json, email: request.email.trim()),
      ),
    );
  }

  /// Step 2: checks the code without spending the session, so a wrong entry
  /// can be corrected on the same screen. Five wrong tries lock the session.
  Future<ApiResponse<void>> verifyOtp(VerifyOtpRequest request) {
    return _guard(
      request.validate(),
      () => _client.post<void>(AuthEndpoints.verifyOtp, body: request.toJson()),
    );
  }

  /// Step 3: sets the new password and closes the reset session.
  Future<ApiResponse<void>> resetPassword(ResetPasswordRequest request) {
    return _guard(
      request.validate(),
      () => _client.post<void>(
        AuthEndpoints.resetPassword,
        body: request.toJson(),
      ),
    );
  }

  /// Short-circuits on a local validation error, and converts a transport
  /// failure into a plain unsuccessful response so no screen has to handle
  /// [ApiException] itself.
  Future<ApiResponse<T>> _guard<T>(
    String? validationError,
    Future<ApiResponse<T>> Function() send,
  ) async {
    if (validationError != null) return ApiResponse<T>.failure(validationError);
    try {
      return await send();
    } on ApiException catch (e) {
      return ApiResponse<T>.failure(e.message);
    }
  }
}
