import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/shared/widgets/app_header.dart';

void main() {
  testWidgets('AppHeader shows the active route title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppHeader(
            user: const AppUser(
              id: '1',
              name: 'Jane Admin',
              email: 'jane@smartfinance.dev',
              role: UserRole.admin,
            ),
          ),
          body: const SizedBox(),
        ),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('SmartFinance'), findsNothing);
  });
}