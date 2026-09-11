import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/routing/app_routes.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/theme/app_theme.dart';

class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final AppUser? user;

  const AppHeader({
    super.key,
    required this.user,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();

  // We return a strictly fixed height so the Scaffold never throws layout errors.
  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}

class _AppHeaderState extends State<AppHeader> {
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isCompactWidth = false;

  final GlobalKey _notificationKey = GlobalKey();
  final GlobalKey _avatarKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
    });

    if (_showSearch) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    } else {
      _searchController.clear();
      _searchFocusNode.unfocus();
    }
  }

  String _currentPageTitle() {
    final state = GoRouter.maybeOf(context)?.state;
    final location = state?.matchedLocation ?? '';
    final path =
        location.isEmpty || location == '/' ? AppRoutes.dashboard : location;

    final titles = <String, String>{
      AppRoutes.dashboard: 'Dashboard',
      AppRoutes.verify: 'Verify',
      AppRoutes.security: 'Security & 2FA',
      AppRoutes.members: 'Members',
      AppRoutes.payments: 'Payments',
      AppRoutes.fieldCollection: 'Field Collection',
      AppRoutes.dailyCollectionReport: 'Daily Collection Report',
      AppRoutes.kycCompliance: 'KYC Compliance',
      AppRoutes.IdentityVerification: 'Identity Verification',
      AppRoutes.chits: 'Chits',
      AppRoutes.auctions: 'Auctions',
      AppRoutes.settlements: 'Settlements',
      AppRoutes.branchHandovers: 'Branch Handovers',
      AppRoutes.paymentVerifications: 'Payment Verifications',
      AppRoutes.reports: 'Reports',
      AppRoutes.loanDashboard: 'Loan Dashboard',
      AppRoutes.loans: 'Loans',
      AppRoutes.loanCustomers: 'Loan Customers',
      AppRoutes.emiCollections: 'EMI Collections',
      AppRoutes.overdueEmis: 'Overdue EMIs',
      AppRoutes.loanVerifications: 'Loan Verifications',
      AppRoutes.loanReports: 'Loan Reports',
      AppRoutes.branches: 'Branches',
      AppRoutes.analytics: 'Analytics',
      AppRoutes.broadcastHub: 'Broadcast Hub',
      AppRoutes.userManager: 'User Manager',
      AppRoutes.auditControls: 'Audit Controls',
      AppRoutes.notifications: 'Notifications',
      AppRoutes.profile: 'Profile',
      '/purchases': 'Investments',
      '/purchase-history': 'Investment History',
      '/gstr': 'GSTR Filing',
      '/invoices': 'Invoices',
      '/asset-inventory': 'Asset Inventory',
      '/product-requests': 'Product Requests',
      '/cashback-applications': 'Cashback Applications',
      '/cashback-monitoring': 'Cashback Monitoring',
      '/users': 'Users',
      '/genealogy': 'Genealogy',
      '/wallets': 'Wallets',
      '/wallets-list': 'Wallets List',
      '/cashback-payouts': 'Cashback Payouts',
      '/export-payout': 'Export Payout Excel',
      '/payout-reconciliation': 'Payout Reconciliation',
      '/payout-reports': 'Payout Reports',
      '/wallet-adjustment': 'Wallet Adjustment',
      '/tally-export': 'Tally Export',
      '/tally-integration': 'Tally Integration',
      '/kyc': 'KYC',
      '/market-rates': 'Market Rates',
      '/withdrawals': 'Withdrawals',
      '/withdrawals-liquidity': 'Withdrawals Liquidity',
      '/cashback-reports': 'Cashback Reports',
      '/withdrawal-reports': 'Withdrawal Reports',
      '/transaction-reports': 'Transaction Reports',
      '/investment-reports': 'Investment Reports',
      '/referral-reports': 'Referral Reports',
      '/holiday-calendar': 'Holiday Calendar',
      '/feedback': 'Feedback & Remarks',
      '/offers': 'Offers & Festivals',
      '/add-staff': 'Add Staff',
      AppRoutes.settings: 'System Settings',
      AppRoutes.customers: 'Customers',
      AppRoutes.support: 'Support',
      AppRoutes.agreements: 'Agreements',
      AppRoutes.archive: 'Archive',
      AppRoutes.disputes: 'Disputes',
      AppRoutes.rules: 'Rules',
    };

    return titles[path] ?? _deriveTitleFromPath(path);
  }

  String _deriveTitleFromPath(String path) {
    final cleanPath = path.split('?').first.split('#').first;
    final normalized =
        cleanPath.replaceFirst('/', '').replaceAll(RegExp(r'[-_]'), ' ');
    if (normalized.trim().isEmpty) return 'Dashboard';

    return normalized
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .map((segment) => segment[0].toUpperCase() + segment.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    _isCompactWidth = MediaQuery.sizeOf(context).width < 380;
    final pageTitle = _currentPageTitle();

    // Grab top padding so our dropdown correctly avoids the OS status bar
    final topPadding = MediaQuery.paddingOf(context).top;

    return Stack(
      // clipBehavior: Clip.none is the magic that allows the search bar
      // to paint over the body without causing pixel overflow errors.
      clipBehavior: Clip.none,
      children: [
        AppBar(
          titleSpacing: _isCompactWidth ? 10 : 16,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _PageTitle(title: pageTitle), // App logo completely removed
          ),
          actions: [
            IconButton(
              tooltip: 'Search',
              onPressed: _toggleSearch,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: _isCompactWidth ? 40 : 44,
                height: 44,
              ),
              visualDensity: VisualDensity.compact,
              icon: Icon(
                _showSearch ? Icons.close_rounded : Icons.search_rounded,
                size: _isCompactWidth ? 24 : 27,
              ),
            ),
            IconButton(
              key: _notificationKey,
              tooltip: 'Notifications',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: _isCompactWidth ? 40 : 44,
                height: 44,
              ),
              visualDensity: VisualDensity.compact,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 26),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.kDanger,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.kSurface, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                _showNotificationMenu(context, _notificationKey);
              },
            ),
            InkWell(
              key: _avatarKey,
              customBorder: const CircleBorder(),
              onTap: () {
                _showProfileMenu(context, _avatarKey);
              },
              child: CircleAvatar(
                radius: _isCompactWidth ? 18 : 20,
                backgroundColor: AppColors.kPrimary,
                child: Text(
                  widget.user?.initials ?? 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),

        // The Dropdown Search Bar Positioned exactly below the AppBar
        Positioned(
          top: topPadding + 56.0,
          left: 0,
          right: 0,
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _showSearch
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildSearchBar(),
            secondChild: const SizedBox(width: double.infinity, height: 0),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final barHeight = _isCompactWidth ? 56.0 : 64.0;
    return Container(
      width: double.infinity,
      height: barHeight,
      padding: EdgeInsets.fromLTRB(
        16,
        _isCompactWidth ? 6 : 8,
        16,
        _isCompactWidth ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors
            .kSurface, // Ensure background is solid so text behind it is blocked
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: const Border(
          bottom: BorderSide(
            color: AppColors.kBorder,
            width: 1.0,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.kBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: _isCompactWidth ? 14 : 16),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.kTextDark.withOpacity(0.5),
                size: _isCompactWidth ? 22 : 24,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: _performSearch,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.kTextDark,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                    color: AppColors.kTextDark.withOpacity(0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.kTextDark.withOpacity(0.5),
                    size: _isCompactWidth ? 18 : 20,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: GestureDetector(
                onTap: () {
                  _performSearch(_searchController.text);
                },
                child: Container(
                  width: _isCompactWidth ? 36 : 38,
                  height: _isCompactWidth ? 36 : 38,
                  decoration: BoxDecoration(
                    color: AppColors.kPrimary, // Themed color
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _performSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    debugPrint('Searching for: $query');
    // Implement your search logic here
  }

  void _showNotificationMenu(BuildContext context, GlobalKey anchorKey) {
    final RenderBox anchorBox =
        anchorKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final Offset anchorBottomRight = anchorBox.localToGlobal(
      anchorBox.size.bottomRight(Offset.zero),
      ancestor: overlayBox,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    const double maxMenuWidth = 320.0;
    final double menuWidth =
        screenWidth < (maxMenuWidth + 32) ? screenWidth - 32 : maxMenuWidth;

    showMenu(
      context: context,
      color: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      position: RelativeRect.fromLTRB(
        overlayBox.size.width - menuWidth - 16,
        anchorBottomRight.dy + 8,
        16,
        0,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(width: menuWidth, child: _buildNotificationMenu()),
        ),
      ],
    );
  }

  void _showProfileMenu(BuildContext context, GlobalKey anchorKey) {
    final RenderBox anchorBox =
        anchorKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final Offset anchorBottomRight = anchorBox.localToGlobal(
      anchorBox.size.bottomRight(Offset.zero),
      ancestor: overlayBox,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    const double maxMenuWidth = 310.0;
    final double menuWidth =
        screenWidth < (maxMenuWidth + 32) ? screenWidth - 32 : maxMenuWidth;

    showMenu(
      context: context,
      color: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      position: RelativeRect.fromLTRB(
        overlayBox.size.width - menuWidth - 16,
        anchorBottomRight.dy + 8,
        16,
        0,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(width: menuWidth, child: _buildProfileMenu()),
        ),
      ],
    );
  }

  Widget _buildNotificationMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            'Notifications',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.kTextDark,
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.kBorder),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.kPrimary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.download_done_rounded,
                color: AppColors.kPrimary, size: 20),
          ),
          title: const Text('System Update Ready',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: const Text(
              'Core engine v2.4 has been installed successfully.',
              style: TextStyle(fontSize: 13)),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.kDanger.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.kDanger, size: 20),
          ),
          title: const Text('Overdue Alert',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: const Text('3 branches have pending audit clearance.',
              style: TextStyle(fontSize: 13)),
          onTap: () => Navigator.pop(context),
        ),
        const Divider(height: 1, color: AppColors.kBorder),
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Center(
              child: Text(
                'Mark all as read',
                style: TextStyle(
                  color: AppColors.kPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: AppColors.kPrimary,
            child: Text(
              widget.user?.initials ?? 'A',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            widget.user?.name ?? 'Admin',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(widget.user?.email ?? 'admin@gmail.com'),
        ),
        const Divider(),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          horizontalTitleGap: 12,
          leading: const Icon(Icons.person_outline),
          title: const Text('My Profile'),
          subtitle: const Text('Account settings & info'),
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.profile);
          },
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          horizontalTitleGap: 12,
          leading: const Icon(Icons.settings_outlined),
          title: const Text('System Config'),
          subtitle: const Text('Core engine settings'),
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.settings);
          },
        ),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          horizontalTitleGap: 12,
          leading: const Icon(Icons.shield_outlined),
          title: const Text('Security & 2FA'),
          subtitle: const Text('Protect your account'),
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.security);
          },
        ),
        const Divider(),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          horizontalTitleGap: 12,
          leading: const Icon(Icons.logout, color: AppColors.kDanger),
          title: const Text(
            'Sign Out',
            style: TextStyle(
              color: AppColors.kDanger,
              fontWeight: FontWeight.w700,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            SessionService.instance.logout();
            context.go(AppRoutes.login);
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PageTitle extends StatelessWidget {
  final String title;

  const _PageTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 20,
        color: AppColors.kTextDark,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
