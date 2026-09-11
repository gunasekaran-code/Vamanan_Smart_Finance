import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/models/auth_models.dart';
import 'package:frontend/core/routing/app_routes.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_loading) return;

    final request = RegisterRequest(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
      password: _passCtrl.text,
      referralCode: _referralCtrl.text,
    );

    // Name, email, phone and password are all mandatory on the backend —
    // validate here so the user is told which field is missing.
    final localError = request.validate();
    if (localError != null) {
      ToastService.show(
        title: 'Missing Information',
        message: localError,
        type: ToastType.error,
      );
      return;
    }

    setState(() => _loading = true);
    final response = await SessionService.instance.register(request);
    if (!mounted) return;
    setState(() => _loading = false);

    if (!response.success) {
      // Covers the duplicate-email rejection as well as transport failures.
      ToastService.show(
        title: 'Registration Failed',
        message: response.message,
        type: ToastType.error,
      );
      return;
    }

    // `register.php` forces every self-registered account to `pending`, so
    // there is no session to establish — hand the user back to login with the
    // backend's approval notice.
    ToastService.show(
      title: 'Account Created',
      message: response.message,
      type: ToastType.success,
    );
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 380;
    final isWide = width >= 620;

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
                constraints: BoxConstraints(maxWidth: isWide ? 560 : 420),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                              child: const Center(
                                child: Icon(Icons.person_add_rounded,
                                    color: AppColors.kPrimary, size: 32),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Center(
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                color: AppColors.kTextDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Center(
                            child: Text(
                              'Register to get started',
                              style: TextStyle(
                                color: AppColors.kTextMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          _responsiveRow(
                            isWide,
                            _buildTextField(
                              controller: _nameCtrl,
                              hint: 'Full Name',
                              icon: Icons.person_outline_rounded,
                            ),
                            _buildTextField(
                              controller: _emailCtrl,
                              hint: 'Email-ID',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _responsiveRow(
                            isWide,
                            _buildTextField(
                              controller: _phoneCtrl,
                              hint: 'Phone Number',
                              icon: Icons.call_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            _buildTextField(
                              controller: _passCtrl,
                              hint: 'Password',
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
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _referralCtrl,
                            hint: 'Referral Code (Optional)',
                            icon: Icons.people_outline_rounded,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _register(),
                          ),

                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.kPrimary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.kPrimary.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_user_rounded,
                                    color: AppColors.kPrimary, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'YOUR INFORMATION IS KEPT SAFE AND SECURE',
                                    style: TextStyle(
                                      color: AppColors.kTextDark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
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
                                      'REGISTER NOW',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),

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
                                  style: TextStyle(
                                    color: AppColors.kTextMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                  children: const [
                                    TextSpan(text: 'ALREADY HAVE AN ACCOUNT?  '),
                                    TextSpan(
                                      text: 'LOG IN',
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      enabled: !_loading,
      keyboardType: keyboardType,
      obscureText: obscure,
      textInputAction: textInputAction ?? TextInputAction.next,
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

  Widget _responsiveRow(bool isWide, Widget a, Widget b) {
    if (!isWide) {
      return Column(children: [a, const SizedBox(height: 14), b]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 14),
        Expanded(child: b),
      ],
    );
  }
}