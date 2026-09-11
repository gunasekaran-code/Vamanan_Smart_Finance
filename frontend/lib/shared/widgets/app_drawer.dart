import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/core/services/permission_service.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/theme/app_theme.dart';

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
      width: 290,
      backgroundColor: AppColors.kSurface,
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            // ============================================================
            // HEADER (Logo & Company Info)
            // ============================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.kPrimary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VAMANAN',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: AppColors.kPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Text(
                          'ENTERPRISES V',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: AppColors.kPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 3,
                              backgroundColor: AppColors.kWarning,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              role.label.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.kTextMuted,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ============================================================
            // MENU ITEMS (Scrollable) — driven by this role's menu, so
            // each of the five roles sees its own sections/pages.
            // ============================================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  for (final section in PermissionService.menuFor(role)) ...[
                    _sectionTitle(section.heading),
                    for (final item in section.items)
                      item.isExpandable
                          ? _expandableMenuItem(
                              context,
                              icon: item.icon,
                              label: item.label,
                              currentPath: currentPath,
                              children: [
                                for (final child in item.children)
                                  {
                                    'label': child.label,
                                    'route': child.route,
                                    'icon': child.icon,
                                  },
                              ],
                            )
                          : _menuItem(context,
                              icon: item.icon,
                              label: item.label,
                              route: item.route,
                              currentPath: currentPath),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ============================================================
            // FOOTER (Profile & Log Out)
            // ============================================================
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.kBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: AppColors.kTextMuted,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.email?.split('@').first.toUpperCase() ??
                                    'VAMANAN ENTERPRISES',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.kPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'SIGNED IN',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.kTextMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Log Out Button
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      SessionService.instance.logout();
                      context.go('/login');
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.kDanger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: AppColors.kDanger,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'LOG OUT',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: AppColors.kDanger,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.kDanger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // WIDGET HELPERS
  // ========================================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Text(
        title.split('').join(' '),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
          color: AppColors.kTextMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required String currentPath,
    bool hasArrow = false,
    bool forceLightBg = false,
  }) {
    final selected = currentPath == route ||
        (route != '/dashboard' && currentPath.startsWith('$route/'));

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.kPrimary
            : (forceLightBg ? AppColors.kBackground : Colors.transparent),
        borderRadius: BorderRadius.circular(20),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.kPrimary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).pop();
            context.go(route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? Colors.white : AppColors.kTextMuted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: selected ? Colors.white : AppColors.kTextMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.kWarning,
                      shape: BoxShape.circle,
                    ),
                  )
                else if (hasArrow)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.kTextMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _expandableMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String currentPath,
    required List<Map<String, dynamic>> children,
  }) {
    final bool isChildActive = children.any(
      (item) => currentPath == item['route'],
    );

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isChildActive
              ? AppColors.kPrimary.withOpacity(0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ExpansionTile(
          initiallyExpanded: isChildActive,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: Icon(
            icon,
            size: 22,
            color: isChildActive ? AppColors.kPrimary : AppColors.kTextMuted,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: isChildActive ? AppColors.kPrimary : AppColors.kTextMuted,
              letterSpacing: 0.5,
            ),
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 22,
            color: isChildActive ? AppColors.kPrimary : AppColors.kTextMuted,
          ),
          children: [
            Container(
              margin: const EdgeInsets.only(left: 20, right: 8, bottom: 8),
              padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.kPrimary.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                children: children.map((item) {
                  final String route = item['route'] as String;
                  final IconData childIcon = item['icon'] as IconData;
                  final String childLabel = item['label'] as String;
                  final bool isActive = currentPath == route;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.kPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.kPrimary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (!isActive) {
                            Navigator.of(context).pop();
                            context.go(route);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                childIcon,
                                size: 18,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.kTextMuted,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  childLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FontStyle.italic,
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.kTextMuted,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: AppColors.kWarning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
