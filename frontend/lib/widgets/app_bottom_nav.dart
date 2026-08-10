import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';

/// Bottom tab bar. Items the current role can't access are removed
/// entirely (as opposed to [AppDrawer], which disables them) so the
/// primary nav only ever shows destinations that actually work for
/// this user.
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
    final visible = <MapEntry<int, NavEntry>>[
      for (int i = 0; i < PermissionService.navEntries.length; i++)
        if (PermissionService.navEntries[i].isAllowedFor(role))
          MapEntry(i, PermissionService.navEntries[i]),
    ];

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
              for (final entry in visible)
                Expanded(
                  child: _NavButton(
                    label: entry.value.label,
                    icon: entry.value.icon,
                    selected: entry.key == activeIndex,
                    onTap: () => onSelectBranch(entry.key),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.kPrimary : AppColors.kTextMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
