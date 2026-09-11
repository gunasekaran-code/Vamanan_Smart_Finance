import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/core/services/session_service.dart';
import 'app_bottom_nav.dart';
import 'app_drawer.dart';
import 'app_header.dart';

/// Persistent chrome for every authenticated page.
///
/// [navigationShell] comes from go_router's `StatefulShellRoute` — it
/// is the one piece of state that changes when a tab is tapped; the
/// [Scaffold], [AppHeader], and [AppBottomNav] all stay mounted, which
/// is what gives the "no full page reload" SPA behaviour, and each
/// branch keeps its own navigation/scroll state when you switch away
/// and back.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser;
    final role = user?.role ?? UserRole.staff;

    return Scaffold(
      appBar: AppHeader(user: user),
      drawer: AppDrawer(
        role: role,
      ),
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        role: role,
        activeIndex: navigationShell.currentIndex,
        onSelectBranch: (index) => navigationShell.goBranch(
          index,
          // Tapping the tab you're already on resets it to its initial
          // location, matching standard bottom-nav behaviour.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
