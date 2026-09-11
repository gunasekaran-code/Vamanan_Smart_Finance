import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/models/auth_models.dart';
import 'package:frontend/core/routing/app_routes.dart';
import 'package:frontend/core/services/auth_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/glass_widgets.dart';

/// The three server round trips the reset takes, plus the terminal state.
///
/// They map one-to-one onto `auth/forgot_password.php`, `auth/verify_otp.php`
/// and `auth/reset_password.php`. Verifying is a separate step on purpose: it
/// checks the code *without* consuming the reset session, so a mistyped digit
/// can be fixed without starting over (and without tripping the 2-minute
/// rate limit on requesting a fresh code).
enum _ResetStep { requestCode, verifyCode, newPassword, done }

class RecoverKeyScreen extends StatefulWidget {
  const RecoverKeyScreen({super.key});

  @override
  State<RecoverKeyScreen> createState() => _RecoverKeyScreenState();
}

class _RecoverKeyScreenState extends State<RecoverKeyScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final AuthService _auth = AuthService.instance;

  _ResetStep _step = _ResetStep.requestCode;
  bool _loading = false;
  bool _obscure = true;

  /// The open reset session. Carries the 6-digit code when the backend
  /// returns it inline (mail delivery is currently disabled there).
  PasswordResetChallenge? _challenge;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _email => _challenge?.email ?? _emailCtrl.text.trim();

  void _toastError(String message) => ToastService.show(
        title: 'Recovery Failed',
        message: message,
        type: ToastType.error,
      );

  /// Step 1 — open a 10-minute OTP session for the email.
  Future<void> _requestCode() async {
    if (_loading) return;

    setState(() => _loading = true);
    final response = await _auth
        .forgotPassword(ForgotPasswordRequest(email: _emailCtrl.text));
    if (!mounted) return;
    setState(() => _loading = false);

    if (!response.success || response.data == null) {
      // Unknown email and the 2-minute rate limit both land here.
      _toastError(response.message);
      return;
    }

    final challenge = response.data!;
    setState(() {
      _challenge = challenge;
      _step = _ResetStep.verifyCode;
      // The backend hands the code back in the response while mail is off —
      // prefill it so the user isn't asked to retype what's on screen.
      if (challenge.hasInlineOtp) _otpCtrl.text = challenge.otp;
    });

    ToastService.show(
      title: 'Code Generated',
      message: challenge.message,
      type: ToastType.success,
    );
  }

  /// Step 2 — check the code without spending the session.
  Future<void> _verifyCode() async {
    if (_loading) return;

    setState(() => _loading = true);
    final response = await _auth
        .verifyOtp(VerifyOtpRequest(email: _email, otp: _otpCtrl.text));
    if (!mounted) return;
    setState(() => _loading = false);

    if (!response.success) {
      // The message counts down the remaining attempts (5 locks the session).
      _toastError(response.message);
      return;
    }

    setState(() => _step = _ResetStep.newPassword);
    ToastService.show(
      title: 'Identity Verified',
      message: response.message,
      type: ToastType.success,
    );
  }

  /// Step 3 — set the new password and close the reset session.
  Future<void> _submitNewPassword() async {
    if (_loading) return;

    setState(() => _loading = true);
    final response = await _auth.resetPassword(ResetPasswordRequest(
      email: _email,
      otp: _otpCtrl.text,
      newPassword: _passCtrl.text,
      confirmPassword: _confirmCtrl.text,
    ));
    if (!mounted) return;
    setState(() => _loading = false);

    if (!response.success) {
      _toastError(response.message);
      return;
    }

    setState(() => _step = _ResetStep.done);
    ToastService.show(
      title: 'Password Updated',
      message: response.message,
      type: ToastType.success,
    );
  }

  /// Lets the user correct a typo in the email before the rate limit applies.
  void _changeEmail() {
    setState(() {
      _step = _ResetStep.requestCode;
      _challenge = null;
      _otpCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 380;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.kPrimary,
              AppColors.kPrimaryLight,
              AppColors.kBackground,
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 18 : 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassBackButton(onTap: () => context.go(AppRoutes.login)),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    color: Colors.white.withOpacity(0.9),
                                    border: Border.all(
                                      color: AppColors.kPrimary.withOpacity(0.2),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _step == _ResetStep.done
                                          ? Icons.lock_reset_rounded
                                          : Icons.vpn_key_rounded,
                                      color: AppColors.kPrimary,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Center(
                                child: Text(
                                  'Security Recovery',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.kTextDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Text(
                                  _subtitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.kTextMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              ..._buildStep(),
                              const SizedBox(height: 22),
                              Divider(
                                  color: Colors.black.withOpacity(0.1),
                                  thickness: 1),
                              const SizedBox(height: 16),
                              Center(
                                child: GestureDetector(
                                  onTap: () => context.go(AppRoutes.login),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: AppColors.kTextMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                        height: 1.5,
                                      ),
                                      children: const [
                                        TextSpan(text: 'REMEMBERED KEY?  '),
                                        TextSpan(
                                          text: 'RETURN TO AUTHENTICATION',
                                          style: TextStyle(
                                            color: AppColors.kPrimary,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    switch (_step) {
      case _ResetStep.requestCode:
        return 'Identity access restoration node';
      case _ResetStep.verifyCode:
        return 'Enter the 6-digit code for $_email';
      case _ResetStep.newPassword:
        return 'Choose a new password for $_email';
      case _ResetStep.done:
        return 'Your password has been updated';
    }
  }

  List<Widget> _buildStep() {
    switch (_step) {
      case _ResetStep.requestCode:
        return _requestCodeStep();
      case _ResetStep.verifyCode:
        return _verifyCodeStep();
      case _ResetStep.newPassword:
        return _newPasswordStep();
      case _ResetStep.done:
        return _doneStep();
    }
  }

  List<Widget> _requestCodeStep() => [
        _field(
          controller: _emailCtrl,
          hint: 'Enter verified email',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _requestCode(),
        ),
        const SizedBox(height: 20),
        _primaryButton('Generate Verification Code', _requestCode),
      ];

  List<Widget> _verifyCodeStep() => [
        if (_challenge?.hasInlineOtp ?? false) _inlineOtpCard(_challenge!.otp),
        if (_challenge?.hasInlineOtp ?? false) const SizedBox(height: 16),
        _field(
          controller: _otpCtrl,
          hint: '6-digit code',
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onSubmitted: (_) => _verifyCode(),
        ),
        const SizedBox(height: 20),
        _primaryButton('Verify Code', _verifyCode),
        const SizedBox(height: 10),
        _secondaryButton('Use a different email', _changeEmail),
      ];

  List<Widget> _newPasswordStep() => [
        _field(
          controller: _passCtrl,
          hint: 'New password',
          icon: Icons.lock_outline_rounded,
          obscure: _obscure,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.kPrimary,
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 14),
        _field(
          controller: _confirmCtrl,
          hint: 'Confirm new password',
          icon: Icons.lock_person_outlined,
          obscure: _obscure,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitNewPassword(),
        ),
        const SizedBox(height: 20),
        _primaryButton('Update Password', _submitNewPassword),
      ];

  List<Widget> _doneStep() => [
        _noticeCard(
          icon: Icons.check_circle_outline_rounded,
          title: 'Password reset complete',
          body: 'Sign in with your new password to continue.',
        ),
        const SizedBox(height: 20),
        _primaryButton(
          'Return to Login',
          () => context.go(AppRoutes.login),
        ),
      ];

  /// Mail delivery is disabled on the backend, which returns the code in the
  /// response instead — surface it plainly rather than sending the user to an
  /// inbox that will stay empty.
  Widget _inlineOtpCard(String otp) => _noticeCard(
        icon: Icons.mark_email_read_rounded,
        title: 'Your verification code',
        body: 'Valid for 10 minutes. Five incorrect attempts lock this session.',
        trailing: Text(
          otp,
          style: const TextStyle(
            color: AppColors.kPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
          ),
        ),
      );

  Widget _noticeCard({
    required IconData icon,
    required String title,
    required String body,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kPrimary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.kPrimary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.kTextDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (trailing != null) ...[
            const SizedBox(height: 10),
            Center(child: trailing),
          ],
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.kTextMuted,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      enabled: !_loading,
      keyboardType: keyboardType,
      obscureText: obscure,
      textInputAction: textInputAction ?? TextInputAction.next,
      inputFormatters: inputFormatters,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        prefixIcon: Icon(icon, color: AppColors.kPrimary, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.kPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _secondaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton(
        onPressed: _loading ? null : onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.kPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
