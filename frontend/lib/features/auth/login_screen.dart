import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/models/auth_models.dart';
import 'package:frontend/core/routing/app_routes.dart';
import 'package:frontend/core/services/permission_service.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  late final TapGestureRecognizer _registerTap = TapGestureRecognizer()
    ..onTap = () => context.push(AppRoutes.register);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _registerTap.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    // Same rules the service would apply — checked here so an obviously
    // incomplete form never costs a round trip.
    final localError = LoginRequest(email: email, password: password).validate();
    if (localError != null) {
      ToastService.show(
        title: 'Check Your Details',
        message: localError,
        type: ToastType.error,
      );
      return;
    }

    setState(() => _loading = true);
    final response =
        await SessionService.instance.login(email: email, password: password);
    if (!mounted) return;
    setState(() => _loading = false);

    if (!response.success) {
      // The backend explains the refusal itself — wrong password, unknown
      // email, account pending approval or suspended — so show its message.
      ToastService.show(
        title: 'Login Failed',
        message: response.message,
        type: ToastType.error,
      );
      return;
    }

    final user = SessionService.instance.currentUser!;
    ToastService.show(
      title: 'Welcome Back',
      message: response.message,
      type: ToastType.success,
    );
    context.go(PermissionService.landingRouteFor(user.role));
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ClipRRect(
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
                          // Circular Top Icon
                          Container(
                            width: 76,
                            height: 76,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.kPrimary.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Title & Subtitle
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              color: AppColors.kTextDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sign in to continue',
                            style: TextStyle(
                              color: AppColors.kTextMuted,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Email Field
                          TextField(
                            controller: _emailCtrl,
                            enabled: !_loading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              hintText: 'Email address',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.6),
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                                color: AppColors.kPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password Field
                          TextField(
                            controller: _passCtrl,
                            enabled: !_loading,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.6),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.kPrimary,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.kPrimary,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push(AppRoutes.recoverKey),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: AppColors.kPrimary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
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
                                  : const Text(
                                      'LOGIN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Register Footer
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: AppColors.kTextMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                const TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: 'Register',
                                  style: const TextStyle(
                                    color: AppColors.kPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  recognizer: _registerTap,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
