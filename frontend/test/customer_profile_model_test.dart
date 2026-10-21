import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/customer_profile_model.dart';

/// A realistic `customer/profile.php` payload. Numerics come back as strings
/// because PDO returns column values as strings unless emulation is off, so
/// the model must parse rather than cast.
Map<String, dynamic> get _payload => {
      'user': {
        'id': '6',
        'customer_id': 'VEV006',
        'name': 'Anupriya.M',
        'email': 'anupriya375@gmail.com',
        'phone': '6380635824',
        'address': null,
        'kyc_status': 'pending',
        'aadhar_no': null,
        'pan_no': null,
        'avatar': null,
        'bank_name': null,
        'account_no': null,
        'ifsc_code': null,
        'referral_code': 'VEV28BFZ',
        'created_at': '2026-08-14 10:22:31',
      },
      'wallet': {'balance': '0.00'},
      'stats': {
        'active_cycles': '0',
        'total_invested': '1600002.00',
        'referral_count': '0',
        'total_cashback': '0',
        'total_referral': '0',
        'total_earned': '0',
      },
    };

void main() {
  group('CustomerProfile', () {
    test('parses the profile.php envelope', () {
      final profile = CustomerProfile.fromJson(_payload);

      expect(profile.id, 6);
      expect(profile.customerId, 'VEV006');
      expect(profile.name, 'Anupriya.M');
      expect(profile.referralCode, 'VEV28BFZ');
      expect(profile.kycStatus, 'pending');
      expect(profile.isKycVerified, isFalse);
      expect(profile.createdAt?.year, 2026);
      expect(profile.createdAt?.month, 8);
    });

    test('parses string numerics into numbers', () {
      final profile = CustomerProfile.fromJson(_payload);

      expect(profile.walletBalance, 0.0);
      expect(profile.stats.totalInvested, 1600002.0);
      expect(profile.stats.activeCycles, 0);
      expect(profile.stats.referralCount, 0);
    });

    test('turns null columns into empty strings, never "null"', () {
      final profile = CustomerProfile.fromJson(_payload);

      for (final value in [
        profile.address,
        profile.aadharNo,
        profile.panNo,
        profile.avatar,
        profile.bankName,
        profile.accountNo,
        profile.ifscCode,
      ]) {
        expect(value, isEmpty);
      }
      expect(profile.hasAadhar, isFalse);
      expect(profile.hasPan, isFalse);
    });

    test('survives a completely empty payload', () {
      final profile = CustomerProfile.fromJson(const {});
      expect(profile.id, 0);
      expect(profile.kycStatus, 'pending');
      expect(profile.walletBalance, 0);
      expect(profile.stats.totalInvested, 0);
      expect(profile.initials, '?');
    });

    test('derives initials from a dotted name', () {
      expect(CustomerProfile.fromJson(_payload).initials, 'AM');
    });

    test('masks all but the last four characters', () {
      expect(CustomerProfile.mask('123456789012'), '••••••••9012');
      expect(CustomerProfile.mask('ABCD'), 'ABCD');
      expect(CustomerProfile.mask(''), '');
    });

    test('copyWith keeps the fields update_profile.php does not return', () {
      final original = CustomerProfile.fromJson(_payload);
      final updated = original.copyWith(
        name: 'New Name',
        email: 'new@example.com',
        phone: '9999999999',
        address: '12 Main St',
        bankName: 'HDFC',
        accountNo: '000111222',
        ifscCode: 'HDFC0001234',
      );

      expect(updated.name, 'New Name');
      expect(updated.bankName, 'HDFC');
      // update_profile.php replies with a message only, so everything it does
      // not touch has to survive the merge.
      expect(updated.id, original.id);
      expect(updated.customerId, 'VEV006');
      expect(updated.referralCode, 'VEV28BFZ');
      expect(updated.walletBalance, original.walletBalance);
      expect(updated.stats.totalInvested, original.stats.totalInvested);
      expect(updated.createdAt, original.createdAt);
    });
  });

  group('CustomerFeedbackThreads', () {
    test('parses both directions from get_feedback.php', () {
      final threads = CustomerFeedbackThreads.fromJson(const {
        'received': [
          {
            'id': '3',
            'subject': 'Payout query',
            'message': 'Processed on Friday.',
            'rating': null,
            'from_name': 'Gold Manager',
            'sender_role': 'manager',
            'created_at': '2026-09-01 09:00:00',
          }
        ],
        'sent': [
          {
            'id': '2',
            'subject': '',
            'message': 'When is my cashback due?',
            'rating': '4',
            'created_at': '2026-08-30 18:12:00',
          }
        ],
      });

      expect(threads.received, hasLength(1));
      expect(threads.received.first.fromName, 'Gold Manager');
      expect(threads.received.first.rating, isNull);

      expect(threads.sent, hasLength(1));
      expect(threads.sent.first.rating, 4);
      expect(threads.sent.first.subject, isEmpty);
    });

    test('treats missing threads as empty', () {
      const threads = CustomerFeedbackThreads();
      expect(threads.received, isEmpty);
      expect(threads.sent, isEmpty);
      expect(CustomerFeedbackThreads.fromJson(const {}).sent, isEmpty);
    });
  });
}
