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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      _updatePreferredHeight();
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePreferredHeight();
  }

  void _updatePreferredHeight() {
    widget._preferredHeight = _showSearch ? (_isCompactWidth ? 126 : 132) : 56;
  }

  @override
  Widget build(BuildContext context) {
    _isCompactWidth = MediaQuery.sizeOf(context).width < 380;
    _updatePreferredHeight();

    return Column(
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
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 26,
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.kDanger,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.kSurface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                // Your notification dropdown
              },
            ),
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                _showProfileMenu(context);
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
            // Search icon
            Padding(
              padding: EdgeInsets.only(left: _isCompactWidth ? 14 : 16),
              child: Icon(
                Icons.search_rounded,
                color: Color(0xFF6B7280),
                size: _isCompactWidth ? 22 : 24,
              ),
            ),

            // Text field
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

            // Clear button
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
                    color: Color(0xFF9CA3AF),
                    size: _isCompactWidth ? 18 : 20,
                  ),
                ),
              ),

            // Search button
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

  // ======================================================================
  // SEARCH ACTION
  // ======================================================================

  void _performSearch(String value) {
    final query = value.trim();

    if (query.isEmpty) {
      return;
    }

    debugPrint('Searching for: $query');

    // Later you can connect this to:
    //
    // Members search
    // Loan search
    // Customer search
    // Payment search
    // Chit search
    //
    // Example:
    // context.go('${AppRoutes.members}?search=$query');
  }

  // ======================================================================
  // PROFILE MENU
  // ======================================================================

  void _showProfileMenu(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;

    final position = renderBox.localToGlobal(Offset.zero);

    final screenWidth = MediaQuery.of(context).size.width;

    showMenu(
      context: context,
      color: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      position: RelativeRect.fromLTRB(
        screenWidth - 330,
        position.dy + renderBox.size.height + 8,
        16,
        0,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 310,
            child: _buildProfileMenu(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.kPrimary,
            child: Text(
              widget.user?.initials ?? 'A',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          title: Text(
            widget.user?.name ?? 'CF Admin',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            widget.user?.email ?? 'admin@gmail.com',
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(
            Icons.person_outline,
          ),
          title: const Text('My Profile'),
          subtitle: const Text(
            'Account settings & info',
          ),
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.profile);
          },
        ),
        ListTile(
          leading: const Icon(
            Icons.settings_outlined,
          ),
          title: const Text('System Config'),
          subtitle: const Text(
            'Core engine settings',
          ),
          onTap: () {
            Navigator.pop(context);
            context.go(
              AppRoutes.engineSettings,
            );
          },
        ),
        ListTile(
          leading: const Icon(
            Icons.shield_outlined,
          ),
          title: const Text('Security & 2FA'),
          subtitle: const Text(
            'Protect your account',
          ),
          onTap: () {
            Navigator.pop(context);
            context.go(
              AppRoutes.security,
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(
            Icons.logout,
            color: AppColors.kDanger,
          ),
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

            context.go(
              AppRoutes.login,
            );
          },
        ),
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
            style: TextStyle(
              color: AppColors.kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
