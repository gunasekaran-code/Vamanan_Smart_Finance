import 'package:flutter/material.dart';

import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/empty_state_card.dart';

class DisputesScreen extends StatelessWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Disputes',
      subtitle: 'Customer disputes and their resolution status.',
      children: [
        EmptyStateCard(
          headerIcon: Icons.balance_outlined,
          headerLabel: 'DISPUTES',
          emptyIcon: Icons.gavel_outlined,
          emptyLabel: 'NO OPEN DISPUTES',
        ),
      ],
    );
  }
}
