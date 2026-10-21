import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/auditor_cashback_application_model.dart';

void main() {
  group('CashbackApplicationRequest', () {
    // cashback_application.php rejects the POST outright when any of these is
    // empty: "Missing required field: <name>".
    const requiredKeys = [
      'user_id',
      'customer_name',
      'phone',
      'purchase_amount',
      'account_no',
      'ifsc_code',
    ];

    const minimal = CashbackApplicationRequest(
      userId: 6,
      customerName: 'Anupriya.M',
      phone: '6380635824',
      purchaseAmount: 25000,
      accountNo: '00000000000',
      ifscCode: 'SBIN0000123',
    );

    test('always sends every field the endpoint requires', () {
      final json = minimal.toJson();
      for (final key in requiredKeys) {
        expect(json.containsKey(key), isTrue, reason: 'missing $key');
        expect('${json[key]}', isNotEmpty, reason: '$key was empty');
      }
    });

    test('omits optional fields that are blank', () {
      final json = minimal.toJson();
      expect(json.keys, hasLength(requiredKeys.length));
      for (final key in [
        'address',
        'aadhar_no',
        'pan_no',
        'purchased_product',
        'agent_name',
        'purchase_date',
      ]) {
        expect(json.containsKey(key), isFalse, reason: '$key should be absent');
      }
    });

    test('sends optional fields once filled in', () {
      const full = CashbackApplicationRequest(
        userId: 6,
        customerName: 'Anupriya.M',
        phone: '6380635824',
        purchaseAmount: 25000,
        accountNo: '00000000000',
        ifscCode: 'SBIN0000123',
        address: '12 Main St',
        aadharNo: '123412341234',
        panNo: 'ABCDE1234F',
        customerCode: 'VEV006',
        customerEmail: 'anupriya375@gmail.com',
        referralId: 'VEV28BFZ',
        purchasedProduct: '22K Gold Coin',
        productDetails: '8 gram coin',
        purchaseDate: '2026-09-01',
        bankAccountName: 'Anupriya M',
        bankName: 'State Bank of India',
        bankBranch: 'Krishnagiri Main',
        agentName: 'R. Kumar',
        agentId: 'AG-22',
        place: 'Krishnagiri',
        applicationDate: '2026-09-21',
      );

      final json = full.toJson();
      expect(json['purchase_date'], '2026-09-01');
      expect(json['application_date'], '2026-09-21');
      expect(json['customer_code'], 'VEV006');
      expect(json['pan_no'], 'ABCDE1234F');
      expect(json['place'], 'Krishnagiri');
    });

    test('purchase_amount goes over the wire as a number', () {
      expect(minimal.toJson()['purchase_amount'], isA<double>());
      expect(minimal.toJson()['purchase_amount'], 25000);
    });
  });

  group('CashbackApplicationPrefill', () {
    test('parses the users row with no prior application', () {
      final prefill = CashbackApplicationPrefill.fromJson(const {
        'user': {
          'id': '6',
          'customer_id': 'VEV006',
          'name': 'Anupriya.M',
          'email': 'anupriya375@gmail.com',
          'phone': '6380635824',
          'address': null,
          'aadhar_no': null,
          'pan_no': null,
          'referral_code': 'VEV28BFZ',
          'bank_name': null,
          'account_no': null,
          'ifsc_code': null,
          'branch_name': null,
        },
        'application': null,
      });

      expect(prefill.user.id, 6);
      expect(prefill.user.customerId, 'VEV006');
      expect(prefill.user.referralCode, 'VEV28BFZ');
      expect(prefill.application, isNull);
    });

    test('parses the most recent application, numerics included', () {
      final prefill = CashbackApplicationPrefill.fromJson(const {
        'user': {'id': '6', 'name': 'Anupriya.M'},
        'application': {
          'id': '4',
          'user_id': '6',
          'customer_name': 'Anupriya.M',
          'purchase_amount': '1600002.00',
          'purchase_date': '2026-09-01',
          'application_date': '2026-09-21',
          'status': 'pending',
          'place': '',
        },
      });

      final app = prefill.application!;
      expect(app.id, 4);
      expect(app.purchaseAmount, 1600002.0);
      expect(app.isPending, isTrue);
      expect(app.purchaseDate?.month, 9);
      // The column default only applies on INSERT, so a blank read-back still
      // has to fall back client-side.
      expect(app.place, 'Krishnagiri');
    });

    test('treats a zeroed MySQL date as no date', () {
      final prefill = CashbackApplicationPrefill.fromJson(const {
        'user': {'id': '6'},
        'application': {
          'id': '1',
          'user_id': '6',
          'purchase_date': '0000-00-00',
          'application_date': '',
        },
      });

      expect(prefill.application!.purchaseDate, isNull);
      expect(prefill.application!.applicationDate, isNull);
    });
  });

  group('CashbackApplicationSubmitResult', () {
    test('reads a success envelope', () {
      final result = CashbackApplicationSubmitResult.fromJson(const {
        'status': 'success',
        'message': 'Cashback application submitted successfully.',
        'application_id': '7',
      });
      expect(result.success, isTrue);
      expect(result.applicationId, 7);
    });

    test('reads a rejection', () {
      final result = CashbackApplicationSubmitResult.fromJson(const {
        'status': 'error',
        'message': 'Missing required field: ifsc_code',
      });
      expect(result.success, isFalse);
      expect(result.message, contains('ifsc_code'));
      expect(result.applicationId, isNull);
    });
  });
}
