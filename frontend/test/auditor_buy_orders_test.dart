import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/models/auditor_buy_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuditorSession', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SessionService.instance.logout();
    });

    test('is null when nobody is signed in', () {
      expect(AuditorSession.currentUserId, isNull);
    });

    test('resolves the signed-in user id', () async {
      await SessionService.instance.updateCurrentUser(const AppUser(
        id: '6',
        name: 'Anupriya.M',
        email: 'anupriya375@gmail.com',
        role: UserRole.customer,
      ));
      addTearDown(() => SessionService.instance.logout());

      expect(AuditorSession.currentUserId, 6);
    });

    test('is null rather than 0 for an unparseable id', () async {
      await SessionService.instance.updateCurrentUser(const AppUser(
        id: 'not-a-number',
        name: 'Broken',
        email: 'b@example.com',
        role: UserRole.customer,
      ));
      addTearDown(() => SessionService.instance.logout());

      expect(AuditorSession.currentUserId, isNull);
    });
  });

  group('OrderHistoryItem', () {
    test('parses a customer/orders.php row with string numerics', () {
      final item = OrderHistoryItem.fromJson(const {
        'id': '12',
        'total_value': '26250.00',
        'product_amount': '25000.00',
        'gst_amount': '1250.00',
        'total_amount': '26250.00',
        'asset_type': 'gold',
        'weight': '4.500',
        'status': 'approved',
        'transaction_id': 'TXN99',
        'payment_screenshot': 'uploads/payments/pay_12.jpg',
        'created_at': '2026-09-01 11:04:00',
        'product_name': '22K Gold Coin',
        'cycle_product_name': 'Gold 4.5g',
      });

      expect(item.id, 12);
      expect(item.totalValue, 26250.0);
      expect(item.gstAmount, 1250.0);
      expect(item.weight, 4.5);
      expect(item.assetType, 'gold');
      expect(item.status, 'approved');
      expect(item.productName, '22K Gold Coin');
    });

    test('falls back to the name on the cycle row', () {
      // A plain gold buy has no agreement->product join, so product_name is
      // null even though the cycle carries its own name.
      final item = OrderHistoryItem.fromJson(const {
        'id': '13',
        'product_name': null,
        'cycle_product_name': 'Pure Silver Asset',
      });
      expect(item.productName, 'Pure Silver Asset');
    });

    test('leaves the name null when neither column has one', () {
      final item = OrderHistoryItem.fromJson(const {'id': '14'});
      expect(item.productName, isNull);
      expect(item.assetType, 'gold');
      expect(item.status, 'pending');
    });

    test('falls back to total_value when total_amount is absent', () {
      final item = OrderHistoryItem.fromJson(const {
        'id': '15',
        'total_value': '5000',
      });
      expect(item.totalAmount, 5000.0);
    });
  });
}
