import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user.dart';
import '../routes/app_routes.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final AppUser? user;
  double _preferredHeight = 56;

  AppHeader({
    super.key,
    required this.user,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();

  @override
  Size get preferredSize => Size.fromHeight(_preferredHeight);
}

class _AppHeaderState extends State<AppHeader> {
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isCompactWidth = false;

  final GlobalKey _notificationKey = GlobalKey();
  final GlobalKey _avatarKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

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
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    } else {
      _searchController.clear();
      _searchFocusNode.unfocus();
    }

    _scheduleHeightMeasure();
    // Cross-fade animation is 220ms; measure again once it's fully settled.
    Future.delayed(const Duration(milliseconds: 240), () {
      if (mounted) _measureHeight();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isCompactWidth = MediaQuery.sizeOf(context).width < 380;
    _scheduleHeightMeasure();
  }

  void _scheduleHeightMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  void _measureHeight() {
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final measured = box.size.height;
    // Small safety buffer so nothing clips on the last pixel.
    final target = measured + 2;
    if ((widget._preferredHeight - target).abs() > 0.5) {
      setState(() {
        widget._preferredHeight = target;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _isCompactWidth = MediaQuery.sizeOf(context).width < 380;

    return Column(
      key: _contentKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ================================================================
        // APP BAR
        // ================================================================

        AppBar(
          titleSpacing: _isCompactWidth ? 10 : 12,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: _isCompactWidth ? 34 : 38,
                  height: _isCompactWidth ? 34 : 38,
                  decoration: BoxDecoration(
                    color: AppColors.kPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: _isCompactWidth ? 19 : 21,
                  ),
                ),
                SizedBox(width: _isCompactWidth ? 8 : 10),
                const _BrandTitle(),
              ],
            ),
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

        // ================================================================
        // SEARCH BAR
        // ================================================================

        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _showSearch
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _buildSearchBar(),
          secondChild: const SizedBox(
            width: double.infinity,
            height: 0,
          ),
        ),
      ],
    );
  }

  // ======================================================================
  // SEARCH BAR
  // ======================================================================
  Widget _buildSearchBar() {
    final barHeight = _isCompactWidth ? 50.0 : 54.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        _isCompactWidth ? 6 : 8,
        16,
        _isCompactWidth ? 10 : 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.kSurface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.kBorder,
            width: 0.7,
          ),
        ),
      ),
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: _isCompactWidth ? 14 : 16),
              child: Icon(
                Icons.search_rounded,
                color: const Color(0xFF6B7280),
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
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
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
                    color: const Color(0xFF9CA3AF),
                    size: _isCompactWidth ? 18 : 20,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: GestureDetector(
                onTap: () {
                  _performSearch(
                    _searchController.text,
                  );
                },
                child: Container(
                  width: _isCompactWidth ? 42 : 44,
                  height: _isCompactWidth ? 42 : 44,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 22,
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
  }

  // ======================================================================
  // NOTIFICATION MENU
  // ======================================================================

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
    final double maxMenuWidth = 320.0;
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
    final double maxMenuWidth = 310.0;
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

  // ======================================================================
  // PROFILE MENU
  // ======================================================================

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
            widget.user?.name ?? 'CF Admin',
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
            context.go(AppRoutes.engineSettings);
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

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: AppColors.kTextDark,
        ),
        children: [
          TextSpan(text: 'Smart'),
          TextSpan(
            text: 'Finance',
            style: TextStyle(color: AppColors.kPrimary),
          ),
        ],
      ),
    );
  }
}