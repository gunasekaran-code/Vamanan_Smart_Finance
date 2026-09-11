import 'package:flutter/material.dart';

import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/core/routing/app_routes.dart';
import 'package:frontend/core/services/permission_service.dart';
import 'package:frontend/core/theme/app_theme.dart';

/// Bottom navigation bar for the authenticated shell.
///
/// Tabs come from [PermissionService.bottomNavFor], so a role only ever
/// sees shortcuts to pages it's actually permitted to open. A trailing
/// "Menu" tab always opens the drawer, which carries that role's full
/// [PermissionService.menuFor] list — the bottom bar itself only holds a
/// handful of the most-used destinations, keeping it usable on narrow
/// phones no matter how large a role's menu is.
///
/// [activeIndex] is the *global* branch index from `StatefulNavigationShell`
/// (see [AppRoutes.shellBranchOrder]) — not a position within this bar's
/// own (shorter, role-filtered) tab list — so each entry's route is
/// resolved through that shared order before comparing or navigating.
class AppBottomNav extends StatelessWidget {
  final UserRole role;
  final int activeIndex;
  final void Function(int branchIndex) onSelectBranch;

  const AppBottomNav({
    super.key,
    required this.role,
    required this.activeIndex,
    required this.onSelectBranch,
  });

  @override
  Widget build(BuildContext context) {
    final entries = PermissionService.bottomNavFor(role);
    final activeRoute = activeIndex >= 0 && activeIndex < AppRoutes.shellBranchOrder.length
        ? AppRoutes.shellBranchOrder[activeIndex]
        : null;
    final activeEntryIndex = entries.indexWhere((e) => e.route == activeRoute);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.kSurface,
        border: Border(top: BorderSide(color: AppColors.kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (int i = 0; i < entries.length; i++)
                Expanded(
                  child: _NavButton(
                    label: entries[i].label,
                    icon: entries[i].icon,
                    selected: i == activeEntryIndex,
                    onTap: () => _goToRoute(entries[i].route),
                  ),
                ),
              Expanded(
                child: _NavButton(
                  label: 'Menu',
                  icon: Icons.menu_rounded,
                  selected: activeEntryIndex == -1,
                  onTap: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToRoute(String route) {
    final branchIndex = AppRoutes.shellBranchOrder.indexOf(route);
    if (branchIndex == -1) return;
    onSelectBranch(branchIndex);
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final targetColor = selected ? AppColors.kPrimary : AppColors.kTextMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // Suppressing the harsh default splash makes the custom animation stand out more
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 250),
          tween: ColorTween(end: targetColor),
          builder: (context, color, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gives the icon a satisfying, slightly bouncy "pop" when selected
                  AnimatedScale(
                    scale: selected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(height: 4),
                  // Smoothly transitions the font weight and color of the label
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}