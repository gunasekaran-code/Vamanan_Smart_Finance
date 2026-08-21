import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';

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
    // 1. Get the sequential list of allowed tabs for this role.
    // This perfectly matches the router's branch indices (0, 1, 2, 3...)
    final allowedEntries = PermissionService.entriesFor(role);

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
              for (int i = 0; i < allowedEntries.length; i++)
                Expanded(
                  child: _NavButton(
                    label: allowedEntries[i].label,
                    icon: allowedEntries[i].icon,
                    selected: i == activeIndex,
                    onTap: () => onSelectBranch(i),
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
