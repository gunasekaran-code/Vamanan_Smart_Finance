import 'package:flutter/material.dart';

import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/theme/app_theme.dart';

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
    );
  }
}
