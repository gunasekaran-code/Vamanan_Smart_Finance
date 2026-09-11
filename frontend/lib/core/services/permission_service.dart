import 'package:flutter/material.dart';

import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/core/routing/app_routes.dart';

/// One tappable destination in the bottom navigation bar.
class NavEntry {
  final String route;
  final String label;
  final IconData icon;

  const NavEntry({
    required this.route,
    required this.label,
    required this.icon,
  });
}

class MenuItemDef {
  final String label;
  final IconData icon;
  final String route;
  final List<MenuItemDef> children;

  const MenuItemDef({
    required this.label,
    required this.icon,
    this.route = '',
    this.children = const [],
  });

  bool get isExpandable => children.isNotEmpty;

  Iterable<String> get allRoutes sync* {
    if (route.isNotEmpty) yield route;
    for (final child in children) {
      yield* child.allRoutes;
    }
  }
}

class MenuSectionDef {
  final String heading;
  final List<MenuItemDef> items;

  const MenuSectionDef(this.heading, this.items);
}

class PermissionService {
  PermissionService._();

  // ==========================================================================
  // BOTTOM NAVIGATION — a short, role-specific set of shortcuts to the
  // destinations each role uses most. It intentionally mirrors only a
  // handful of entries from that role's own [menuFor] list (never a route
  // the role can't otherwise reach) — the drawer stays the place for
  // everything else, and Profile/Settings are always one tap away from the
  // avatar menu in [AppHeader], so they don't need a slot here too.
  // ==========================================================================

  static const List<NavEntry> _adminBottomNav = [
    NavEntry(route: AppRoutes.dashboard, label: 'Dashboard', icon: Icons.grid_view_rounded),
    NavEntry(route: '/purchases', label: 'Purchases', icon: Icons.shopping_cart_outlined),
    NavEntry(route: '/wallets', label: 'Wallets', icon: Icons.account_balance_wallet_outlined),
    NavEntry(route: '/users', label: 'Users', icon: Icons.people_outline),
  ];

  static const List<NavEntry> _managerBottomNav = [
    NavEntry(route: AppRoutes.dashboard, label: 'Dashboard', icon: Icons.grid_view_rounded),
    NavEntry(route: AppRoutes.customers, label: 'Customers', icon: Icons.people_outline),
    NavEntry(route: '/product-requests-manager', label: 'Requests', icon: Icons.inventory_outlined),
    NavEntry(route: '/identity-verification', label: 'KYC', icon: Icons.verified_user_outlined),
  ];

  static const List<NavEntry> _staffBottomNav = [
    NavEntry(route: AppRoutes.dashboard, label: 'Dashboard', icon: Icons.grid_view_rounded),
    NavEntry(route: '/purchases', label: 'Purchases', icon: Icons.shopping_cart_outlined),
    NavEntry(route: '/wallets', label: 'Wallets', icon: Icons.account_balance_wallet_outlined),
    NavEntry(route: '/kyc', label: 'KYC', icon: Icons.verified_user_outlined),
  ];

  static const List<NavEntry> _advocateBottomNav = [
    NavEntry(route: AppRoutes.dashboard, label: 'Overview', icon: Icons.grid_view_rounded),
    NavEntry(route: AppRoutes.agreements, label: 'Agreements', icon: Icons.gavel_outlined),
    NavEntry(route: AppRoutes.customers, label: 'Customers', icon: Icons.people_outline),
    NavEntry(route: AppRoutes.disputes, label: 'Disputes', icon: Icons.balance_outlined),
  ];


  static const List<NavEntry> _auditorBottomNav = [                                         
    NavEntry(route: AppRoutes.dashboard, label: 'Dashboard', icon: Icons.grid_view_rounded),
    NavEntry(route: AppRoutes.auditorBuy, label: 'BUY', icon: Icons.shopping_cart_outlined),
    NavEntry(route: AppRoutes.auditorCashback, label: 'Cashback', icon: Icons.payments_outlined),
    NavEntry(route: AppRoutes.auditorKyc, label: 'KYC', icon: Icons.verified_user_outlined),
  ];                                                                                        

  static List<NavEntry> bottomNavFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return _adminBottomNav;
      case UserRole.manager:
        return _managerBottomNav;
      case UserRole.staff:
        return _staffBottomNav;
      case UserRole.advocate:
        return _advocateBottomNav;
      case UserRole.auditor:
        return _auditorBottomNav;
    }
  }


  static const List<MenuSectionDef> _adminMenu = [
    MenuSectionDef('MANAGEMENT', [
      MenuItemDef(label: 'DASHBOARD', icon: Icons.bar_chart_rounded, route: AppRoutes.dashboard),
      MenuItemDef(label: 'PURCHASES', icon: Icons.shopping_cart_outlined, route: '/purchases'),
      MenuItemDef(label: 'PURCHASE HISTORY', icon: Icons.description_outlined, route: '/purchase-history'),
      MenuItemDef(label: 'GSTR FILING (GSTR-1 & 3B)', icon: Icons.receipt_long_outlined, route: '/gstr'),
      MenuItemDef(label: 'INVOICES', icon: Icons.receipt_outlined, route: '/invoices'),
      MenuItemDef(label: 'ASSET INVENTORY', icon: Icons.inventory_2_outlined, route: '/asset-inventory'),
      MenuItemDef(label: 'PRODUCT REQUESTS', icon: Icons.inventory_outlined, route: '/product-requests'),
      MenuItemDef(label: 'CASHBACK APPLICATIONS', icon: Icons.request_quote_outlined, route: '/cashback-applications'),
      MenuItemDef(label: 'USERS', icon: Icons.people_outline, route: '/users'),
      MenuItemDef(label: 'GENEALOGY', icon: Icons.account_tree_outlined, route: '/genealogy'),
    ]),
    MenuSectionDef('OPERATIONS', [
      MenuItemDef(
        label: 'WALLETS',
        icon: Icons.account_balance_wallet_outlined,
        children: [
          MenuItemDef(label: 'WALLET LIST', icon: Icons.list_alt_outlined, route: '/wallets'),
          MenuItemDef(label: 'CASHBACK PAYOUTS', icon: Icons.payments_outlined, route: '/cashback-payouts'),
          MenuItemDef(label: 'EXPORT PAYOUT EXCEL', icon: Icons.file_download_outlined, route: '/export-payout-excel'),
          MenuItemDef(label: 'PAYOUT RECONCILIATION', icon: Icons.compare_arrows_outlined, route: '/payout-reconciliation'),
          MenuItemDef(label: 'PAYOUT REPORTS', icon: Icons.summarize_outlined, route: '/wallet-payout-reports'),
        ],
      ),
      MenuItemDef(label: 'WALLET ADJUSTMENT', icon: Icons.tune_outlined, route: '/wallet-adjustment'),
      MenuItemDef(label: 'TALLY EXPORT', icon: Icons.import_export_outlined, route: '/tally-export'),
      MenuItemDef(label: 'TALLY INTEGRATION', icon: Icons.sync_alt_outlined, route: '/tally-integration'),
      MenuItemDef(label: 'KYC', icon: Icons.verified_user_outlined, route: '/kyc'),
      MenuItemDef(label: 'MARKET RATES', icon: Icons.trending_up_outlined, route: '/market-rates'),
      MenuItemDef(label: 'WITHDRAWALS', icon: Icons.money_off_outlined, route: '/withdrawals'),
      MenuItemDef(label: 'NOTIFICATIONS', icon: Icons.notifications_outlined, route: '/notifications'),
      MenuItemDef(
        label: 'REPORTS',
        icon: Icons.pie_chart_outline,
        children: [
          MenuItemDef(label: 'CASHBACK REPORTS', icon: Icons.analytics_outlined, route: '/cashback-reports'),
          MenuItemDef(label: 'WITHDRAWAL REPORTS', icon: Icons.receipt_long_outlined, route: '/withdrawal-reports'),
          MenuItemDef(label: 'TRANSACTION REPORTS', icon: Icons.swap_horiz_outlined, route: '/transaction-reports'),
          MenuItemDef(label: 'INVESTMENT REPORTS', icon: Icons.insights_outlined, route: '/investment-reports'),
          MenuItemDef(label: 'REFERRAL REPORTS', icon: Icons.group_add_outlined, route: '/referral-reports'),
          MenuItemDef(label: 'PAYOUT REPORTS', icon: Icons.summarize_outlined, route: '/payout-reports'),
        ],
      ),
    ]),
    MenuSectionDef('SYSTEM', [
      MenuItemDef(label: 'HOLIDAY CALENDAR', icon: Icons.calendar_month_outlined, route: '/holiday-calendar'),
      MenuItemDef(label: 'FEEDBACK & REMARKS', icon: Icons.feedback_outlined, route: '/feedback'),
      MenuItemDef(label: 'OFFERS & FESTIVALS', icon: Icons.celebration_outlined, route: '/offers'),
      MenuItemDef(label: 'ADD STAFF', icon: Icons.person_add_outlined, route: '/add-staff'),
      MenuItemDef(label: 'SETTINGS', icon: Icons.settings_outlined, route: AppRoutes.settings),
    ]),
  ];

  static const List<MenuSectionDef> _managerMenu = [
    MenuSectionDef('OPERATIONS', [
      MenuItemDef(label: 'DASHBOARD', icon: Icons.bar_chart_rounded, route: AppRoutes.dashboard),
      MenuItemDef(label: 'CUSTOMERS', icon: Icons.people_outline, route: '/customers'),
      MenuItemDef(label: 'PURCHASE REQUESTS', icon: Icons.inventory_outlined, route: '/product-requests-manager'), //ProductRequestsScreenManager
      MenuItemDef(label: 'MANAGE ASSETS', icon: Icons.inventory_2_outlined, route: '/asset-inventory'),
      MenuItemDef(label: 'KYC VERIFICATION', icon: Icons.verified_user_outlined, route: '/identity-verification'),  //IdentityVerificationScreen
    ]),
    MenuSectionDef('FINANCE', [
      MenuItemDef(label: 'CASHBACK', icon: Icons.request_quote_outlined, route: '/cashback-Monitoring'), //CashbackMonitoringScreen
      MenuItemDef(label: 'WITHDRAWALS', icon: Icons.money_off_outlined, route: '/withdrawals-liquidity'), //WithdrawLiquidityScreen
      MenuItemDef(label: 'SUPPORT TICKETS', icon: Icons.support_agent_outlined, route: '/support'),
    ]),
    MenuSectionDef('SETTINGS', [
      MenuItemDef(label: 'STAFF MANAGEMENT', icon: Icons.badge_outlined, route: '/add-staff-manager'),
      MenuItemDef(label: 'PROFILE', icon: Icons.person_outline_rounded, route: AppRoutes.profile),
    ]),
  ];

  static const List<MenuSectionDef> _staffMenu = [
    MenuSectionDef('MANAGEMENT', [
      MenuItemDef(label: 'DASHBOARD', icon: Icons.bar_chart_rounded, route: AppRoutes.dashboard),
      MenuItemDef(label: 'PURCHASES', icon: Icons.shopping_cart_outlined, route: '/purchases'),
      MenuItemDef(label: 'GSTR FILING (GSTR-1 & 3B)', icon: Icons.receipt_long_outlined, route: '/gstr'),
      MenuItemDef(label: 'INVOICES', icon: Icons.receipt_outlined, route: '/invoices'),
      MenuItemDef(label: 'ASSET INVENTORY', icon: Icons.inventory_2_outlined, route: '/asset-inventory'),
      MenuItemDef(label: 'USERS', icon: Icons.people_outline, route: '/users'),
      MenuItemDef(label: 'GENEALOGY', icon: Icons.account_tree_outlined, route: '/genealogy'),
    ]),
    MenuSectionDef('OPERATIONS', [
      MenuItemDef(label: 'WALLETS', icon: Icons.account_balance_wallet_outlined, route: '/wallets'),
      MenuItemDef(label: 'KYC', icon: Icons.verified_user_outlined, route: '/kyc'),
      MenuItemDef(label: 'MARKET RATES', icon: Icons.trending_up_outlined, route: '/market-rates'),
      MenuItemDef(label: 'WITHDRAWALS', icon: Icons.money_off_outlined, route: '/withdrawals'),
      MenuItemDef(label: 'NOTIFICATIONS', icon: Icons.notifications_outlined, route: '/notifications'),
    ]),
    MenuSectionDef('SYSTEM', [
      MenuItemDef(label: 'ADD STAFF', icon: Icons.person_add_outlined, route: '/add-staff'),
      MenuItemDef(label: 'SETTINGS', icon: Icons.settings_outlined, route: AppRoutes.settings),
    ]),
  ];

  static const List<MenuSectionDef> _advocateMenu = [
    MenuSectionDef('LEGAL', [
      MenuItemDef(label: 'OVERVIEW', icon: Icons.bar_chart_rounded, route: AppRoutes.dashboard),
      MenuItemDef(label: 'PURCHASES', icon: Icons.shopping_cart_outlined, route: '/purchase-verification'),
      MenuItemDef(label: 'AGREEMENTS', icon: Icons.gavel_outlined, route: '/agreements'),
      MenuItemDef(label: 'CUSTOMERS', icon: Icons.people_outline, route: '/customers'),
      MenuItemDef(label: 'ARCHIVE', icon: Icons.archive_outlined, route: '/archive'),
      MenuItemDef(label: 'DISPUTES', icon: Icons.balance_outlined, route: '/disputes'),
    ]),
    MenuSectionDef('ACCOUNT', [
      MenuItemDef(label: 'PROFILE', icon: Icons.person_outline_rounded, route: AppRoutes.profile),
    ]),
  ];

  static const List<MenuSectionDef> _auditorMenu = [
    MenuSectionDef('MAIN MENU', [
      MenuItemDef(label: 'DASHBOARD', icon: Icons.bar_chart_rounded, route: AppRoutes.dashboard),
      MenuItemDef(label: 'BUY', icon: Icons.shopping_cart_outlined, route: '/auditor-buy'),
      MenuItemDef(label: 'REQUEST A PRODUCT', icon: Icons.inventory_outlined, route: '/auditor-request'),
      MenuItemDef(label: 'CASHBACK', icon: Icons.payments_outlined, route: '/auditor-cashback'),
      MenuItemDef(label: 'CASHBACK APPLICATION', icon: Icons.request_quote_outlined, route: '/auditor-cashback-application'),
      MenuItemDef(label: 'REFERRALS', icon: Icons.account_tree_outlined, route: '/auditor-referral'),
      MenuItemDef(
        label: 'WALLETS',
        icon: Icons.account_balance_wallet_outlined,
        children: [
          MenuItemDef(label: 'Wallet Overview', icon: Icons.account_balance_wallet_outlined, route: '/auditor-wallets'), 
          MenuItemDef(label: 'Transaction History', icon: Icons.receipt_long_outlined, route: '/auditor-transaction'),
          MenuItemDef(label: 'Withdraw History', icon: Icons.history_outlined, route: '/auditor-withdrawals'),
        ],
      ),
      MenuItemDef(label: 'RULES', icon: Icons.rule_outlined, route: '/auditor-rules'),
    ]),
    MenuSectionDef('ACCOUNT SETTINGS', [
      MenuItemDef(label: 'KYC', icon: Icons.verified_user_outlined, route: '/auditor-kyc'),
      MenuItemDef(label: 'AGREEMENT', icon: Icons.gavel_outlined, route: '/auditor-agreements'),
      MenuItemDef(label: 'PROFILE', icon: Icons.person_outline_rounded, route: '/auditor-profile'),
    ]),
  ];

  static List<MenuSectionDef> menuFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return _adminMenu;
      case UserRole.manager:
        return _managerMenu;
      case UserRole.staff:
        return _staffMenu;
      case UserRole.advocate:
        return _advocateMenu;
      case UserRole.auditor:
        return _auditorMenu;
    }
  }

  static const List<String> _universalRoutes = [
    AppRoutes.profile,
    AppRoutes.settings,
  ];

  static bool canAccess(String route, UserRole role) {
    if (_universalRoutes.contains(route)) return true;
    final allRoleRoutes = menuFor(role).expand((s) => s.items).expand((i) => i.allRoutes);
    final isRoleGated = UserRole.values
        .expand((r) => menuFor(r))
        .expand((s) => s.items)
        .expand((i) => i.allRoutes)
        .contains(route);
    if (!isRoleGated) return true;
    return allRoleRoutes.contains(route);
  }

  static String landingRouteFor(UserRole role) {
    final sections = menuFor(role);
    for (final section in sections) {
      if (section.items.isNotEmpty) {
        final first = section.items.first;
        return first.route.isNotEmpty ? first.route : first.children.first.route;
      }
    }
    return AppRoutes.unauthorized;
  }
}