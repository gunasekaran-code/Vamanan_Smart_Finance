import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'customer_feedback_section.dart';
import '../../models/customer_dashboard_model.dart';
import '../../services/customer_dashboard_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

/// The landing page for the customer role.
///
/// Backed by `customer/dashboard.php`, which is scoped to a single `user_id`.
/// It deliberately does not reuse AuditorDashboardScreen: that screen reads
/// `auditor/summary.php`, which reports platform-wide revenue, GST collected
/// and total wallet liability — figures a customer must never see.
class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  static const Color _navy = Color(0xFF1B233A);
  static const Color _royal = AppColors.kPrimary;
  static const Color _slate = AppColors.kTextMuted;
  static const Color _label = Color(0xFFCBD5E1);
  static const Color _hairline = Color(0xFFF1F5F9);

  final _money0 =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _money2 =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  CustomerDashboard? _data;
  Object? _error;
  bool _loading = true;

  String get _displayName =>
      SessionService.instance.currentUser?.name ?? 'CUSTOMER';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await CustomerDashboardService.instance.fetchDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _reload() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  String _money(double v) => _money0.format(v);
  String _moneyExact(double v) => _money2.format(v);

  void _copy(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    ToastService.show(
      title: 'Copied',
      message: '$what copied to clipboard.',
      type: ToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // custom header
      children: [
        Center(
          child: Container(
                        constraints: const BoxConstraints(maxWidth: 800), 
            child: _body(),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 120),
        child: Center(child: AppLoader()),
      );
    }

    if (_error != null || _data == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: _slate),
            const SizedBox(height: 16),
            const Text(
              'COULD NOT LOAD YOUR DASHBOARD',
              style: TextStyle(
                color: _navy,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _slate, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _reload, child: const Text('RETRY')),
          ],
        ),
      );
    }

    final data = _data!;
    final plan = data.plan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(data),
        const SizedBox(height: 20),
        _actionRow(),
        const SizedBox(height: 24),
        _totalPaidCard(plan),
        const SizedBox(height: 16),
        _statCards(data, plan),
        const SizedBox(height: 24),
        _earningsCapCard(plan),
        const SizedBox(height: 24),
        _investmentProgressCard(plan),
        const SizedBox(height: 24),
        _networkCard(data, plan),
        const SizedBox(height: 24),
        _ordersCard(data.cycles),
        const SizedBox(height: 24),
        _importantNotice(plan),
        const SizedBox(height: 24),
        _navCard(
          icon: Icons.trending_up_rounded,
          title: 'ACQUIRE GOLD',
          subtitle: 'SCALE YOUR INSTITUTIONAL PORTFOLIO',
          route: '/auditor-buy',
        ),
        const SizedBox(height: 16),
        _navCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'WALLET OPERATIONS',
          subtitle: 'MANAGE WITHDRAWALS AND TERMINAL HISTORY',
          route: '/auditor-wallets',
        ),
        const SizedBox(height: 24),
        const CustomerFeedbackSection(),
        const SizedBox(height: 40),
      ],
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================

  Widget _header(CustomerDashboard data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.star, color: AppColors.goldColor, size: 8),
            SizedBox(width: 8),
            Text(
              'ACTIVE SESSION',
              style: TextStyle(
                color: AppColors.goldColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'DASHBOARD',
          style: TextStyle(
            color: _navy,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'WELCOME BACK, ${_displayName.toUpperCase()}'
          '${data.customerId.isEmpty ? '' : ' · CUSTOMER ID ${data.customerId}'}',
          style: const TextStyle(
            color: _slate,
            fontSize: 10,
            height: 1.5,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _actionRow() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hairline, width: 2),
          ),
          child: IconButton(
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh_rounded, color: _royal, size: 20),
            tooltip: 'Refresh',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => context.push('/auditor-buy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _royal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'INVEST NOW',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TOTAL PAID
  // ==========================================================================

  Widget _totalPaidCard(CustomerPlan plan) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _royal,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.goldBadgeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.show_chart_rounded,
                color: AppColors.goldColor, size: 18),
          ),
          const SizedBox(height: 20),
          Text(
            'TOTAL PAID (INCL. GST)',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _money(plan.totalValue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'CASHBACK BASE ${_money(plan.eligibleAmount)} · '
            'GST ${_money(plan.gstAmount)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // STAT CARDS
  // ==========================================================================

  Widget _statCards(CustomerDashboard data, CustomerPlan plan) {
    return Column(
      children: [
        _statCard(
          icon: Icons.workspace_premium_outlined,
          label: 'GOLD CASHBACK',
          value: _money(plan.totalEarned),
          caption: 'TOTAL REALISED',
          captionColor: AppColors.goldColor,
        ),
        const SizedBox(height: 12),
        _statCard(
          icon: Icons.bolt_rounded,
          label: 'MONTHLY CASHBACK',
          value: _money(plan.monthlyPayoutNet),
          caption: plan.tdsRate > 0 || plan.serviceChargeRate > 0
              ? 'NET INSTALMENT AFTER TDS + CHARGES'
              : 'NET MONTHLY INSTALMENT',
        ),
        const SizedBox(height: 12),
        _statCard(
          icon: Icons.account_tree_outlined,
          label: 'NETWORK COMMISSIONS',
          value: _money(plan.totalReferralEarned),
          caption: 'DIRECT REFERRAL INCOME',
        ),
        const SizedBox(height: 12),
        _statCard(
          icon: Icons.savings_outlined,
          label: 'REMAINING AMOUNT',
          value: _money(plan.remainingValue),
          caption: 'STILL TO BE RETURNED TO YOU',
          highlighted: true,
        ),
        const SizedBox(height: 12),
        _statCard(
          icon: Icons.calendar_month_outlined,
          label: 'MONTHS PROGRESS',
          value: '${plan.monthsCompleted} / ${plan.planMonths}',
          caption: 'INSTALMENTS CREDITED',
        ),
        const SizedBox(height: 12),
        _statCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'WALLET BALANCE',
          value: _money(data.balance),
          caption: 'LIVE',
          captionColor: AppColors.kSuccess,
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required String caption,
    Color? captionColor,
    bool highlighted = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFF5F8FF) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlighted ? const Color(0xFFDDE6FF) : _hairline,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: highlighted ? Colors.white : AppColors.kBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: highlighted ? _royal : AppColors.goldColor, size: 16),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: _label,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: highlighted ? _royal : _navy,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: TextStyle(
              color: captionColor ?? _slate.withOpacity(0.8),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // EARNINGS CAP
  // ==========================================================================

  Widget _earningsCapCard(CustomerPlan plan) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'EARNINGS CAP',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.goldBadgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${plan.cashbackPercentage.toStringAsFixed(1)}% REACHED',
                  style: const TextStyle(
                    color: AppColors.goldColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'CASHBACK + REFERRAL COMBINED · STOPS AT 100% OF PRINCIPAL',
            style: TextStyle(
              color: _slate,
              fontSize: 9,
              height: 1.5,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: plan.progress,
              minHeight: 10,
              backgroundColor: AppColors.kPrimaryLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.goldColor),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _capFigure('EARNED', _money(plan.totalEarned), _navy),
              ),
              Expanded(
                child: _capFigure(
                    'PRINCIPAL CAP', _money(plan.eligibleAmount), _slate),
              ),
              Expanded(
                child: _capFigure(
                    'REMAINING', _money(plan.remainingValue), _royal),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.kBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'ONCE YOUR COMBINED CASHBACK + REFERRAL EARNINGS REACH 100% OF '
              'YOUR PRINCIPAL, PAYOUTS STOP AUTOMATICALLY — EVEN IF MONTHS '
              'REMAIN ON THE PLAN.',
              style: TextStyle(
                color: _slate,
                fontSize: 9,
                height: 1.6,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _capFigure(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _label,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // INVESTMENT PROGRESS
  // ==========================================================================

  Widget _investmentProgressCard(CustomerPlan plan) {
    if (!plan.hasPlan) {
      return _card(
        child: Column(
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 40, color: _label),
            const SizedBox(height: 14),
            const Text(
              'NO ACTIVE PLAN YET',
              style: TextStyle(
                color: _navy,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Make your first purchase to start earning monthly cashback.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _slate, fontSize: 12),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => context.push('/auditor-buy'),
              icon: const Icon(Icons.shopping_cart_outlined, size: 16),
              label: const Text('BUY NOW'),
            ),
          ],
        ),
      );
    }

    final pending = plan.status.toLowerCase() == 'pending';
    final (Color badgeColor, String badgeLabel) = switch (plan.status.toLowerCase()) {
      'active' => (AppColors.kSuccess, 'ACTIVE'),
      'completed' => (_royal, 'COMPLETED'),
      'pending' => (AppColors.kWarning, 'PENDING APPROVAL'),
      _ => (_slate, plan.status.toUpperCase()),
    };

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INVESTMENT PROGRESS',
            style: TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            plan.weight > 0
                ? '${plan.productName.toUpperCase()} · '
                    '${plan.weight.toStringAsFixed(3)} GRAMS'
                : plan.productName.toUpperCase(),
            style: const TextStyle(
              color: AppColors.goldColor,
              fontSize: 9,
              height: 1.5,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'REAL-TIME TRACKING OF YOUR ACTIVE INVESTMENTS',
            style: TextStyle(
              color: _slate,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (pending)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.goldBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.goldBorder),
              ),
              child: const Text(
                'MONTHLY CASHBACK BEGINS ONCE AN ADMIN APPROVES THIS '
                'PURCHASE. NOTHING IS CREDITED BEFORE APPROVAL.',
                style: TextStyle(
                  color: AppColors.kWarning,
                  fontSize: 9,
                  height: 1.6,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: plan.planMonths == 0
                    ? 0
                    : (plan.monthsCompleted / plan.planMonths).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: AppColors.kPrimaryLight,
                valueColor: const AlwaysStoppedAnimation<Color>(_royal),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _progressFigure(
                  Icons.event_available_outlined,
                  'MONTHS PAID',
                  '${plan.monthsCompleted} / ${plan.planMonths}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _progressFigure(
                  Icons.payments_outlined,
                  'MONTHLY PAYOUT',
                  _money(plan.monthlyPayout),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _progressFigure(
                  Icons.schedule_rounded,
                  'PLAN DURATION',
                  '${plan.planMonths} Months',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _progressFigure(
                  Icons.percent_rounded,
                  'MONTHLY RATE',
                  '${plan.monthlyRate.toStringAsFixed(plan.monthlyRate % 1 == 0 ? 0 : 2)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressFigure(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _royal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _label,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // NETWORK EXPANSION
  // ==========================================================================

  Widget _networkCard(CustomerDashboard data, CustomerPlan plan) {
    final code = data.referralCode;

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _royal,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups_outlined,
                color: AppColors.goldColor, size: 18),
          ),
          const SizedBox(height: 18),
          const Text(
            'NETWORK\nEXPANSION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'GROW YOUR RETURNS BY BRINGING NEW INVESTORS INTO YOUR NETWORK.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 9,
              height: 1.6,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _networkFigure(
                    '${data.referralsCount}', 'REFERRALS'),
              ),
              Expanded(
                child: _networkFigure(
                    _money(plan.totalReferralEarned), 'TOTAL EARNED'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  'YOUR PERSONAL CODE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  code.isEmpty ? 'NOT SET' : code,
                  style: const TextStyle(
                    color: AppColors.goldColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/auditor-referral'),
              icon: const Icon(Icons.account_tree_outlined, size: 16),
              label: const Text(
                'VIEW NETWORK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: code.isEmpty
                  ? null
                  : () => _copy(code, 'Referral code'),
              icon: const Icon(Icons.link_rounded, size: 16),
              label: const Text(
                'COPY LINK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withOpacity(0.4),
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkFigure(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 8,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // ORDERS & INVOICES
  // ==========================================================================

  Widget _ordersCard(List<CustomerCycle> cycles) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.kBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: _royal, size: 16),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORDERS & INVOICES',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'TAX INVOICES WITH CGST / SGST BREAKDOWN',
                      style: TextStyle(
                        color: _slate,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (cycles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'NO ORDERS YET. PLACE AN ORDER TO GET\nYOUR TAX INVOICE.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _label,
                    fontSize: 10,
                    height: 1.8,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            )
          else
            for (final cycle in cycles.take(5)) _orderRow(cycle),
        ],
      ),
    );
  }

  Widget _orderRow(CustomerCycle cycle) {
    final (Color color, String label) = switch (cycle.status.toLowerCase()) {
      'active' => (AppColors.kSuccess, 'ACTIVE'),
      'completed' => (_royal, 'COMPLETED'),
      'rejected' => (AppColors.kDanger, 'REJECTED'),
      _ => (AppColors.kWarning, 'PENDING'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.kBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    cycle.displayName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _orderLine('TOTAL PAID', _moneyExact(cycle.totalValue)),
            _orderLine('TAXABLE VALUE', _moneyExact(cycle.eligibleAmount)),
            // An intra-state sale, so the GST splits evenly in two.
            _orderLine('CGST', _moneyExact(cycle.cgst)),
            _orderLine('SGST', _moneyExact(cycle.sgst)),
            if (cycle.createdAt != null)
              _orderLine(
                'ORDERED',
                DateFormat('dd MMM yyyy').format(cycle.createdAt!),
              ),
            if (!cycle.hasInvoice) ...[
              const SizedBox(height: 8),
              const Text(
                'TAX INVOICE AVAILABLE ONCE APPROVED',
                style: TextStyle(
                  color: AppColors.kWarning,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _orderLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _label,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _navy,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // NOTICE + NAV CARDS
  // ==========================================================================

  Widget _importantNotice(CustomerPlan plan) {
    final rate = plan.monthlyRate > 0
        ? plan.monthlyRate.toStringAsFixed(plan.monthlyRate % 1 == 0 ? 0 : 2)
        : (100 / (plan.planMonths == 0 ? 10 : plan.planMonths))
            .toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.goldBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.goldBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.goldColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              const Text(
                'IMPORTANT NOTICE',
                style: TextStyle(
                  color: _navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'YOU EARN MONTHLY CASHBACK — YOUR PURCHASE VALUE IS RETURNED OVER '
            '${plan.planMonths} EQUAL MONTHLY INSTALMENTS ($rate% EACH). '
            'CASHBACK IS CALCULATED ON YOUR PRODUCT VALUE ONLY (GST '
            'EXCLUDED), REFERRAL INCOME IS INCLUDED, AND THE COMBINED TOTAL '
            'IS CAPPED AT 100% OF THAT AMOUNT.',
            style: TextStyle(
              color: _slate.withOpacity(0.95),
              fontSize: 9,
              height: 1.8,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _hairline, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.kBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _royal, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _slate,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _label, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _hairline, width: 2),
      ),
      child: child,
    );
  }
}
