import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/models/auth_models.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/network/api_response.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ApiClient _client = ApiClient.instance;

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

  Future<ApiResponse<void>> verifyOtp(VerifyOtpRequest request) {
    return _guard(
      request.validate(),
      () => _client.post<void>(AuthEndpoints.verifyOtp, body: request.toJson()),
    );
  }

  Future<ApiResponse<void>> resetPassword(ResetPasswordRequest request) {
    return _guard(
      request.validate(),
      () => _client.post<void>(
        AuthEndpoints.resetPassword,
        body: request.toJson(),
      ),
    );
  }

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
