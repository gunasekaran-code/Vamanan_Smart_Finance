class AppRoutes {
  AppRoutes._();

  // GENERAL

  static const String root = '/';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String recoverKey = '/recover-key';
  static const String register = '/register';
  static const String unauthorized = '/unauthorized';

  // MANAGEMENT

  static const String dashboard = '/dashboard';
  static const String verify = '/verify';
  static const String security = '/security';
  static const String members = '/members';
  static const String payments = '/payments';
  static const String fieldCollection = '/field-collection';
  static const String dailyCollectionReport = '/daily-collection-report';
  static const String kycCompliance = '/kyc-compliance';
  static const String IdentityVerification = '/identity-verification';

  // CHIT OPERATIONS

  static const String chits = '/chits';
  static const String golddash = 'GoldDash';
  static const String auctions = '/auctions';
  static const String settlements = '/settlements';
  static const String branchHandovers = '/branch-handovers';
  static const String paymentVerifications = '/payment-verifications';
  static const String reports = '/reports';

  // LOAN MODULE

  static const String loanDashboard = '/loan-dashboard';
  static const String loans = '/loans';
  static const String loanCustomers = '/loan-customers';
  static const String emiCollections = '/emi-collections';
  static const String overdueEmis = '/overdue-emis';
  static const String loanVerifications = '/loan-verifications';
  static const String loanReports = '/loan-reports';

  // SYSTEM ENGINE

  static const String branches = '/branches';
  static const String analytics = '/analytics';
  static const String broadcastHub = '/broadcast-hub';
  static const String userManager = '/user-manager';
  static const String settings = '/settings';
  static const String auditControls = '/audit-controls';
  static const String notifications = '/notifications';
  static const String logs = '/recoverKey';

  // Existing profile
  static const String profile = '/profile';
  static const String customers = '/customers';
  static const String support = '/support';
  static const String agreements = '/agreements';
  static const String archive = '/archive';
  static const String disputes = '/disputes';
  static const String rules = '/rules';


  static const String auditorBuy = '/auditor-buy';
  static const String auditorCashback = '/auditor-cashback';
  static const String auditorKyc = '/auditor-kyc';


  /// The route paths of every `StatefulShellBranch` in `AppRouter.router`,
  /// in the exact order they're declared there. A branch's index in this
  /// list is what `StatefulNavigationShell.goBranch(index)` expects — it's
  /// a *position*, not something tied to any one role's menu order — so
  /// any nav UI that jumps to a branch (e.g. `AppBottomNav`) resolves its
  /// target route through this list rather than guessing an index.
  ///
  /// Keep this in sync whenever a branch is added, removed, or reordered
  /// in app_router.dart.
  static const List<String> shellBranchOrder = [
    // AUDITOR SECTION
    '/auditor-profile',
    '/auditor-agreements',
    auditorKyc,
    '/auditor-rules',
    '/auditor-wallets',
    '/auditor-transaction',
    '/auditor-withdrawals',
    '/auditor-referral',
    '/auditor-cashback-application',
    auditorCashback,
    '/auditor-request',
    auditorBuy,
    // ADVOCATE SECTION
    '/purchase-verification',
    agreements,
    // MANAGEMENT SECTION
    dashboard,
    profile,
    customers,
    support,
    archive,
    disputes,
    rules,
    '/purchases',
    '/purchase-history',
    '/gstr',
    '/invoices',
    '/asset-inventory',
    '/product-requests',
    '/product-requests-manager',
    '/cashback-applications',
    '/cashback-Monitoring',
    '/users',
    '/genealogy',
    // OPERATIONS SECTION
    '/wallets',
    '/cashback-payouts',
    '/export-payout-excel',
    '/payout-reconciliation',
    '/wallet-payout-reports',
    '/wallet-adjustment',
    '/tally-export',
    '/tally-integration',
    '/kyc',
    '/identity-verification',
    '/market-rates',
    '/withdrawals',
    '/withdrawals-liquidity',
    '/notifications',
    reports,
    // REPORTS SECTION
    '/cashback-reports',
    '/withdrawal-reports',
    '/transaction-reports',
    '/investment-reports',
    '/referral-reports',
    '/payout-reports',
    // SYSTEM SECTION
    '/holiday-calendar',
    '/feedback',
    '/offers',
    '/add-staff',
    '/add-staff-manager',
    settings,
  ];
}
