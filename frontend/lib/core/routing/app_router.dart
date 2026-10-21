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
import 'package:frontend/features/manager/manager_profile_screen.dart';
import 'package:frontend/features/manager/manager_customer_screen.dart';
import 'package:frontend/features/manager/support_screen.dart';
import 'package:frontend/features/advocate/agreements_screen.dart';
import 'package:frontend/features/admin/archive_screen.dart';
import 'package:frontend/features/advocate/advocate_archive_screen.dart';
import 'package:frontend/features/advocate/agreement_verification_screen.dart';
import 'package:frontend/models/advocate_archive_model.dart';
import 'package:frontend/features/advocate/advocate_customer_screen.dart'
    as advocate_customers;
import 'package:frontend/features/advocate/advocate_profile_screen.dart';
import 'package:frontend/features/advocate/advocate_disputes_screen.dart';
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
import 'package:frontend/features/manager/manager_product_requests_screen.dart';
import 'package:frontend/features/manager/cashback_monitoring_screen.dart';
import 'package:frontend/features/manager/staff_add_screen.dart';
import 'package:frontend/features/manager/withdraw_liquidity_screen.dart';

// Advocate Screens
import 'package:frontend/features/advocate/advocate_dashboard_screen.dart';
import 'package:frontend/features/advocate/advocate_purchase_screen.dart';

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
import 'package:frontend/features/auditor/auditor_cart_screen.dart';
import 'package:frontend/features/shared/asset_movement_history_screen.dart';
import 'package:frontend/features/shared/asset_form_screen.dart';
import 'package:frontend/models/asset_model.dart';
import 'package:frontend/services/cart_service.dart';
import 'package:frontend/features/auditor/auditor_dashboard_screen.dart';
import 'package:frontend/features/customer/customer_cashback_screen.dart';
import 'package:frontend/features/customer/customer_dashboard_screen.dart';
import 'package:frontend/features/customer/customer_profile_screen.dart';

import 'package:frontend/features/shared/users_directory_screen.dart';
import 'package:frontend/features/shared/user_profile_screen.dart';
import 'package:frontend/models/admin_user_model.dart';
import 'package:frontend/features/shared/settings_page.dart';

import 'package:frontend/shared/widgets/shell_navigation_observer.dart';
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
      GoRoute(
          path: AppRoutes.recoverKey,
          builder: (_, __) => const RecoverKeyScreen()),
      GoRoute(
          path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
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
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/auditor-profile',
              builder: (_, __) {
                final userId = int.tryParse(
                  SessionService.instance.currentUser?.id ?? '',
                );
                return userId == null
                    ? const UnauthorizedScreen()
                    : AuditorProfileScreen(userId: userId);
              },
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/auditor-agreements',
              builder: (_, __) {
                final userId = SessionService.instance.currentUser?.id;
                if (userId == null || userId.isEmpty) {
                  return const UnauthorizedScreen();
                }
                return AuditorAgreementScreen(userId: userId);
              },
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/auditor-kyc',
              builder: (_, __) {
                final userId = SessionService.instance.currentUser?.id;
                if (userId == null || userId.isEmpty) {
                  return const UnauthorizedScreen();
                }
                return AuditorKycScreen(userId: userId);
              },
            ),
          ]),
          // AuditorRulesScreen
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/auditor-rules',
              builder: (_, __) => const AuditorRulesScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/auditor-wallets',
              builder: (_, __) {
                final userId = SessionService.instance.currentUser?.id;
                return userId == null || userId.isEmpty
                    ? const UnauthorizedScreen()
                    : AuditorWalletScreen(userId: userId);
              },
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/auditor-transaction',
              builder: (_, __) {
                final userId = SessionService.instance.currentUser?.id;
                return userId == null || userId.isEmpty
                    ? const UnauthorizedScreen()
                    : AuditorWalletTransactionScreen(userId: userId);
              },
            ),
          ]),
          //
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/auditor-withdrawals',
              builder: (_, __) {
                final userId = SessionService.instance.currentUser?.id;
                return userId == null || userId.isEmpty
                    ? const UnauthorizedScreen()
                    : AuditorWalletWithdrawScreen(userId: userId);
              },
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/auditor-referral',
              builder: (_, __) {
                final userId = SessionService.instance.currentUser?.id;
                if (userId == null || userId.isEmpty) {
                  return const UnauthorizedScreen();
                }
                return AuditorReferralScreen(userId: userId);
              },
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              // IMPORTANT: Ensure this path matches the one you are pushing.
              // Your screenshot shows '/auditor-cashback'. If that's what you are
              // using to navigate, change the line below to: path: '/auditor-cashback',
              path: '/auditor-cashback-application',
              builder: (_, __) {
                final user = SessionService.instance.currentUser;
                final userId = int.tryParse(user?.id ?? '');

                if (userId == null) {
                  return const UnauthorizedScreen();
                }

                return AuditorCashbackApplicationScreen(userId: userId);
              },
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/auditor-cashback',
              builder: (_, __) {
                final user = SessionService.instance.currentUser;
                // auditor/ledger.php only filters by user when `user_id` is
                // sent; with it omitted the reply carries every account's
                // transactions, names and customer ids. An auditor audits the
                // whole platform, so they get the unfiltered view — a
                // customer must only ever see their own rows.
                final scopedId = user?.role == UserRole.customer
                    ? int.tryParse(user?.id ?? '')
                    : null;
                return AuditorCashbackScreen(userId: scopedId);
              },
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: AppRoutes.customerCashback,
              builder: (_, __) {
                final user = SessionService.instance.currentUser;
                return user?.role == UserRole.customer
                    ? const CustomerCashbackScreen()
                    : const UnauthorizedScreen();
              },
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/auditor-request',
              builder: (_, __) => const AuditorRequestScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/auditor-buy',
              builder: (_, __) => const AuditorBuyScreen(),
              routes: [
                GoRoute(
                  path: 'cart',
                  builder: (_, __) => CartService.isAvailableFor(
                          SessionService.instance.currentUser?.role)
                      ? const AuditorCartScreen()
                      : const UnauthorizedScreen(),
                ),
              ],
            ),
          ]),

          // ============================================================
          // ADVOCATE SECTION
          // ============================================================
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/purchase-verification',
              builder: (_, __) => const PurchaseVerificationPage(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/agreements',
              builder: (_, __) => const AgreementsScreen(),
            ),
          ]),

          // ============================================================
          // MANAGEMENT SECTION
          // ============================================================
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
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
                  // Not AuditorDashboardScreen: that one reads
                  // auditor/summary.php, which reports platform-wide revenue,
                  // GST and wallet liability. Customers get the per-user
                  // customer/dashboard.php instead.
                  case UserRole.customer:
                    return const CustomerDashboardScreen();
                  default:
                    return const DashboardScreen();
                }
              },
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, __) {
                switch (SessionService.instance.currentUser?.role) {
                  case UserRole.advocate:
                    return const AdvocateProfileScreen();
                  case UserRole.customer:
                    return const CustomerProfileScreen();
                  default:
                    return const ManagerProfileScreen();
                }
              },
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
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
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: AppRoutes.support,
              builder: (_, __) => const SupportScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
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
              routes: [
                GoRoute(
                  path: 'agreement',
                  // Shares the archive's permission; a missing/invalid id
                  // (e.g. a hand-typed URL) falls back to the list.
                  redirect: (_, state) {
                    final role = SessionService.instance.currentUser?.role;
                    if (role == null ||
                        !PermissionService.canAccess(AppRoutes.archive, role)) {
                      return AppRoutes.unauthorized;
                    }
                    return int.tryParse(
                                state.uri.queryParameters['id'] ?? '') ==
                            null
                        ? AppRoutes.archive
                        : null;
                  },
                  // The tapped row rides along as `extra` for an instant
                  // first paint; the screen re-reads it from the backend,
                  // which also covers a browser refresh (extra is dropped).
                  builder: (_, state) => AgreementVerificationScreen(
                    agreementId: int.parse(state.uri.queryParameters['id']!),
                    initial: state.extra is AgreementArchiveItem
                        ? state.extra as AgreementArchiveItem
                        : null,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: AppRoutes.disputes,
              builder: (_, __) => const DisputesScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: AppRoutes.rules,
              builder: (_, __) => const RulesScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/purchases',
              builder: (_, __) => const InvestmentsScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/purchase-history',
              builder: (_, __) => const InvestmentHistoryScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/gstr',
              builder: (_, __) => const GstrFilingScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/invoices',
              builder: (_, __) => const InvoicesScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/asset-inventory',
              builder: (_, __) => const AssetInventoryScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (_, __) => _canManageAssets()
                      ? const AssetFormScreen()
                      : const UnauthorizedScreen(),
                ),
                GoRoute(
                  path: 'edit',
                  // The asset travels as `extra`, which a browser refresh drops.
                  redirect: (_, state) =>
                      state.extra is Asset ? null : '/asset-inventory',
                  builder: (_, state) => _canManageAssets()
                      ? AssetFormScreen(asset: state.extra as Asset)
                      : const UnauthorizedScreen(),
                ),
                GoRoute(
                  path: 'history',
                  redirect: (_, state) =>
                      int.tryParse(state.uri.queryParameters['id'] ?? '') ==
                              null
                          ? '/asset-inventory'
                          : null,
                  builder: (_, state) => _canManageAssets()
                      ? AssetMovementHistoryScreen(
                          productId:
                              int.parse(state.uri.queryParameters['id']!),
                          productName: state.uri.queryParameters['name'] ?? '',
                        )
                      : const UnauthorizedScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/product-requests',
              builder: (_, __) => const ProductRequestsScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/product-requests-manager',
              builder: (_, __) => const ProductRequestsScreenManager(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/cashback-applications',
              builder: (_, __) => const CashbackApplicationsScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/cashback-Monitoring',
              builder: (_, __) => const CashbackMonitoringScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/users',
              builder: (_, __) => const UsersDirectoryScreen(),
              routes: [
                GoRoute(
                  path: 'profile',
                  // Child routes aren't role-gated by the menu, so reuse the
                  // directory's own permission check.
                  redirect: (_, state) {
                    final role = SessionService.instance.currentUser?.role;
                    if (role == null ||
                        !PermissionService.canAccess('/users', role)) {
                      return AppRoutes.unauthorized;
                    }
                    return int.tryParse(
                                state.uri.queryParameters['id'] ?? '') ==
                            null
                        ? '/users'
                        : null;
                  },
                  builder: (_, state) => UserProfileScreen(
                    userId: int.parse(state.uri.queryParameters['id']!),
                    initialUser: state.extra is AdminUserModel
                        ? state.extra as AdminUserModel
                        : null,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/genealogy',
              builder: (_, __) => const GenealogyExplorerScreen(),
            ),
          ]),

          // ============================================================
          // OPERATIONS SECTION
          // ============================================================
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/wallets',
              builder: (_, __) => const WalletListScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/cashback-payouts',
              builder: (_, __) => const YieldDisbursementsScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/export-payout-excel',
              builder: (_, __) => const ExportPayoutsScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/payout-reconciliation',
              builder: (_, __) => const PayoutReconciliationScreen(),
            ),
          ]),

          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/wallet-payout-reports',
              builder: (_, __) => const WalletPayoutReportsScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/wallet-adjustment',
              builder: (_, __) => const WalletAdjustmentScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/tally-export',
              builder: (_, __) => const TallyExportScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/tally-integration',
              builder: (_, __) => const TallyIntegrationScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/kyc',
              builder: (_, __) => const KycRegistryScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/identity-verification',
              builder: (_, __) => const IdentityVerificationScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/market-rates',
              builder: (_, __) => const MarketRatesScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/withdrawals',
              builder: (_, __) => const WithdrawalsScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/withdrawals-liquidity',
              builder: (_, __) => const WithdrawLiquidityScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/notifications',
              builder: (_, __) => const NotificationHubScreen(),
            ),
          ]),

          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/reports',
              builder: (_, __) => const PayoutReportsScreen(),
            ),
          ]),

          // ============================================================
          // REPORTS SECTION
          // ============================================================
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/cashback-reports',
              builder: (_, __) => const CashbackReportsScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/withdrawal-reports',
              builder: (_, __) => const WithdrawalReportsScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/transaction-reports',
              builder: (_, __) => const TransactionReportsScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/investment-reports',
              builder: (_, __) => const InvestmentReportsScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/referral-reports',
              builder: (_, __) => const ReferralReportsScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/payout-reports',
              builder: (_, __) => const PayoutReportsScreen(),
            ),
          ]),

          // ============================================================
          // SYSTEM SECTION
          // ============================================================
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/holiday-calendar',
              builder: (_, __) => const HolidaysScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/feedback',
              builder: (_, __) => const FeedbackRemarksScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/offers',
              builder: (_, __) => const OffersScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/add-staff',
              builder: (_, __) => const RecruitmentScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
            GoRoute(
              path: '/add-staff-manager',
              builder: (_, __) => const StaffInfrastructureScreen(),
            ),
          ]),
          StatefulShellBranch(observers: [
            ShellNavigationObserver()
          ], routes: [
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

  /// Sub-pages of `/asset-inventory` share its permission.
  static bool _canManageAssets() => PermissionService.canAccess(
      '/asset-inventory', SessionService.instance.currentUser!.role);

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
