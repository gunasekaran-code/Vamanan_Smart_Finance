import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const _bars = [0.3, 0.6, 0.4, 0.9, 0.5, 0.7];

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Reports',
      subtitle: 'Visible to Super Admin and Admin only.',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // TODO: replace with a real chart (e.g. the fl_chart
              // package) fed by GET /reports/collections.
              for (final b in _bars)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FractionallySizedBox(
                      heightFactor: b,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.kPrimary.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
