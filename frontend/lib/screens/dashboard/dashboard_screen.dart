import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser!;
    final isCustomer = user.role == UserRole.customer;

    return AppPage(
      title: 'Welcome back, ${user.name.split(' ').first}',
      subtitle: isCustomer ? 'Here is a snapshot of your account.' : 'Organization-wide overview.',
      children: [
        // TODO: replace the static values below with data from the API
        // once the backend is available (e.g. GET /dashboard/summary).
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: isCustomer
              ? const [
                  StatCard(
                    label: 'Active Loan',
                    value: '₹24,500',
                    icon: Icons.account_balance_outlined,
                    color: AppColors.kPrimary,
                  ),
                  StatCard(
                    label: 'Next EMI Due',
                    value: '5 Sep',
                    icon: Icons.event_outlined,
                    color: AppColors.kWarning,
                  ),
                  StatCard(
                    label: 'Paid This Year',
                    value: '₹18,900',
                    icon: Icons.check_circle_outline,
                    color: AppColors.kSuccess,
                  ),
                  StatCard(
                    label: 'Open Tickets',
                    value: '0',
                    icon: Icons.support_agent_outlined,
                    color: AppColors.kInfo,
                  ),
                ]
              : const [
                  StatCard(
                    label: 'Active Members',
                    value: '4',
                    icon: Icons.people_outline,
                    color: AppColors.kSuccess,
                  ),
                  StatCard(
                    label: 'Branches',
                    value: '2',
                    icon: Icons.store_mall_directory_outlined,
                    color: AppColors.kInfo,
                  ),
                  StatCard(
                    label: "Today's Collection",
                    value: '₹2,063',
                    icon: Icons.payments_outlined,
                    color: AppColors.kWarning,
                  ),
                  StatCard(
                    label: 'Total Overdue',
                    value: '₹9,939',
                    icon: Icons.error_outline,
                    color: AppColors.kDanger,
                  ),
                ],
        ),
        const SizedBox(height: 24),
        const Text('Role permissions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        Text(
          "Signed in as ${user.role.label}. Tabs and pages you can't access are "
          'hidden or disabled automatically — try switching demo accounts from '
          'the Profile page.',
          style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
        ),
      ],
    );
  }
}
