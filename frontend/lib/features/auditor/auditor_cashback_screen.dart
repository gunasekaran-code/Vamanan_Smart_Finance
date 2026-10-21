import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/auditor_cashback_model.dart';
import '../../services/auditor_cashback_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class AuditorCashbackScreen extends StatefulWidget {
  /// Pass the auditor's own user id if this screen should be scoped to one
  /// investor (matches the `user_id=123` examples). Leave null for the
  /// platform-wide view.
  final int? userId;

  const AuditorCashbackScreen({super.key, this.userId});

  @override
  State<AuditorCashbackScreen> createState() => _AuditorCashbackScreenState();
}

class _AuditorCashbackScreenState extends State<AuditorCashbackScreen> {
  String _selectedFilter = 'ALL'; // ALL | CASHBACK | REFERRAL

  bool _loadingSummary = true;
  bool _loadingLedger = true;
  String? _error;

  CashbackSummary _summary = CashbackSummary.empty();
  LedgerResponse _ledger = LedgerResponse.empty();
  double _todayEarning = 0;

  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  String? get _categoryParam {
    switch (_selectedFilter) {
      case 'CASHBACK':
        return 'cashback';
      case 'REFERRAL':
        return 'referral';
      default:
        return null; // ALL
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _loadingSummary = true;
      _loadingLedger = true;
      _error = null;
    });
    await Future.wait([_loadSummary(), _loadLedger()]);
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await AuditorCashbackService.fetchSummary();
      final today = await AuditorCashbackService.fetchTodayEarning(userId: widget.userId);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _todayEarning = today;
        _loadingSummary = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingSummary = false;
        _error = 'Failed to load cashback summary';
      });
    }
  }

  Future<void> _loadLedger() async {
    setState(() => _loadingLedger = true);
    try {
      final ledger = await AuditorCashbackService.fetchLedger(
        category: _categoryParam,
        userId: widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _ledger = ledger;
        _loadingLedger = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLedger = false;
        _error = 'Failed to load cashback history';
      });
    }
  }

  Future<void> _handleRefresh() async {
    ToastService.show(
      title: 'Refreshing',
      message: 'Syncing latest cashback data from the server...',
      type: ToastType.info,
    );
    await _loadAll();
  }

  void _setFilter(String filter) {
    if (_selectedFilter == filter) return;
    setState(() => _selectedFilter = filter);
    _loadLedger();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null,
      children: [
        Center(
          child: Container(
                        constraints: const BoxConstraints(maxWidth: 800), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _StatCards2x2Grid(
                  loading: _loadingSummary,
                  payoutsGross: _summary.payoutsGross,
                  payoutsNet: _summary.payoutsNet,
                  tdsWithheld: _summary.tdsWithheld,
                  cashbackNet: _summary.cashbackNet,
                  referralNet: _summary.referralNet,
                  todayEarning: _todayEarning,
                  currency: _currency,
                ),
                const SizedBox(height: 24),
                _buildPlatformStatusCard(),
                const SizedBox(height: 24),
                _buildYieldRunsCard(),
                const SizedBox(height: 24),
                _buildCashbackHistoryTable(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.star, color: AppColors.goldColor, size: 10),
            SizedBox(width: 6),
            Text(
              'CASHBACK PLAN',
              style: TextStyle(color: AppColors.goldColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2.0),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'MY CASHBACK',
          style: TextStyle(color: AppColors.kPrimaryDark, fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0),
        ),
        const SizedBox(height: 4),
        const Text(
          '10% MONTHLY PAYOUT • 10 MONTHS = 100% — TRACKED LIVE',
          style: TextStyle(color: AppColors.kTextMuted, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _handleRefresh,
          icon: const Icon(Icons.sync, size: 16),
          label: const Text('REFRESH', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1.0)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.kTextDark,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.kBorder, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // PLATFORM STATUS (replaces the old fake "cycle progress" bar — summary.php
  // has no per-user month counter, so this surfaces the real aggregate stats)
  // ==========================================================================
  Widget _buildPlatformStatusCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PLATFORM STATUS', style: TextStyle(color: AppColors.kPrimaryDark, fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.kBorder)),
                child: Text(
                  '${_summary.activeCycles} ACTIVE',
                  style: const TextStyle(color: AppColors.kTextMuted, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          _loadingSummary
              ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator()))
              : Row(
                  children: [
                    Expanded(child: _buildProgressStat('WALLET LIABILITY', _currency.format(_summary.walletLiability), const Color(0xFF3B82F6))),
                    Expanded(child: _buildProgressStat('CUSTOMERS', '${_summary.customers}', AppColors.kPrimaryDark)),
                    Expanded(child: _buildProgressStat('TRANSACTIONS', '${_summary.transactions}', AppColors.goldColor)),
                  ],
                ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.kBorder, thickness: 1.5),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildProgressStat('WITHDRAWN (PAID)', _currency.format(_summary.withdrawnPaid), const Color(0xFF3B82F6))),
              Expanded(child: _buildProgressStat('WITHDRAWALS PENDING', _currency.format(_summary.withdrawPending), AppColors.kPrimaryDark)),
              Expanded(child: _buildProgressStat('TDS WITHHELD', _currency.format(_summary.tdsWithheld), AppColors.goldColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.kTextMuted, fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, textAlign: TextAlign.center, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  // ==========================================================================
  // LAST YIELD RUNS (real last_daily_run / last_monthly_run from summary.php)
  // ==========================================================================
  Widget _buildYieldRunsCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.kPrimaryDark,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppColors.kPrimaryDark.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, bottom: -20,
            child: Icon(Icons.schedule, size: 180, color: Colors.white.withOpacity(0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.access_time, color: AppColors.goldColor, size: 16),
              ),
              const SizedBox(height: 24),
              const Text('YIELD RUN STATUS', style: TextStyle(color: AppColors.kTextMuted, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              _buildPayoutInfoRow(Icons.event_repeat, 'LAST DAILY RUN: ${_summary.lastDailyRun ?? 'NEVER'}', AppColors.goldColor),
              const SizedBox(height: 12),
              _buildPayoutInfoRow(Icons.calendar_month, 'LAST MONTHLY RUN: ${_summary.lastMonthlyRun ?? 'NEVER'}', Colors.white70),
              const SizedBox(height: 12),
              _buildPayoutInfoRow(Icons.star_border, '1% OF INVESTED AMOUNT CREDITED DAILY', Colors.white70),
              const SizedBox(height: 12),
              _buildPayoutInfoRow(Icons.event_busy_outlined, 'NO PAYOUTS ON WEEKENDS & HOLIDAYS', Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutInfoRow(IconData icon, String text, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // CASHBACK HISTORY TABLE — backed by /auditor/ledger.php
  // ==========================================================================
  Widget _buildCashbackHistoryTable(BuildContext context) {
    final rows = _ledger.rows;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.kPrimaryDark, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.show_chart, color: AppColors.goldColor, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CASHBACK HISTORY', style: TextStyle(color: AppColors.kPrimaryDark, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text(
                          '${_ledger.summary.shown} ENTRIES FOUND',
                          style: const TextStyle(color: AppColors.kTextMuted, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterPill('ALL'),
                      _buildFilterPill('CASHBACK'),
                      _buildFilterPill('REFERRAL'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 2, color: Color(0xFFF1F5F9)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width > 800 ? 800 : MediaQuery.of(context).size.width - 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                    child: Row(
                      children: [
                        _buildHeaderCell('DATE', width: 100),
                        _buildHeaderCell('TYPE', width: 120),
                        _buildHeaderCell('DESCRIPTION', width: 220),
                        _buildHeaderCell('AMOUNT', width: 100),
                        _buildHeaderCell('STATUS', width: 100),
                      ],
                    ),
                  ),
                  if (_loadingLedger)
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 800 ? 800 : MediaQuery.of(context).size.width - 64,
                      height: 250,
                      child: const Center(child: AppLoader()),
                    )
                  else if (rows.isEmpty)
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 800 ? 800 : MediaQuery.of(context).size.width - 64,
                      height: 250,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.show_chart_rounded, size: 64, color: Color(0xFFE2E8F0)),
                          SizedBox(height: 16),
                          Text('NO TRANSACTIONS YET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
                        ],
                      ),
                    )
                  else
                    ...rows.map((t) => _buildRow(t)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(LedgerTransaction t) {
    final amountColor = t.isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final amountText = '${t.isCredit ? '+' : '-'}${_currency.format(t.amount)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(_dateFmt.format(t.createdAt), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.kTextDark))),
          SizedBox(width: 120, child: Text(t.category.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kTextMuted, letterSpacing: 0.5))),
          SizedBox(width: 220, child: Text(t.description, style: const TextStyle(fontSize: 11, color: AppColors.kTextDark), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 100, child: Text(amountText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: amountColor))),
          SizedBox(width: 100, child: _buildStatusBadge(t.status)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isDone = status.toLowerCase() == 'completed';
    final color = isDone ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: color)),
    );
  }

  Widget _buildFilterPill(String title) {
    final isActive = _selectedFilter == title;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => _setFilter(title),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.kPrimaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? AppColors.kPrimaryDark : AppColors.kBorder),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.kTextMuted,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, {required double width}) {
    return SizedBox(
      width: width,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
    );
  }
}

// ============================================================================
// 2x2 STAT CARDS — now driven by real summary.php values
// ============================================================================
class _StatCards2x2Grid extends StatelessWidget {
  final bool loading;
  final double payoutsGross;
  final double payoutsNet;
  final double tdsWithheld;
  final double cashbackNet;
  final double referralNet;
  final double todayEarning;
  final NumberFormat currency;

  const _StatCards2x2Grid({
    required this.loading,
    required this.payoutsGross,
    required this.payoutsNet,
    required this.tdsWithheld,
    required this.cashbackNet,
    required this.referralNet,
    required this.todayEarning,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 380;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: isSmallMobile ? 8.0 : 16.0,
      crossAxisSpacing: isSmallMobile ? 8.0 : 16.0,
      childAspectRatio: isSmallMobile ? 0.75 : 1.05,
      children: [
        _CashbackStatCard(
          label: 'TOTAL PAID (GROSS)',
          value: loading ? '…' : currency.format(payoutsGross),
          icon: Icons.trending_up,
          subText: loading ? '' : 'NET: ${currency.format(payoutsNet)} • TDS: ${currency.format(tdsWithheld)}',
          color: Colors.white,
          backgroundColor: AppColors.kPrimaryDark,
          borderColor: AppColors.kPrimaryDark,
          iconBg: Colors.white.withOpacity(0.1),
          subTextColor: Colors.white70,
        ),
        _CashbackStatCard(
          label: 'CASHBACK PAID',
          value: loading ? '…' : currency.format(cashbackNet),
          icon: Icons.bolt,
          subText: 'NET, ALL TIME',
          color: AppColors.goldColor,
          backgroundColor: Colors.white,
          borderColor: AppColors.kBorder,
          iconBg: AppColors.goldBadgeBg,
          subTextColor: const Color(0xFFCBD5E1),
        ),
        _CashbackStatCard(
          label: 'REFERRAL PAID',
          value: loading ? '…' : currency.format(referralNet),
          icon: Icons.card_giftcard,
          subText: 'NET, ALL TIME',
          color: AppColors.kPrimaryDark,
          backgroundColor: Colors.white,
          borderColor: AppColors.kBorder,
          iconBg: AppColors.goldBadgeBg,
          subTextColor: const Color(0xFFCBD5E1),
          iconColor: AppColors.goldColor,
        ),
        _CashbackStatCard(
          label: 'TODAY\'S EARNING',
          value: loading ? '…' : currency.format(todayEarning),
          icon: Icons.payments_outlined,
          subText: 'CREDITED TODAY',
          color: AppColors.kPrimaryDark,
          backgroundColor: Colors.white,
          borderColor: AppColors.kBorder,
          iconBg: const Color(0xFFEFF6FF),
          subTextColor: const Color(0xFFCBD5E1),
          iconColor: const Color(0xFF3B82F6),
        ),
      ],
    );
  }
}

class _CashbackStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String subText;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBg;
  final Color subTextColor;
  final Color? iconColor;

  const _CashbackStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.subText,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBg,
    required this.subTextColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [if (backgroundColor == Colors.white) BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor ?? color, size: 16),
          ),
          const Spacer(),
          Text(label, style: TextStyle(color: backgroundColor == Colors.white ? AppColors.kTextMuted : Colors.white70, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 8),
          Text(subText, style: TextStyle(color: subTextColor, fontSize: 7, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}