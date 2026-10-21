import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/report_components.dart';
import '../../models/cashback_reports_model.dart';
import '../../services/cashback_reports_service.dart';

const _kNavy = ReportColors.navy;
const _kGold = ReportColors.gold;
const _kGoldCard = ReportColors.goldCard;
const _kMuted = ReportColors.muted;
const _kRed = ReportColors.red;
const _kTile = ReportColors.tile;

enum _HistoryTab { transactions, cycles }

class CashbackReportsScreen extends StatefulWidget {
  const CashbackReportsScreen({super.key});

  @override
  State<CashbackReportsScreen> createState() => _CashbackReportsScreenState();
}

class _CashbackReportsScreenState extends State<CashbackReportsScreen> {
  final CashbackService _service = CashbackService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  CashbackReport _report = CashbackReport.empty();
  DateTime? _lastSync;

  _HistoryTab _tab = _HistoryTab.transactions;
  String _searchQuery = '';
  String? _statusFilter; // null = all nodes

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  // --- Data loading ---

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await _service.fetchReport();
      if (!mounted) return;
      setState(() {
        _report = report;
        _lastSync = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _load();
    if (!mounted) return;
    ToastService.show(
      title: _error == null ? 'Refreshed' : 'Refresh failed',
      message: _error ?? 'Cashback ledger synced from the server.',
      type: _error == null ? ToastType.success : ToastType.error,
    );
  }

  // --- Filtering ---

  bool _matches(List<String?> fields) {
    if (_searchQuery.isEmpty) return true;
    return fields.whereType<String>().join(' ').toLowerCase().contains(_searchQuery);
  }

  List<CashbackTransaction> get _filteredTransactions => _report.transactions
      .where((t) => _statusFilter == null || t.status == _statusFilter)
      .where((t) => _matches([t.userName, t.userEmail, '#ID-${t.id}', t.description]))
      .toList();

  List<CashbackCycle> get _filteredCycles => _report.cycles
      .where((c) => _statusFilter == null || c.status == _statusFilter)
      .where((c) => _matches([c.userName, c.userEmail, c.transactionId, '#CY-${c.id}', c.productName, c.assetType]))
      .toList();

  List<String> get _availableStatuses {
    final statuses = _tab == _HistoryTab.transactions
        ? _report.transactions.map((t) => t.status)
        : _report.cycles.map((c) => c.status);
    return statuses.toSet().toList()..sort();
  }

  void _switchTab(_HistoryTab tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      _statusFilter = null;
    });
  }

  // --- Export ---

  Future<void> _handleExportLedger() async {
    final isTxn = _tab == _HistoryTab.transactions;
    final count = isTxn ? _filteredTransactions.length : _filteredCycles.length;
    if (count == 0) {
      ToastService.show(title: 'Nothing to export', message: 'There are no rows in the current view.', type: ToastType.info);
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'EXPORT LEDGER',
      message: 'Copy a CSV of the $count ${isTxn ? 'transaction' : 'cycle'}(s) currently in view to your clipboard?',
      confirmLabel: 'EXPORT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: _kNavy,
    );
    if (confirmed != true) return;

    await Clipboard.setData(ClipboardData(text: isTxn ? _transactionsCsv() : _cyclesCsv()));
    if (!mounted) return;
    ToastService.show(title: 'Copied to clipboard', message: '$count row(s) exported as CSV.', type: ToastType.success);
  }

  String _esc(Object? v) => '"${(v ?? '').toString().replaceAll('"', '""')}"';

  String _transactionsCsv() {
    final b = StringBuffer('ID,Name,Email,Net Amount,Gross,TDS,Charges,Status,Created At\n');
    for (final t in _filteredTransactions) {
      b.writeln([
        t.id,
        _esc(t.userName),
        _esc(t.userEmail),
        t.amount.toStringAsFixed(2),
        t.grossAmount?.toStringAsFixed(2) ?? '',
        t.tdsAmount?.toStringAsFixed(2) ?? '',
        t.chargesAmount?.toStringAsFixed(2) ?? '',
        t.status,
        t.createdAt?.toIso8601String() ?? '',
      ].join(','));
    }
    return b.toString();
  }

  String _cyclesCsv() {
    final b = StringBuffer('ID,Name,Email,Reference,Asset,Weight (g),Total Value,Daily Payout,Paid,Status,Created At\n');
    for (final c in _filteredCycles) {
      b.writeln([
        c.id,
        _esc(c.userName),
        _esc(c.userEmail),
        _esc(c.transactionId),
        _esc(c.assetType == 'product' ? c.productName : c.assetType),
        c.weight.toStringAsFixed(3),
        c.totalValue.toStringAsFixed(2),
        c.dailyPayout.toStringAsFixed(2),
        c.paidAmount.toStringAsFixed(2),
        c.status,
        c.createdAt?.toIso8601String() ?? '',
      ].join(','));
    }
    return b.toString();
  }

  // --- Formatting ---

  String _inr(double v) => formatInr(v);

  String _pct(double part, double whole) => whole > 0 ? '${(part / whole * 100).toStringAsFixed(1)}%' : '0.0%';

  String _cycleStatusLabel(String status) => status == 'pending' ? 'PENDING REVIEW' : status.toUpperCase();

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kTile,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 600;
              final pad = isMobile ? 16.0 : 24.0;
              final gap = isMobile ? 16.0 : 24.0;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(pad),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[ReportErrorBanner(message: _error!, onRetry: _load), SizedBox(height: gap)],
                        ReportHeader(
                          navyTitle: 'CASHBACK',
                          goldTitle: 'REPORTS',
                          isMobile: isMobile,
                          loading: _loading,
                          lastSync: _lastSync,
                          onRefresh: _handleRefresh,
                        ),
                        SizedBox(height: gap + 8),
                        ReportOverviewRow(
                          width: width - pad * 2,
                          gap: gap,
                          velocity: ReportVelocityCard(
                            values: _report.chart.map((p) => p.totalAmount).toList(),
                            loading: _loading,
                            isMobile: isMobile,
                            aggregateValue: _inr(_report.chart.fold<double>(0, (s, p) => s + p.totalAmount)),
                            nodeCount: '${_report.summary.totalCount}',
                            healthy: _error == null,
                          ),
                          efficiency: ReportEfficiencyCard(efficiency: _report.summary.efficiency),
                          registry: ReportRegistryCard(registryCount: _report.summary.registryCount, onExport: _loading ? null : _handleExportLedger),
                        ),
                        SizedBox(height: gap),
                        _buildNavyStats(width - pad * 2),
                        SizedBox(height: gap),
                        _buildDeductionBreakdown(width - pad * 2, isMobile),
                        SizedBox(height: gap),
                        _buildCyclePanels(width - pad * 2, gap),
                        SizedBox(height: gap),
                        _buildProtocolHistory(width - pad * 2, isMobile),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Navy stat cards ---

  Widget _buildNavyStats(double width) {
    final s = _report.summary;
    final c = _report.cyclesSummary;
    double ratio(num part, num whole) => whole > 0 ? (part / whole).clamp(0, 1).toDouble() : 0;

    final cards = [
      _navyStatCard('MONTHLY CASHBACK', "THIS MONTH'S LIVE VALUE", s.monthlyAmount, Icons.bolt, ratio(s.monthlyAmount, s.totalAmount)),
      _navyStatCard('PENDING CASHBACK', 'AWAITING VALIDATION', s.pendingAmount, Icons.schedule, ratio(s.pendingAmount, s.totalAmount)),
      _navyStatCard('COMPLETED CYCLES', 'SUCCESSFULLY CLOSED', c.completedCycles.toDouble(), Icons.check_circle_outline, ratio(c.completedCycles, c.totalCycles), isCount: true),
      _navyStatCard('TOTAL PAYOUT', 'LIFETIME DISTRIBUTION', s.successAmount, Icons.workspace_premium_outlined, ratio(s.successAmount, s.totalAmount)),
    ];
    final columns = width < 600 ? 1 : (width < 1000 ? 2 : 4);
    return _grid(cards, columns, spacing: 16);
  }

  Widget _navyStatCard(String label, String subtitle, double value, IconData icon, double progress, {bool isCount = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kNavy,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _kNavy.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFFBBF24), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('MARKET LIVE', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 6, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Icon(icon, color: const Color(0xFFFBBF24), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.6), letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 6, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.35), letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                if (!isCount) TextSpan(text: '₹ ', style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.5))),
                TextSpan(text: isCount ? value.toInt().toString() : formatInrDigits(value)),
              ]),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(_kGoldCard),
            ),
          ),
        ],
      ),
    );
  }

  // --- Deduction breakdown ---

  Widget _buildDeductionBreakdown(double width, bool isMobile) {
    final s = _report.summary;
    final tiles = [
      _deductionTile('GROSS INCENTIVE', _inr(s.grossAmount), 'BEFORE DEDUCTIONS', _kNavy, 1),
      _deductionTile('TDS WITHHELD', _inr(s.tdsAmount), '${_pct(s.tdsAmount, s.grossAmount)} OF GROSS', _kRed, 0.15),
      _deductionTile('SERVICE CHARGES', _inr(s.chargesAmount), '${_pct(s.chargesAmount, s.grossAmount)} OF GROSS', _kRed, 0.15),
      _deductionTile('TOTAL DEDUCTION', _inr(s.totalDeduction), '${_pct(s.totalDeduction, s.grossAmount)} WITHHELD', _kRed, 0.25),
      _deductionTile('NET CREDITED', _inr(s.netAmount), 'PAID TO WALLETS', _kGoldCard, 0.85),
    ];
    final columns = width < 520 ? 1 : (width < 900 ? 2 : (width < 1150 ? 3 : 5));

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: reportWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReportCardTitle('DEDUCTION BREAKDOWN'),
                    SizedBox(height: 4),
                    ReportCardSubtitle('AUTO-COMPUTED TDS + SERVICE CHARGES · LIVE FROM LEDGER'),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.trending_down, color: _kRed, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _grid(tiles, columns, spacing: 12),
        ],
      ),
    );
  }

  Widget _deductionTile(String label, String value, String caption, Color color, double barFraction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kTile, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: _kMuted, letterSpacing: 1)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: color)),
          ),
          const SizedBox(height: 8),
          FractionallySizedBox(
            widthFactor: barFraction,
            alignment: Alignment.centerLeft,
            child: Container(height: 2, color: color),
          ),
          const SizedBox(height: 10),
          Text(caption, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: _kMuted, letterSpacing: 1)),
        ],
      ),
    );
  }

  // --- Active yield / completion panels ---

  Widget _buildCyclePanels(double width, double gap) {
    final active = _buildActiveYieldCard(width < 600);
    final completion = _buildCompletionCard(width < 600);
    if (width < 800) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [active, SizedBox(height: gap), completion]);
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: active), SizedBox(width: gap), Expanded(child: completion)],
      ),
    );
  }

  Widget _buildActiveYieldCard(bool isMobile) {
    final c = _report.cyclesSummary;
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: reportWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelHeader('ACTIVE YIELD PROTOCOL', 'ONGOING CASHBACK CYCLES', Icons.bolt, _kNavy, _kMuted, const Color(0xFFFFFBEB), _kGold),
          const SizedBox(height: 20),
          _bigCountRow('${c.activeCycles}', _kNavy, 'Live Processing', Icons.show_chart, const Color(0xFFFFFBEB), _kGold),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _miniBox('DAILY LIABILITY', _inr(c.dailyLiability), dark: false)),
              const SizedBox(width: 12),
              Expanded(child: _miniBox('PENDING VERIFICATION', '${c.pendingCycles} Cycles', dark: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(bool isMobile) {
    final c = _report.cyclesSummary;
    final txns = _report.transactions;
    final completedTxns = txns.where((t) => t.status == 'completed').length;
    final successRate = txns.isEmpty ? 0.0 : completedTxns / txns.length * 100;
    final closed = _report.cycles.where((cy) => cy.status == 'completed').toList();
    final avgPayout = closed.isEmpty ? 0.0 : closed.fold<double>(0, (s, cy) => s + cy.paidAmount) / closed.length;

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: _kNavy,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: _kNavy.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelHeader('PROTOCOL COMPLETION', 'SUCCESSFULLY CLOSED CYCLES', Icons.check_circle_outline, const Color(0xFFFBBF24),
              Colors.white.withValues(alpha: 0.45), Colors.white.withValues(alpha: 0.1), const Color(0xFFFBBF24)),
          const SizedBox(height: 20),
          _bigCountRow('${c.completedCycles}', Colors.white, 'Mission Success', Icons.emoji_events_outlined, Colors.white.withValues(alpha: 0.1), const Color(0xFFFBBF24)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _miniBox('SUCCESS RATE', '${successRate.toStringAsFixed(1)}%', dark: true)),
              const SizedBox(width: 12),
              Expanded(child: _miniBox('AVERAGE PAYOUT', _inr(avgPayout), dark: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panelHeader(String title, String subtitle, IconData icon, Color titleColor, Color subColor, Color iconBg, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: titleColor, letterSpacing: -0.3)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: subColor, letterSpacing: 1)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
      ],
    );
  }

  Widget _bigCountRow(String count, Color color, String chip, IconData chipIcon, Color chipBg, Color chipFg) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(count, style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: color, height: 1)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: chipFg.withValues(alpha: 0.3))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(chipIcon, size: 10, color: chipFg),
              const SizedBox(width: 4),
              Text(chip, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, color: chipFg)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniBox(String label, String value, {required bool dark}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.12) : AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: dark ? Colors.white.withValues(alpha: 0.5) : _kMuted, letterSpacing: 1)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: dark ? Colors.white : _kNavy)),
          ),
        ],
      ),
    );
  }

  // --- Protocol history (TRANSACTIONS / CYCLES) ---

  Widget _buildProtocolHistory(double width, bool isMobile) {
    final isTxn = _tab == _HistoryTab.transactions;
    final rows = isTxn
        ? _filteredTransactions
            .map((t) => ReportHistoryRow(
                  name: t.userName,
                  email: t.userEmail,
                  ref: '#ID-${t.id}',
                  value: _inr(t.amount),
                  valueDetail: deductionLine(gross: t.grossAmount, tds: t.tdsAmount, charges: t.chargesAmount),
                  statusLabel: t.status.toUpperCase(),
                  statusKey: t.status,
                  timestamp: t.createdAt,
                ))
            .toList()
        : _filteredCycles
            .map((c) => ReportHistoryRow(
                  name: c.userName,
                  email: c.userEmail,
                  ref: c.transactionId ?? '#CY-${c.id}',
                  refDetail: _cycleAssetLine(c),
                  value: _inr(c.totalValue),
                  valueDetail: 'DAILY: ${_inr(c.dailyPayout)}',
                  valueDetailColor: _kMuted,
                  statusLabel: _cycleStatusLabel(c.status),
                  statusKey: c.status,
                  timestamp: c.createdAt,
                ))
            .toList();

    return ReportHistoryCard(
      width: width,
      isMobile: isMobile,
      loading: _loading,
      searchController: _searchController,
      rows: rows,
      tabs: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tabChip('TRANSACTIONS', _HistoryTab.transactions),
          const SizedBox(width: 8),
          _tabChip('CYCLES', _HistoryTab.cycles),
        ],
      ),
      filter: ReportStatusFilter(
        selected: _statusFilter,
        options: {for (final s in _availableStatuses) s: isTxn ? s.toUpperCase() : _cycleStatusLabel(s)},
        onChanged: (v) => setState(() => _statusFilter = v),
      ),
    );
  }

  Widget _tabChip(String label, _HistoryTab tab) {
    final active = _tab == tab;
    return InkWell(
      onTap: () => _switchTab(tab),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _kGoldCard : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: active ? [BoxShadow(color: _kGoldCard.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: active ? Colors.white : const Color(0xFF475569), letterSpacing: 1.5),
        ),
      ),
    );
  }

  String? _cycleAssetLine(CashbackCycle c) {
    if (c.assetType == 'product') return c.productName == null ? 'PRODUCT' : 'PRODUCT (${c.productName!.toUpperCase()})';
    return '${c.assetType.toUpperCase()} (${c.weight.toStringAsFixed(3)}G)';
  }

  // --- Small shared pieces ---

  /// Equal-width, equal-height grid without GridView's fixed aspect ratio,
  /// so cards grow with their content instead of overflowing.
  Widget _grid(List<Widget> children, int columns, {double spacing = 16}) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final end = math.min(i + columns, children.length);
      final cells = <Widget>[];
      for (var j = i; j < i + columns; j++) {
        if (j > i) cells.add(SizedBox(width: spacing));
        cells.add(Expanded(child: j < end ? children[j] : const SizedBox.shrink()));
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
      rows.add(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}
