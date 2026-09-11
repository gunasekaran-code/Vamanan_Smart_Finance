import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/core/routing/app_routes.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders /branches content on a mobile viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // The session cache writes through shared_preferences.
    SharedPreferences.setMockInitialValues({});

    // Seed the session directly instead of going through SessionService.login,
    // which now posts to the real backend — this test is about the /branches
    // screen rendering, not about authentication.
    await SessionService.instance.updateCurrentUser(const AppUser(
      id: 'test-admin',
      name: 'Test Admin',
      email: 'admin@example.com',
      role: UserRole.admin,
    ));
    addTearDown(() => SessionService.instance.logout());
    await tester.pumpWidget(const VamananGoldApp());
    AppRouter.router.go(AppRoutes.branches);
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Regional Footprint'), findsOneWidget);
    expect(find.text('Main Office'), findsOneWidget);
    expect(find.text("Teacher's Colony Branch"), findsOneWidget);
  });
}
