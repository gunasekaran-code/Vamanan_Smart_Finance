import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/services/permission_service.dart';
import 'package:frontend/core/services/session_service.dart';

import 'package:frontend/shared/widgets/app_shell.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

import 'package:frontend/features/shared/splash_screen.dart';
import 'package:frontend/features/shared/not_found_screen.dart';
import 'package:frontend/features/shared/unauthorized_screen.dart';

// --- Auth Screens ---
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/auth/recover_key_screen.dart';
import 'package:frontend/features/auth/register_screen.dart';

// --- Screen Imports ---
import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/features/admin/admin_dashboard_screen.dart';
import 'package:frontend/features/admin/profile_screen.dart';
import 'package:frontend/features/admin/customer_screen.dart';
import 'package:frontend/features/admin/support_screen.dart';
import 'package:frontend/features/advocate/agreements_screen.dart';
import 'package:frontend/features/admin/archive_screen.dart';
import 'package:frontend/features/admin/archive_agreements_screen.dart';
import 'package:frontend/features/admin/customer_directory_screen.dart'
    as advocate_customers;
import 'package:frontend/features/advocate/advocate_profile_screen.dart';
import 'package:frontend/features/admin/disputes_screen.dart';
import 'package:frontend/features/admin/rules_screen.dart';
import 'package:frontend/features/advocate/investment_screen.dart';
import 'package:frontend/features/advocate/investment_history_screen.dart';
import 'package:frontend/features/shared/gstr_filing_screen.dart';
import 'package:frontend/features/shared/invoices_screen.dart';
import 'package:frontend/features/shared/asset_inventory_screen.dart';
import 'package:frontend/features/shared/product_requests_screen.dart';
import 'package:frontend/features/shared/cashback_applications_screen.dart';
import 'package:frontend/features/advocate/genealogy_explorer_screen.dart';

import 'package:frontend/features/operations/wallet_list_screen.dart';
import 'package:frontend/features/operations/yield_disbursements_screen.dart';
import 'package:frontend/features/operations/export_payouts_screen.dart';
import 'package:frontend/features/operations/payout_reconciliation_screen.dart';
import 'package:frontend/features/operations/wallet_payout_reports_screen.dart';
import 'package:frontend/features/operations/wallet_adjustment_screen.dart';

import 'package:frontend/features/operations/tally_export_screen.dart';
import 'package:frontend/features/operations/tally_integration_screen.dart';
import 'package:frontend/features/operations/kyc_registry_screen.dart';
import 'package:frontend/features/operations/market_rates_screen.dart';
import 'package:frontend/features/operations/withdrawals_screen.dart';
import 'package:frontend/features/operations/notification_hub_screen.dart';
import 'package:frontend/features/shared/holidays_screen.dart';
import 'package:frontend/features/shared/feedback_remarks_screen.dart';
import 'package:frontend/features/shared/offers_screen.dart';
import 'package:frontend/features/shared/recruitment_screen.dart';

// Report Screens
import 'package:frontend/features/shared/cashback_reports_screen.dart';
import 'package:frontend/features/shared/withdrawal_reports_screen.dart'; 
import 'package:frontend/features/shared/transaction_reports_screen.dart';
import 'package:frontend/features/shared/investment_reports_screen.dart';
import 'package:frontend/features/shared/referral_reports_screen.dart';
import 'package:frontend/features/shared/payout_reports_screen.dart';

// Manager Screens
import 'package:frontend/features/manager/manager_dashboard_screen.dart';
import 'package:frontend/features/manager/identity_verification_screen.dart';
import 'package:frontend/features/manager/product_requests_screen_manager.dart';
import 'package:frontend/features/manager/cashback_monitoring_screen.dart';
import 'package:frontend/features/manager/staff_infrastructure_screen.dart';
import 'package:frontend/features/manager/withdraw_liquidity_screen.dart';


// Advocate Screens
import 'package:frontend/features/advocate/advocator_dashboard_screen.dart';
import 'package:frontend/features/advocate/purchase_verification_page.dart';


// Auditor Screens
import 'package:frontend/features/auditor/auditor_profile_screen.dart';
import 'package:frontend/features/auditor/auditor_agreement_screen.dart';
import 'package:frontend/features/auditor/auditor_kyc_screen.dart';
import 'package:frontend/features/auditor/auditor_rules_screen.dart';
import 'package:frontend/features/auditor/auditor_wallet_screen.dart';
import 'package:frontend/features/auditor/auditor_wallet_transaction_screen.dart';
import 'package:frontend/features/auditor/auditor_wallet_withdraw_screen.dart';
import 'package:frontend/features/auditor/auditor_referral_screen.dart';
import 'package:frontend/features/auditor/auditor_cashback_application_screen.dart';
import 'package:frontend/features/auditor/auditor_cashback_screen.dart';
import 'package:frontend/features/auditor/auditor_request_screen.dart';
import 'package:frontend/features/auditor/auditor_buy_screen.dart';
import 'package:frontend/features/auditor/auditor_dashboard_screen.dart';




import 'package:frontend/features/shared/users_directory_screen.dart';
import 'package:frontend/features/shared/settings_page.dart';

import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: ToastService.navigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: SessionService.instance,
    redirect: _redirect,
    routes: [
      // Root & Auth Routes
      GoRoute(path: AppRoutes.root, redirect: (_, __) => AppRoutes.splash),
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.recoverKey, builder: (_, __) => const RecoverKeyScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: AppRoutes.unauthorized,
        builder: (_, __) => const UnauthorizedScreen(),
      ),

      // Application Shell ShellRoute/StatefulShellRoute
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
        
          // ============================================================
          // AUDITOR SECTION
          // ============================================================
           StatefulShellBranch(routes: [
            GoRoute(
              path: '/auditor-profile',
              builder: (_, __) => const AuditorProfileScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/auditor-agreements',
              builder: (_, __) => const AuditorAgreementScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/auditor-kyc',
              builder: (_, __) => const AuditorKycScreen(),
            ),
          ]),
          // AuditorRulesScreen
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/auditor-rules',
              builder: (_, __) => const AuditorRulesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/auditor-wallets',
              builder: (_, __) => const AuditorWalletScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/auditor-transaction',
              builder: (_, __) => const AuditorWalletTransactionScreen(),
            ),
          ]),
          //
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/auditor-withdrawals',
              builder: (_, __) => const AuditorWalletWithdrawScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/auditor-referral',
              builder: (_, __) => const AuditorReferralScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/auditor-cashback-application',
              builder: (_, __) => const AuditorCashbackApplicationScreen(),
            ),
          ]),
           StatefulShellBranch(routes: [
            GoRoute(
              path: '/auditor-cashback',
              builder: (_, __) => const AuditorCashbackScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/auditor-request',
              builder: (_, __) => const AuditorRequestScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/auditor-buy',
              builder: (_, __) => const AuditorBuyScreen(),
            ),
          ]),









          // ============================================================
          // ADVOCATE SECTION
          // ============================================================
           StatefulShellBranch(routes: [
            GoRoute(
              path: '/purchase-verification',
              builder: (_, __) => const PurchaseVerificationPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/agreements',
              builder: (_, __) => const AgreementsScreen(),
            ),
          ]),
        



          // ============================================================
          // MANAGEMENT SECTION
          // ============================================================
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) {
                switch (SessionService.instance.currentUser?.role) {
                  case UserRole.manager:
                    return const ManagerDashboardScreen();
                  case UserRole.advocate:
                    return const AdvocatorDashboardScreen();
                    case UserRole.auditor:
                    return const AuditorDashboardScreen();
                  default:
                    return const DashboardScreen();
                }
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, __) {
                switch (SessionService.instance.currentUser?.role) {
                  case UserRole.advocate:
                    return const AdvocateProfileScreen();
                  default:
                    return const ProfileScreen();
                }
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.customers,
              builder: (_, __) {
                switch (SessionService.instance.currentUser?.role) {
                  case UserRole.advocate:
                    return const advocate_customers.CustomerDirectoryScreen();
                  default:
                    return const CustomerDirectoryScreen();
                }
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.support,
              builder: (_, __) => const SupportScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.archive,
              builder: (_, __) {
                switch (SessionService.instance.currentUser?.role) {
                  case UserRole.advocate:
                    return const ArchiveAgreementsScreen();
                  default:
                    return const ArchiveScreen();
                }
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.disputes,
              builder: (_, __) => const DisputesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.rules,
              builder: (_, __) => const RulesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/purchases',
              builder: (_, __) => const InvestmentsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/purchase-history',
              builder: (_, __) => const InvestmentHistoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/gstr',
              builder: (_, __) => const GstrFilingScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/invoices',
              builder: (_, __) => const InvoicesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/asset-inventory',
              builder: (_, __) => const AssetInventoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/product-requests',
              builder: (_, __) => const ProductRequestsScreen(),
            ),
          ]),
           StatefulShellBranch(routes: [
            GoRoute(
              path: '/product-requests-manager',
              builder: (_, __) => const ProductRequestsScreenManager(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/cashback-applications',
              builder: (_, __) => const CashbackApplicationsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/cashback-Monitoring',
              builder: (_, __) => const CashbackMonitoringScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/users',
              builder: (_, __) => const UsersDirectoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/genealogy',
              builder: (_, __) => const GenealogyExplorerScreen(),
            ),
          ]),

          // ============================================================
          // OPERATIONS SECTION
          // ============================================================
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/wallets',
              builder: (_, __) => const WalletListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/cashback-payouts',
              builder: (_, __) => const YieldDisbursementsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/export-payout-excel',
              builder: (_, __) => const ExportPayoutsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/payout-reconciliation',
              builder: (_, __) => const PayoutReconciliationScreen(),
            ),
          ]),

          StatefulShellBranch(routes: [
            GoRoute(
              path: '/wallet-payout-reports',
              builder: (_, __) => const WalletPayoutReportsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/wallet-adjustment',
              builder: (_, __) => const WalletAdjustmentScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tally-export',
              builder: (_, __) => const TallyExportScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tally-integration',
              builder: (_, __) => const TallyIntegrationScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/kyc',
              builder: (_, __) => const KycRegistryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/identity-verification',
              builder: (_, __) => const IdentityVerificationScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/market-rates',
              builder: (_, __) => const MarketRatesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/withdrawals',
              builder: (_, __) => const WithdrawalsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/withdrawals-liquidity',
              builder: (_, __) => const WithdrawLiquidityScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/notifications',
              builder: (_, __) => const NotificationHubScreen(),
            ),
          ]),

          StatefulShellBranch(routes: [
            GoRoute(
              path: '/reports',
              builder: (_, __) => const PayoutReportsScreen(),
            ),
          ]),



          // ============================================================
          // REPORTS SECTION
          // ============================================================
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/cashback-reports',
              builder: (_, __) =>
                  const CashbackReportsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/withdrawal-reports',
              builder: (_, __) =>
                  const WithdrawalReportsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/transaction-reports',
              builder: (_, __) =>
                  const TransactionReportsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/investment-reports',
              builder: (_, __) =>
                  const InvestmentReportsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/referral-reports',
              builder: (_, __) =>
                  const ReferralReportsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/payout-reports',
              builder: (_, __) =>
                  const PayoutReportsScreen(),
            ),
          ]),

          // ============================================================
          // SYSTEM SECTION
          // ============================================================
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/holiday-calendar',
              builder: (_, __) => const HolidaysScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/feedback',
              builder: (_, __) => const FeedbackRemarksScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/offers',
              builder: (_, __) => const OffersScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/add-staff',
              builder: (_, __) => const RecruitmentScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/add-staff-manager',
              builder: (_, __) => const StaffInfrastructureScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (_, __) => const SystemSettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (_, __) => const NotFoundScreen(),
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final loggedIn = SessionService.instance.isLoggedIn;
    final path = state.matchedLocation;

    if (path == AppRoutes.splash) return null;

    final isPublic = path == AppRoutes.login ||
      path == AppRoutes.recoverKey ||
      path == AppRoutes.register ||
      path == AppRoutes.unauthorized;

    if (!loggedIn) {
      return isPublic ? null : AppRoutes.login;
    }

    final role = SessionService.instance.currentUser!.role;

    if (path == AppRoutes.login) {
      return PermissionService.landingRouteFor(role);
    }

    if (path != AppRoutes.unauthorized &&
        !PermissionService.canAccess(path, role)) {
      return AppRoutes.unauthorized;
    }

    return null;
  }
}

/// Fallback widget for routes currently pending dedicated screen implementation.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title Page',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
