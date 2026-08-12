import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../services/permission_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController(text: 'demo');
  bool _loading = false;
  String? _error;

  static const _demoUsers = ['superadmin', 'admin', 'staff', 'customer'];

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit([String? presetUsername]) async {
    final username = presetUsername ?? _userCtrl.text;
    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await SessionService.instance.login(username: username, password: _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (!ok) {
      setState(() => _error = 'Unknown user — try one of the demo accounts below.');
      return;
    }
    context.go(PermissionService.landingRouteFor(SessionService.instance.currentUser!.role));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.account_balance, color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        color: AppColors.kTextDark,
                      ),
                      children: [
                        TextSpan(text: 'Smart'),
                        TextSpan(text: 'Finance', style: TextStyle(color: AppColors.kPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'UNIFIED MANAGEMENT PORTAL',
                    style: TextStyle(fontSize: 12, letterSpacing: 1, color: AppColors.kTextMuted),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(labelText: 'Username'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.kDanger, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : () => _submit(),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'DEMO ACCOUNTS · frontend only, no backend yet',
                      style: TextStyle(fontSize: 11, color: AppColors.kTextMuted, letterSpacing: 0.4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final u in _demoUsers)
                        OutlinedButton(
                          onPressed: _loading ? null : () => _submit(u),
                          child: Text(u),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
