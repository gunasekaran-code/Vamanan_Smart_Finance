import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_routes.dart';
import '../services/permission_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await SessionService.instance.restoreFromStorage();
    if (!mounted) return;

    final user = SessionService.instance.currentUser;
    if (user == null) {
      context.go(AppRoutes.login);
    } else {
      context.go(PermissionService.landingRouteFor(user.role));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.kBackground,
      body: Center(child: CircularProgressIndicator(color: AppColors.kPrimary)),
    );
  }
}
