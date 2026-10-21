import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/customer_dashboard_model.dart';

/// A realistic `customer/dashboard.php` payload. PDO hands numerics back as
/// strings, so every figure on the dashboard must be parsed, never cast.
Map<String, dynamic> get _payload => {
      'balance': '0.00',
      'customer_id': 'VEV006',
      'referral_code': 'VEV288FZ',
      'referrals_count': '0',
      'agreement_id': null,
      'active_cycle': {
        'total_value': '1600002.00',
        'product_amount': '1355900.00',
        'gst_amount': '244102.00',
        'cashback_eligible': '1355900.00',
        'total_earned': '0',
        'remaining_value': '1553400.00',
        'cashback_percentage': '9.6',
        'plan_months': '10',
        'months_completed': '0',
        'months_remaining': '10',
        'monthly_payout': '135590.00',
        'monthly_payout_net': '122031.00',
        'monthly_rate': '10',
        'tds_rate': '10',
        'service_charge_rate': '0',
        'active_plans_count': '1',
        'status': 'pending',
        'asset_type': 'gold',
        'weight': '40.000',
        'product_name': '24K Gold',
        'today_earning': '0',
        'total_referral_earned': '0',
        'is_closing_soon': false,
      },
      'incentive_breakdown': {
        'gross': '0',
        'tds': '0',
        'charges': '0',
        'deduction': '0',
        'net': '0',
      },
      'cycles': [
        {
          'id': '4',
          'total_value': '1600002.00',
          'gst_amount': '244102.00',
          'cashback_eligible_amount': '1355900.00',
          'paid_amount': '0',
          'daily_payout': '135590.00',
          'days_paid': '0',
          'asset_type': 'gold',
          'weight': '40.000',
          'status': 'pending',
          'product_name': '24K Gold',
          'transaction_id': 'TXN77',
          'created_at': '2026-09-15 10:00:00',
        }
      ],
      'transactions': [],
      'notifications': [],
    };

void main() {
  group('CustomerDashboard', () {
    test('parses the headline figures', () {
      final d = CustomerDashboard.fromJson(_payload);

      expect(d.customerId, 'VEV006');
      expect(d.referralCode, 'VEV288FZ');
      expect(d.referralsCount, 0);
      expect(d.balance, 0);
      expect(d.hasAgreement, isFalse);
    });

    test('parses the plan block, monthly aliases included', () {
      final plan = CustomerDashboard.fromJson(_payload).plan;

      expect(plan.totalValue, 1600002.0);
      expect(plan.eligibleAmount, 1355900.0);
      expect(plan.gstAmount, 244102.0);
      expect(plan.remainingValue, 1553400.0);
      expect(plan.cashbackPercentage, 9.6);
      expect(plan.planMonths, 10);
      expect(plan.monthsCompleted, 0);
      expect(plan.monthlyPayout, 135590.0);
      expect(plan.monthlyPayoutNet, 122031.0);
      expect(plan.monthlyRate, 10);
      expect(plan.weight, 40.0);
      expect(plan.status, 'pending');
      expect(plan.hasPlan, isTrue);
    });

    test('falls back to the legacy daily_* spellings', () {
      // An older backend emits only the daily names.
      final plan = CustomerPlan.fromJson(const {
        'total_value': '1000',
        'daily_payout': '100',
        'daily_payout_net': '90',
        'daily_rate': '10',
        'days_completed': '3',
        'days_remaining': '7',
        'status': 'active',
      });

      expect(plan.monthlyPayout, 100);
      expect(plan.monthlyPayoutNet, 90);
      expect(plan.monthlyRate, 10);
      expect(plan.monthsCompleted, 3);
      expect(plan.monthsRemaining, 7);
      expect(plan.planMonths, 10); // default when absent
    });

    test('progress is clamped to 0..1 for the cap bar', () {
      expect(CustomerDashboard.fromJson(_payload).plan.progress,
          closeTo(0.096, 0.0001));

      final over = CustomerPlan.fromJson(const {
        'total_value': '100',
        'cashback_percentage': '140',
      });
      expect(over.progress, 1.0);
    });

    test('an empty payload yields a no-plan dashboard', () {
      final d = CustomerDashboard.fromJson(const {});
      expect(d.plan.hasPlan, isFalse);
      expect(d.cycles, isEmpty);
      expect(d.balance, 0);
      expect(d.plan.planMonths, 10);
    });
  });

  group('CustomerCycle', () {
    test('parses a cashback_cycles row', () {
      final cycle = CustomerDashboard.fromJson(_payload).cycles.single;

      expect(cycle.id, '4');
      expect(cycle.totalValue, 1600002.0);
      expect(cycle.eligibleAmount, 1355900.0);
      expect(cycle.monthlyPayout, 135590.0);
      expect(cycle.weight, 40.0);
      expect(cycle.isPending, isTrue);
      expect(cycle.createdAt?.year, 2026);
    });

    test('splits GST evenly into CGST and SGST', () {
      final cycle = CustomerDashboard.fromJson(_payload).cycles.single;
      expect(cycle.cgst, 122051.0);
      expect(cycle.sgst, 122051.0);
      expect(cycle.cgst + cycle.sgst, cycle.gstAmount);
    });

    test('a pending cycle has no invoice yet', () {
      final cycle = CustomerDashboard.fromJson(_payload).cycles.single;
      expect(cycle.hasInvoice, isFalse);

      final approved =
          CustomerCycle.fromJson(const {'id': '5', 'status': 'active'});
      expect(approved.hasInvoice, isTrue);
    });

    test('legacy rows with no eligible amount fall back to total_value', () {
      final cycle = CustomerCycle.fromJson(const {
        'id': '1',
        'total_value': '5000',
        'cashback_eligible_amount': '0',
      });
      expect(cycle.eligibleAmount, 5000.0);
    });

    test('names a bullion buy from its asset type', () {
      expect(
        CustomerCycle.fromJson(const {'asset_type': 'silver'}).displayName,
        'Pure Silver Asset',
      );
      expect(
        CustomerCycle.fromJson(const {'asset_type': 'gold'}).displayName,
        '22K Gold Asset',
      );
      expect(
        CustomerCycle.fromJson(const {'product_name': 'Coin 8g'}).displayName,
        'Coin 8g',
      );
    });
  });
}
