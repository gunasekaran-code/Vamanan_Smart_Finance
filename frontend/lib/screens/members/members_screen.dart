import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  // TODO: replace with a paginated list from GET /members.
  static const _demoMembers = [
    ('Jessica', 'Active', AppColors.kSuccess),
    ('Varshini', 'Active', AppColors.kSuccess),
    ('Roki', 'Overdue', AppColors.kDanger),
  ];

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Members',
      subtitle: 'Visible to Super Admin, Admin and Staff only.',
      children: [
        for (final m in _demoMembers)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.kPrimary,
                  child: Text(m.$1.substring(0, 1), style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(m.$1, style: const TextStyle(fontWeight: FontWeight.w600))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: m.$3.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    m.$2,
                    style: TextStyle(color: m.$3, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
