import 'package:flutter/material.dart';

import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/empty_state_card.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Archive',
      subtitle: 'Closed cases and historical legal records.',
      children: [
        EmptyStateCard(
          headerIcon: Icons.archive_outlined,
          headerLabel: 'ARCHIVE',
          emptyIcon: Icons.inventory_2_outlined,
          emptyLabel: 'ARCHIVE IS EMPTY',
        ),
      ],
    );
  }
}
