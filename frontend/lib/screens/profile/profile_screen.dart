import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_role.dart';
import '../../routes/app_routes.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser!;

    return AppPage(
      title: 'My Profile',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.kPrimary,
                child: Text(
                  user.initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(user.email, style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.role.label,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Switch demo role', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
          'Frontend-only helper for exercising RBAC — remove once real '
          'authentication is wired up.',
          style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final role in UserRole.values)
              ChoiceChip(
                label: Text(role.label),
                selected: user.role == role,
                onSelected: (_) {
                  // Re-logs in as the matching demo account. GoRouter's
                  // refreshListenable picks up the change and re-runs
                  // the RBAC redirect automatically, so if the current
                  // page isn't allowed for the new role you'll be
                  // routed away right after switching.
                  SessionService.instance.login(username: role.apiValue.toLowerCase(), password: 'demo');
                },
              ),
          ],
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.kDanger,
              side: const BorderSide(color: AppColors.kDanger),
            ),
            onPressed: () {
              SessionService.instance.logout();
              context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ),
      ],
    );
  }
}
