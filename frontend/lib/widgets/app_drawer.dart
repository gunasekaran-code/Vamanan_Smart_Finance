import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/user_role.dart';
import '../routes/app_routes.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final UserRole role;

  const AppDrawer({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Drawer(
      width: 300,
      backgroundColor: AppColors.kSurface,
      child: SafeArea(
        child: Column(
          children: [
            // ============================================================
            // HEADER
            // ============================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SmartFinance',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kTextDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.kTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
              color: AppColors.kBorder,
            ),

            // ============================================================
            // MENU
            // ============================================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                children: [
                  // ========================================================
                  // MAIN
                  // ========================================================
                  _sectionTitle(''),

                  _menuItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: AppRoutes.dashboard,
                    currentPath: currentPath,
                  ),

                  // ========================================================
                  // MANAGEMENT
                  // ========================================================
                  _sectionTitle('MANAGEMENT'),

                  _menuItem(
                    context,
                    icon: Icons.people_outline,
                    label: 'Members',
                    route: AppRoutes.members,
                    currentPath: currentPath,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Payments',
                    route: AppRoutes.payments,
                    currentPath: currentPath,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.payments_outlined,
                    label: 'Field Collection',
                    route: AppRoutes.fieldCollection,
                    currentPath: currentPath,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Daily Collection Report',
                    route: AppRoutes.dailyCollectionReport,
                    currentPath: currentPath,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.verified_user_outlined,
                    label: 'KYC & Compliance',
                    route: AppRoutes.kycCompliance,
                    currentPath: currentPath,
                  ),

                  // ========================================================
                  // CHIT OPERATIONS
                  // ========================================================
                  _sectionTitle('CHIT OPERATIONS'),

                  _menuItem(
                    context,
                    icon: Icons.folder_outlined,
                    label: 'Chits',
                    route: AppRoutes.chits,
                    currentPath: currentPath,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.gavel_outlined,
                    label: 'Auctions',
                    route: AppRoutes.auctions,
                    currentPath: currentPath,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.check_circle_outline,
                    label: 'Settlements',
                    route: AppRoutes.settlements,
                    currentPath: currentPath,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.inventory_2_outlined,
                    label: 'Branch Handovers',
                    route: AppRoutes.branchHandovers,
                    currentPath: currentPath,
                    iconColor: AppColors.kDanger,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.verified_outlined,
                    label: 'Payment Verifications',
                    route: AppRoutes.paymentVerifications,
                    currentPath: currentPath,
                    iconColor: AppColors.kInfo,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.description_outlined,
                    label: 'Reports',
                    route: AppRoutes.reports,
                    currentPath: currentPath,
                  ),

                  // ========================================================
                  // LOAN MODULE
                  // ========================================================
                  _sectionTitle('LOAN MODULE'),

                  _menuItem(
                    context,
                    icon: Icons.speed_outlined,
                    label: 'Loan Dashboard',
                    route: AppRoutes.loanDashboard,
                    currentPath: currentPath,
                    iconColor: AppColors.kInfo,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.description_outlined,
                    label: 'Loans',
                    route: AppRoutes.loans,
                    currentPath: currentPath,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.people_alt_outlined,
                    label: 'Loan Customers',
                    route: AppRoutes.loanCustomers,
                    currentPath: currentPath,
                    iconColor: AppColors.kInfo,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.payments_outlined,
                    label: 'EMI Collections',
                    route: AppRoutes.emiCollections,
                    currentPath: currentPath,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.warning_amber_rounded,
                    label: 'Overdue EMIs',
                    route: AppRoutes.overdueEmis,
                    currentPath: currentPath,
                    iconColor: AppColors.kDanger,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.verified_outlined,
                    label: 'Loan Verifications',
                    route: AppRoutes.loanVerifications,
                    currentPath: currentPath,
                    iconColor: AppColors.kInfo,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.bar_chart_outlined,
                    label: 'Loan Reports',
                    route: AppRoutes.loanReports,
                    currentPath: currentPath,
                  ),

                  // ========================================================
                  // SYSTEM ENGINE
                  // ========================================================
                  _sectionTitle('SYSTEM ENGINE'),

                  _menuItem(
                    context,
                    icon: Icons.business_outlined,
                    label: 'Branches',
                    route: AppRoutes.branches,
                    currentPath: currentPath,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.analytics_outlined,
                    label: 'Analytics',
                    route: AppRoutes.analytics,
                    currentPath: currentPath,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.campaign_outlined,
                    label: 'Broadcast Hub',
                    route: AppRoutes.broadcastHub,
                    currentPath: currentPath,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.person_outline,
                    label: 'User Manager',
                    route: AppRoutes.userManager,
                    currentPath: currentPath,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.tune_outlined,
                    label: 'Engine Settings',
                    route: AppRoutes.engineSettings,
                    currentPath: currentPath,
                  ),

                  _menuItem(
                    context,
                    icon: Icons.shield_outlined,
                    label: 'Audit Controls',
                    route: AppRoutes.auditControls,
                    currentPath: currentPath,
                  ),
                ],
              ),
            ),

            // ============================================================
            // SIGN OUT
            // ============================================================
            const Divider(
              height: 1,
              color: AppColors.kBorder,
            ),

            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              leading: const Icon(
                Icons.logout_outlined,
                color: AppColors.kDanger,
                size: 20,
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: AppColors.kDanger,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();

                SessionService.instance.logout();

                context.go(AppRoutes.login);
              },
            ),

            if (user != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Signed in as ${user.email}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.kTextMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // SECTION TITLE
  // ========================================================================

  Widget _sectionTitle(String title) {
    if (title.isEmpty) {
      return const SizedBox(height: 4);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 7),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: AppColors.kTextMuted,
        ),
      ),
    );
  }

  // ========================================================================
  // MENU ITEM
  // ========================================================================

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required String currentPath,
    Color? iconColor,
  }) {
    final selected =
        currentPath == route ||
        (route != AppRoutes.dashboard &&
            currentPath.startsWith('$route/'));

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.kPrimaryLight
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        minVerticalPadding: 7,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 1,
        ),
        leading: Icon(
          icon,
          size: 19,
          color: selected
              ? AppColors.kPrimary
              : (iconColor ?? AppColors.kTextMuted),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected
                ? AppColors.kPrimary
                : AppColors.kTextDark,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          context.go(route);
        },
      ),
    );
  }
}
