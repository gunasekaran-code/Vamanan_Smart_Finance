import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_loader.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/app_upgrade_alert.dart';

void main() {
  runApp(const VamananGoldApp());
}

class VamananGoldApp extends StatelessWidget {
  const VamananGoldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vamanan Enterprises V | Vamanan Gold',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
      // With MaterialApp.router the alert has to sit inside the router's
      // widget tree, so it wraps the routed child instead of the app itself
      // and borrows the router's navigator for showDialog().
      // AppLoaderHost draws the global blurred logo loader above every page.
      builder: (context, child) => AppLoaderHost(
        child: AppUpgradeAlert(
          navigatorKey: ToastService.navigatorKey,
          upgrader: Upgrader(
            messages: AppUpgraderMessages(),
            durationUntilAlertAgain: const Duration(days: 1),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
