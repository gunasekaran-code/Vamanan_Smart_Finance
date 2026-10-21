import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import '../../models/customer_dashboard_model.dart';
import '../../services/customer_dashboard_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

/// The cashback dashboard screen for the customer role.
/// Reads only the signed-in customer's existing dashboard endpoint.
class CustomerCashbackScreen extends StatefulWidget {
  const CustomerCashbackScreen({super.key});

  @override
  State<CustomerCashbackScreen> createState() => _CustomerCashbackScreenState();
}

class _CustomerCashbackScreenState extends State<CustomerCashbackScreen> {
  static const Color _navy = Color(0xFF1B233A);
  static const Color _royal = AppColors.kPrimary;
  static const Color _slate = AppColors.kTextMuted;
  static const Color _label = Color(0xFFCBD5E1);
  static const Color _hairline = Color(0xFFF1F5F9);
  static const Color _gold = AppColors.goldColor;

  CustomerDashboard? _dashboard;
  String? _loadError;
  bool _loading = true;

  // History Tabs: 0 = ALL, 1 = CASHBACK, 2 = REFERRAL
  int _historyTab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int get _userId =>
      int.tryParse(SessionService.instance.currentUser?.id ?? '') ?? 0;

  String _money(double value) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      ).format(value);

  Future<void> _load() async {
    if (_userId == 0) {
      setState(() {
        _loadError = 'No signed-in customer.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final dashboard = await CustomerDashboardService.instance
          .fetchDashboard(userId: '$_userId');
      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
        _loadError = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = '$error'.replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

@override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // Custom header
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

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.kDanger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: AppColors.kDanger, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _navy,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('RETRY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _header(),
        const SizedBox(height: 32),
        _statsGrid(),
        const SizedBox(height: 24),
        _cycleProgressCard(),
        const SizedBox(height: 24),
        _nextPayoutCard(),
        const SizedBox(height: 40),
        _cashbackHistorySection(),
        const SizedBox(height: 80),
      ],
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _gold,
                boxShadow: [
                  BoxShadow(color: _gold.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)
                ],
              ),
              child: Icon(Icons.star, size: 6, color: Colors.white), // Adjust size/color as needed
            ),
            const SizedBox(width: 12),
            const Text(
              'CASHBACK PLAN',
              style: TextStyle(
                color: _slate,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'MY CASHBACK',
          style: TextStyle(
            color: _navy,
            fontSize: 32,
            height: 1.05,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '10% MONTHLY PAYOUT • 10 MONTHS = 100% • TRACKED LIVE',
          style: TextStyle(
            color: _slate,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: _load,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _hairline, width: 2),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: _slate.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 16, color: _navy),
                SizedBox(width: 8),
                Text(
                  'REFRESH DATA',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // STATS GRID
  // ==========================================================================

  Widget _statsGrid() {
    final plan = _dashboard!.plan;
    final incentives = _dashboard!.incentives;
    
    // Responsive grid handling
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 1.05 : 1.2,
          children: [
            _statCard(
              title: 'TOTAL PAID',
              amount: _money(plan.totalValue),
              subtitle: 'UNTIL 100%',
              icon: Icons.trending_up_rounded,
              iconColor: _gold,
            ),
            _statCard(
              title: 'MONTHLY PAYOUT',
              amount: _money(plan.monthlyPayoutNet),
              subtitle: '${plan.monthlyRate.toStringAsFixed(1)}% / MONTH',
              icon: Icons.flash_on_rounded,
              iconColor: _gold,
            ),
            _statCard(
              title: 'TOTAL EARNED',
              amount: _money(incentives.net),
              subtitle: 'VALID AGAINST LIMIT',
              icon: Icons.card_giftcard_rounded,
              iconColor: _gold,
            ),
            _statCard(
              title: "TODAY'S EARNING",
              amount: _money(plan.todayEarning),
              subtitle: 'TRACKED DAILY',
              icon: Icons.sync_rounded,
              iconColor: _royal,
            ),
          ],
        );
      }
    );
  }

  Widget _statCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    bool isPrimary = false,
    Color? iconColor,
  }) {
    final bgColor = isPrimary ? _navy : Colors.white;
    final textColor = isPrimary ? Colors.white : _navy;
    final subColor = isPrimary ? Colors.white70 : _slate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: isPrimary ? null : Border.all(color: _hairline, width: 2),
        boxShadow: isPrimary
            ? [BoxShadow(color: _navy.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))]
            : [BoxShadow(color: _slate.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.1)
                      : (iconColor ?? _navy).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: isPrimary ? _gold : iconColor),
              ),
              if (isPrimary)
                 const Icon(Icons.arrow_outward_rounded, color: Colors.white38, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: subColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: subColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // CYCLE PROGRESS CARD
  // ==========================================================================

  Widget _cycleProgressCard() {
    final plan = _dashboard!.plan;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _hairline, width: 2),
        boxShadow: [
          BoxShadow(color: _slate.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CYCLE\nPROGRESS',
                style: TextStyle(
                  color: _navy,
                  fontSize: 18,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _gold.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_empty_rounded, size: 14, color: _gold),
                    const SizedBox(width: 6),
                    Text(
                      plan.status.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 9,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${plan.productName.toUpperCase()}${plan.weight > 0 ? ' • ${plan.weight.toStringAsFixed(3)} GRAMS' : ''}',
            style: const TextStyle(
              color: _gold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MONTHS COMPLETED',
                style: TextStyle(
                  color: _slate,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${plan.monthsCompleted} / ${plan.planMonths}',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _hairline,
              borderRadius: BorderRadius.circular(6),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Container(
                      width: constraints.maxWidth * plan.progress,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_gold, Color(0xFFFFD700)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(color: _gold.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2)),
                        ]
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MONTH 01', style: TextStyle(color: _label, fontSize: 9, fontWeight: FontWeight.w800)),
              Text('MONTH ${plan.planMonths}', style: const TextStyle(color: _label, fontSize: 9, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _hairline.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _progressStat('REMAINING', _money(plan.remainingValue), isBlue: true),
                Container(width: 2, height: 40, color: _label.withOpacity(0.3)),
                _progressStat('MONTHS LEFT', '${plan.monthsRemaining}'),
                Container(width: 2, height: 40, color: _label.withOpacity(0.3)),
                _progressStat('REFERRAL\nINCOME', _money(plan.totalReferralEarned), isGold: true),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _progressStat(String label, String value, {bool isBlue = false, bool isGold = false}) {
    final valColor = isBlue ? _royal : (isGold ? _gold : _navy);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _slate,
              fontSize: 9,
              height: 1.2,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: valColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // NEXT PAYOUT CARD
  // ==========================================================================

  Widget _nextPayoutCard() {
    final plan = _dashboard!.plan;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, Color(0xFF0F1524)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: _navy.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.access_time_filled_rounded, color: _gold, size: 24),
              ),
              Icon(Icons.waves_rounded, color: Colors.white.withOpacity(0.05), size: 60),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'NEXT PAYOUT IN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            plan.hasPlan ? '${plan.monthsRemaining} MONTHS LEFT' : 'PROCESSING...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'WEEKDAYS ONLY • 09:00 AM',
            style: TextStyle(
              color: _gold,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 28),
          _payoutInfoRow(Icons.star_border_rounded, '${plan.monthlyRate.toStringAsFixed(1)}% OF ELIGIBLE AMOUNT CREDITED MONTHLY'),
          const SizedBox(height: 12),
          _payoutInfoRow(Icons.account_balance_wallet_rounded, 'PAYOUT AMOUNT: ${_money(plan.monthlyPayoutNet)}'),
          const SizedBox(height: 12),
          _payoutInfoRow(Icons.all_inclusive_rounded, '${plan.cashbackPercentage.toStringAsFixed(1)}% OF PLAN COMPLETED'),
        ],
      ),
    );
  }

  Widget _payoutInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white60, size: 16),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // CASHBACK HISTORY SECTION (RESPONSIVE & SCROLLABLE TABLE)
  // ==========================================================================

  Widget _cashbackHistorySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _hairline, width: 2),
        boxShadow: [
          BoxShadow(color: _slate.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Tabs Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _navy,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.show_chart_rounded, color: _gold, size: 20),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CASHBACK HISTORY',
                              style: TextStyle(
                                color: _navy,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '0 ENTRIES FOUND', // Dynamic count goes here
                              style: TextStyle(
                                color: _slate,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _tabButton('ALL', 0),
                      const SizedBox(width: 10),
                      _tabButton('CASHBACK', 1),
                      const SizedBox(width: 10),
                      _tabButton('REFERRAL', 2),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Responsive Table Area
          ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(26), bottomRight: Radius.circular(26)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // Ensure table spans full width on large screens, scrolls on mobile
                  minWidth: MediaQuery.of(context).size.width > 600 
                      ? 550 
                      : MediaQuery.of(context).size.width - 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table Header
                    Container(
                      width: 650, // Fixed total width to force scroll on small screens
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(
                        color: _hairline,
                        border: Border(
                          top: BorderSide(color: _label, width: 0.5),
                          bottom: BorderSide(color: _label, width: 0.5),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 90, child: _TableHeaderText('DATE')),
                          SizedBox(width: 100, child: _TableHeaderText('TYPE')),
                          SizedBox(width: 180, child: _TableHeaderText('DESCRIPTION')),
                          SizedBox(width: 120, child: _TableHeaderText('AMOUNT', alignRight: true)),
                          Expanded(child: _TableHeaderText('STATUS', alignRight: true)),
                        ],
                      ),
                    ),
                    
                    // Table Body (Empty State for now)
                    SizedBox(
                      width: 650,
                      height: 250, // Minimum height for empty state
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.monitor_heart_outlined, color: _label.withOpacity(0.5), size: 64),
                            const SizedBox(height: 20),
                            Text(
                              _getEmptyStateText(),
                              style: const TextStyle(
                                color: _slate,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _gold.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'AWAITING ADMIN APPROVAL TO START PAYOUTS',
                                style: TextStyle(
                                  color: _gold,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // EXAMPLE OF A POPULATED ROW (Uncomment when data is ready)
                    /*
                    _buildTableRow(
                      date: '12 OCT',
                      type: 'CASHBACK',
                      description: 'Monthly Cycle Payout',
                      amount: _money(1500),
                      status: 'CREDITED',
                      isSuccess: true,
                    ),
                    _buildTableRow(
                      date: '10 OCT',
                      type: 'REFERRAL',
                      description: 'Referral Bonus - John D.',
                      amount: _money(500),
                      status: 'PENDING',
                      isSuccess: false,
                    ),
                    */
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for rendering future rows properly aligned with headers
  Widget _buildTableRow({
    required String date,
    required String type,
    required String description,
    required String amount,
    required String status,
    required bool isSuccess,
  }) {
    return Container(
      width: 650,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _hairline, width: 1.5)),
      ),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(date, style: const TextStyle(color: _navy, fontSize: 11, fontWeight: FontWeight.bold))),
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _hairline, borderRadius: BorderRadius.circular(6)),
              child: Text(type, style: const TextStyle(color: _slate, fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ),
          SizedBox(width: 180, child: Text(description, style: const TextStyle(color: _navy, fontSize: 11, fontWeight: FontWeight.w600))),
          SizedBox(
            width: 120,
            child: Text(amount, textAlign: TextAlign.right, style: const TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isSuccess ? Colors.green[700] : Colors.orange[700],
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyStateText() {
    switch (_historyTab) {
      case 1:
        return 'NO CASHBACK TRANSACTIONS';
      case 2:
        return 'NO REFERRAL TRANSACTIONS';
      case 0:
      default:
        return 'NO TRANSACTIONS YET';
    }
  }

  Widget _tabButton(String label, int index) {
    final isSelected = _historyTab == index;
    return InkWell(
      onTap: () => setState(() => _historyTab = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _navy : _hairline,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: _navy.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _slate,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  final String title;
  final bool alignRight;

  const _TableHeaderText(this.title, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        color: AppColors.kTextMuted,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        letterSpacing: 1.2,
      ),
    );
  }
}