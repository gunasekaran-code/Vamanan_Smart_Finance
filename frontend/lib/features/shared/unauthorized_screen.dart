import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/routing/app_routes.dart';
import 'package:frontend/core/services/permission_service.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/theme/app_theme.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 56, color: AppColors.kDanger),
              const SizedBox(height: 16),
              const Text(
                'Access Restricted',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                user == null
                    ? 'Please sign in to continue.'
                    : "Your role (${user.role.label}) doesn't have access to that page.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.kTextMuted),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (user == null) {
                    context.go(AppRoutes.login);
                  } else {
                    context.go(PermissionService.landingRouteFor(user.role));
                  }
                },
                child: const Text('Back to safety'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
