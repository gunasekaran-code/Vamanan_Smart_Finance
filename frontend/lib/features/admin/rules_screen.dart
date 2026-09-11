import 'package:flutter/material.dart';

import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/empty_state_card.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Rules',
      subtitle: 'Compliance rules and thresholds enforced platform-wide.',
      children: [
        EmptyStateCard(
          headerIcon: Icons.rule_outlined,
          headerLabel: 'RULES',
          emptyIcon: Icons.policy_outlined,
          emptyLabel: 'NO CUSTOM RULES CONFIGURED',
        ),
      ],
    );
  }
}
