/// Request/result models for the three auth flows: sign in, register, and the
/// OTP-based password reset.
///
/// Each request owns its own [validate] so the screens, the service, and any
/// future caller all reject the same bad input with the same wording — and the
/// backend never gets a round trip it was always going to refuse.

final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

/// `POST auth/login.php` — `{email, password}`.
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'password': password,
      };

  /// Null when the request is worth sending; otherwise the message to show.
  String? validate() {
    if (email.trim().isEmpty) return 'Enter your email address.';
    if (!isValidEmail(email)) return 'Enter a valid email address.';
    if (password.isEmpty) return 'Enter your password.';
    return null;
  }
}

/// `POST auth/register.php` — `{name, email, password, phone, referral_code?}`.
///
/// The backend forces every self-registered account to `pending`, so a success
/// here means "submitted for admin approval", not "signed in".
class RegisterRequest {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String referralCode;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.referralCode = '',
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
    };
    // Only send the referral when it was filled in: the backend treats an
    // unmatched code as "no referrer", but an empty one skips the lookup.
    if (referralCode.trim().isNotEmpty) {
      json['referral_code'] = referralCode.trim();
    }
    return json;
  }

  String? validate() {
    if (name.trim().isEmpty) return 'Enter your full name.';
    if (email.trim().isEmpty) return 'Enter your email address.';
    if (!isValidEmail(email)) return 'Enter a valid email address.';
    // `register.php` rejects a blank phone outright — catch it here so the
    // user sees which field is missing instead of a generic server message.
    if (phone.trim().isEmpty) return 'Enter your phone number.';
    if (phone.trim().length < 10) return 'Enter a valid phone number.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }
}

/// What `auth/register.php` hands back on success.
class RegisterResult {
  final String userId;
  final String message;

  const RegisterResult({required this.userId, required this.message});

  factory RegisterResult.fromJson(Map<String, dynamic> json) => RegisterResult(
        userId: (json['user_id'] ?? '').toString(),
        message: (json['message'] ?? 'Registration successful.').toString(),
      );
}

/// `POST auth/forgot_password.php` — `{email}`.
class ForgotPasswordRequest {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email.trim()};

  String? validate() {
    if (email.trim().isEmpty) return 'Enter your registered email address.';
    if (!isValidEmail(email)) return 'Enter a valid email address.';
    return null;
  }
}

/// The reset session opened by `auth/forgot_password.php`.
///
/// Mail delivery is currently switched off on the backend, which returns the
/// 6-digit code in the response body instead — [otp] carries it so the screen
/// can show the code rather than pointing the user at an inbox that will stay
/// empty. Once mail is re-enabled the field simply arrives empty and the UI
/// falls back to "check your email".
class PasswordResetChallenge {
  final String email;
  final String otp;
  final String message;

  const PasswordResetChallenge({
    required this.email,
    required this.otp,
    required this.message,
  });

  bool get hasInlineOtp => otp.isNotEmpty;

  factory PasswordResetChallenge.fromJson(
    Map<String, dynamic> json, {
    required String email,
  }) {
    return PasswordResetChallenge(
      email: email,
      otp: (json['otp'] ?? '').toString(),
      message: (json['message'] ?? 'Verification code generated.').toString(),
    );
  }
}

/// `POST auth/verify_otp.php` — `{email, otp}`. Checks the code without
/// consuming the reset session, so the UI can gate the new-password step.
class VerifyOtpRequest {
  final String email;
  final String otp;

  const VerifyOtpRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'otp': otp.trim(),
      };

  String? validate() {
    final code = otp.trim();
    if (code.isEmpty) return 'Enter the 6-digit verification code.';
    if (code.length != 6 || int.tryParse(code) == null) {
      return 'The verification code is 6 digits.';
    }
    return null;
  }
}

/// `POST auth/reset_password.php` — `{email, otp, new_password}`.
///
/// The OTP is re-sent here because this call is what actually consumes and
/// clears the reset session; verifying alone leaves it open.
class ResetPasswordRequest {
  final String email;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  const ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'otp': otp.trim(),
        'new_password': newPassword,
      };

  String? validate() {
    final otpError = VerifyOtpRequest(email: email, otp: otp).validate();
    if (otpError != null) return otpError;
    if (newPassword.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (newPassword != confirmPassword) return 'The passwords do not match.';
    return null;
  }
}
