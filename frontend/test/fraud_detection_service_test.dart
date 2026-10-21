import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/admin_user_model.dart';
import 'package:frontend/models/fraud_detection_model.dart';
import 'package:frontend/models/genealogy_explorer_model.dart';
import 'package:frontend/services/fraud_detection_service.dart';

/// Exercises the rule engine through `analyze`, which takes data directly and
/// never touches the network.
void main() {
  final service = FraudDetectionService.instance;

  AdminUserModel user(
    int id, {
    String? name,
    String email = '',
    int? referrerId,
    String status = 'ACTIVE',
    String kycStatus = 'verified',
    double balance = 0,
    bool referralActive = true,
    DateTime? createdAt,
  }) {
    return AdminUserModel(
      id: id,
      customerId: 'VEV$id',
      referralCode: 'REF$id',
      name: name ?? 'User $id',
      email: email.isEmpty ? 'user$id@example.com' : email,
      role: 'CUSTOMER',
      status: status,
      kycStatus: kycStatus,
      kycDocument: null,
      createdAt: createdAt ?? DateTime(2025, 1, 1),
      referrerId: referrerId,
      referralActive: referralActive,
      referrerName: referrerId == null ? null : 'User $referrerId',
      referrerCustomerId: referrerId == null ? null : 'VEV$referrerId',
      referrerReferralCode: referrerId == null ? null : 'REF$referrerId',
      balance: balance,
    );
  }

  List<String> codes(FraudScanResult r) => r.alerts.map((a) => a.code).toList();

  FraudAlert alertOf(FraudScanResult r, String code) =>
      r.alerts.firstWhere((a) => a.code == code);

  group('clean network', () {
    test('a plain verified tree raises nothing', () {
      final result = service.analyze(users: [
        user(1),
        user(2, referrerId: 1),
        user(3, referrerId: 1),
      ]);

      expect(result.alerts, isEmpty);
      expect(result.isClean, isTrue);
      expect(result.riskScore, 0);
      expect(result.riskLabel, 'CLEAR');
      expect(result.usersScanned, 3);
      expect(result.financialsIncluded, isFalse);
    });

    test('an empty user list yields an empty result', () {
      expect(service.analyze(users: const []).alerts, isEmpty);
    });
  });

  group('sponsor-edge integrity', () {
    test('flags an account that sponsors itself', () {
      final result = service.analyze(users: [user(1, referrerId: 1)]);

      expect(codes(result), contains('SELF_REFERRAL'));
      expect(alertOf(result, 'SELF_REFERRAL').severity, FraudSeverity.high);
      expect(alertOf(result, 'SELF_REFERRAL').subjects.single.id, '1');
    });

    test('flags a two-node sponsor loop on both accounts', () {
      final result = service.analyze(users: [
        user(1, referrerId: 2),
        user(2, referrerId: 1),
      ]);

      final circular = alertOf(result, 'CIRCULAR_REFERRAL');
      expect(circular.subjects.map((s) => s.id).toSet(), {'1', '2'});
    });

    test('does not mistake a legitimate deep chain for a loop', () {
      final result = service.analyze(users: [
        user(1),
        user(2, referrerId: 1),
        user(3, referrerId: 2),
      ]);

      expect(codes(result), isNot(contains('CIRCULAR_REFERRAL')));
    });

    test('flags a sponsor id with no matching account', () {
      final result = service.analyze(users: [user(1, referrerId: 99)]);

      expect(codes(result), contains('ORPHAN_SPONSOR'));
      expect(alertOf(result, 'ORPHAN_SPONSOR').subjects.single.detail,
          contains('99'));
    });
  });

  group('identity duplication', () {
    test('collapses gmail dot and +tag aliases onto one mailbox', () {
      final result = service.analyze(users: [
        user(1, email: 'ravi.kumar@gmail.com'),
        user(2, email: 'ravikumar+vev@gmail.com'),
        user(3, email: 'someone.else@outlook.com'),
      ]);

      final dup = alertOf(result, 'DUPLICATE_EMAIL');
      expect(dup.subjects.map((s) => s.id).toSet(), {'1', '2'});
    });

    test('leaves dots alone on non-gmail domains', () {
      final result = service.analyze(users: [
        user(1, email: 'ravi.kumar@outlook.com'),
        user(2, email: 'ravikumar@outlook.com'),
      ]);

      expect(codes(result), isNot(contains('DUPLICATE_EMAIL')));
    });

    test('flags a repeated name beneath one sponsor', () {
      final result = service.analyze(users: [
        user(1),
        user(2, referrerId: 1, name: 'Ravi  Kumar'),
        user(3, referrerId: 1, name: 'ravi kumar'),
      ]);

      final dup = alertOf(result, 'DUPLICATE_NAME_SAME_SPONSOR');
      expect(dup.subjects.map((s) => s.id).toSet(), {'2', '3'});
    });

    test('ignores the same name under different sponsors', () {
      final result = service.analyze(users: [
        user(1),
        user(2),
        user(3, referrerId: 1, name: 'Ravi Kumar'),
        user(4, referrerId: 2, name: 'Ravi Kumar'),
      ]);

      expect(codes(result), isNot(contains('DUPLICATE_NAME_SAME_SPONSOR')));
    });
  });

  group('signup bursts', () {
    test('flags five signups under one sponsor inside 24h', () {
      final base = DateTime(2025, 3, 1, 10);
      final result = service.analyze(users: [
        user(1),
        for (var i = 0; i < 5; i++)
          user(10 + i,
              referrerId: 1, createdAt: base.add(Duration(minutes: i * 3))),
      ]);

      final burst = alertOf(result, 'SIGNUP_BURST');
      expect(burst.severity, FraudSeverity.high);
      expect(burst.subjects.length, 5);
      expect(burst.subjects.map((s) => s.id).toSet(),
          {'10', '11', '12', '13', '14'});
    });

    test('leaves the same five spread over weeks alone', () {
      final base = DateTime(2025, 3, 1);
      final result = service.analyze(users: [
        user(1),
        for (var i = 0; i < 5; i++)
          user(10 + i,
              referrerId: 1, createdAt: base.add(Duration(days: i * 7))),
      ]);

      expect(codes(result), isNot(contains('SIGNUP_BURST')));
    });

    test('reports each account once even when the window slides', () {
      final base = DateTime(2025, 3, 1, 10);
      final result = service.analyze(users: [
        user(1),
        for (var i = 0; i < 8; i++)
          user(10 + i,
              referrerId: 1, createdAt: base.add(Duration(minutes: i))),
      ]);

      final burst = alertOf(result, 'SIGNUP_BURST');
      final ids = burst.subjects.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('chain stacking', () {
    test('flags a four-deep single-child run', () {
      final result = service.analyze(users: [
        user(1),
        user(2, referrerId: 1),
        user(3, referrerId: 2),
        user(4, referrerId: 3),
        user(5, referrerId: 4),
        // Second leg off the root keeps node 1 from being part of the run.
        user(6, referrerId: 1),
      ]);

      final chain = alertOf(result, 'CHAIN_STACKING');
      expect(chain.subjects.map((s) => s.id).toSet(), {'2', '3', '4', '5'});
    });

    test('ignores a shallow run', () {
      final result = service.analyze(users: [
        user(1),
        user(2, referrerId: 1),
        user(3, referrerId: 2),
        user(6, referrerId: 1),
      ]);

      expect(codes(result), isNot(contains('CHAIN_STACKING')));
    });

    test('ignores a branching tree of the same size', () {
      final result = service.analyze(users: [
        user(1),
        user(2, referrerId: 1),
        user(3, referrerId: 1),
        user(4, referrerId: 2),
        user(5, referrerId: 2),
      ]);

      expect(codes(result), isNot(contains('CHAIN_STACKING')));
    });
  });

  group('KYC and account status', () {
    test('flags an unverified wallet holding funds', () {
      final result = service.analyze(users: [
        user(1, kycStatus: 'pending', balance: 4500),
      ]);

      final gap = alertOf(result, 'KYC_GAP_FUNDED');
      expect(gap.severity, FraudSeverity.high);
      expect(gap.subjects.single.detail, contains('4500'));
    });

    test('flags an unverified account that sponsors others', () {
      final result = service.analyze(users: [
        user(1, kycStatus: ''),
        user(2, referrerId: 1),
      ]);

      expect(codes(result), contains('KYC_GAP_SPONSOR'));
      expect(alertOf(result, 'KYC_GAP_SPONSOR').subjects.single.detail,
          contains('not submitted'));
    });

    test('treats "approved" as verified', () {
      final result = service.analyze(users: [
        user(1, kycStatus: 'approved', balance: 4500),
        user(2, referrerId: 1),
      ]);

      expect(codes(result), isNot(contains('KYC_GAP_FUNDED')));
      expect(codes(result), isNot(contains('KYC_GAP_SPONSOR')));
    });

    test('flags a suspended account that still sponsors', () {
      final result = service.analyze(users: [
        user(1, status: 'SUSPENDED'),
        user(2, referrerId: 1),
      ]);

      expect(codes(result), contains('RESTRICTED_SPONSOR'));
    });

    test('flags placements made against a disabled referral link', () {
      final result = service.analyze(users: [
        user(1, referralActive: false),
        user(2, referrerId: 1),
      ]);

      final dormant = alertOf(result, 'DORMANT_LINK_WITH_DOWNLINE');
      expect(dormant.severity, FraudSeverity.low);
    });
  });

  group('payout rules', () {
    GenealogyNode node(String id, double invested, double earned,
            {List<GenealogyNode> downline = const []}) =>
        GenealogyNode(
          id: id,
          name: 'User $id',
          referralCode: 'REF$id',
          totalInvestment: invested,
          totalEarned: earned,
          downline: downline,
        );

    test('flags a payout with no cashback cycle behind it', () {
      final result = service.analyze(
        users: [user(1)],
        tree: [node('7', 0, 2500)],
      );

      expect(codes(result), contains('EARNINGS_WITHOUT_INVESTMENT'));
      expect(result.financialsIncluded, isTrue);
    });

    test('flags a payout larger than the cycle value, nested in the tree', () {
      final result = service.analyze(
        users: [user(1)],
        tree: [
          node('7', 10000, 4000, downline: [node('8', 10000, 13000)]),
        ],
      );

      final over = alertOf(result, 'PAYOUT_OVER_CYCLE_VALUE');
      expect(over.subjects.single.id, '8');
      expect(over.subjects.single.detail, contains('130%'));
    });

    test('leaves a partially paid cycle alone', () {
      final result = service.analyze(
        users: [user(1)],
        tree: [node('7', 10000, 3000)],
      );

      expect(result.alerts, isEmpty);
    });

    test('counts an account appearing under two roots only once', () {
      final result = service.analyze(
        users: [user(1)],
        tree: [node('7', 0, 2500), node('7', 0, 2500)],
      );

      expect(alertOf(result, 'EARNINGS_WITHOUT_INVESTMENT').subjects.length, 1);
    });
  });

  group('scoping', () {
    test('rootNodeId limits the scan to that subtree', () {
      final users = [
        user(1),
        user(2, referrerId: 1),
        user(3, referrerId: 2),
        // A separate leg with a self-referral that must stay out of scope.
        user(4),
        user(5, referrerId: 5),
      ];

      final scoped =
          service.analyze(users: users, rootNodeId: '1', scopeLabel: 'LEG A');

      expect(scoped.usersScanned, 3);
      expect(scoped.scopeLabel, 'LEG A');
      expect(codes(scoped), isNot(contains('SELF_REFERRAL')));

      final global = service.analyze(users: users);
      expect(global.usersScanned, 5);
      expect(codes(global), contains('SELF_REFERRAL'));
    });

    test('an unknown root falls back to the whole network', () {
      final result =
          service.analyze(users: [user(1), user(2)], rootNodeId: '404');
      expect(result.usersScanned, 2);
    });
  });

  group('result summary', () {
    test('risk score saturates and orders severity first', () {
      final result = service.analyze(users: [
        user(1, referrerId: 1, kycStatus: 'pending', balance: 900),
        user(2, email: 'dup@gmail.com'),
        user(3, email: 'd.up@gmail.com'),
        user(4, referralActive: false),
        user(5, referrerId: 4),
      ]);

      expect(result.riskScore, inInclusiveRange(1, 100));
      expect(result.alerts.first.severity, FraudSeverity.high);
      expect(result.alerts.last.severity, FraudSeverity.low);
      expect(result.flaggedAccounts, greaterThan(0));
    });
  });
}
