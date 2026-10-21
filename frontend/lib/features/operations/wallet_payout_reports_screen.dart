import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

import '../../models/wallet_payout_report_model.dart';
import '../../services/wallet_payout_report_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class WalletPayoutReportsScreen extends StatefulWidget {
  const WalletPayoutReportsScreen({super.key});

  @override
  State<WalletPayoutReportsScreen> createState() => _PayoutReportsScreenState();
}

class _PayoutReportsScreenState extends State<WalletPayoutReportsScreen> {
  final PayoutReportService _service = PayoutReportService();
  final TextEditingController _searchController = TextEditingController();

  PayoutSummary _summary = PayoutSummary.empty();
  List<PayoutChartPoint> _chart = [];
  List<PayoutTransaction> _history = [];

  /// Table status filter: null = all, else 'success' | 'pending' | 'failed'.
  String? _statusFilter;
  static const Map<String?, String> _statusOptions = {
    null: 'ALL PROTOCOL STATUS',
    'success': 'SUCCESS NODE',
    'pending': 'PENDING LOGIC',
    'failed': 'FAILED INTERCEPT',
  };

  bool _loading = true;
  bool _exporting = false;
  String? _error;

  final NumberFormat _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final DateFormat _dateFmt = DateFormat('dd MMM, hh:mm a');

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReport({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final bundle = await _service.fetchReport();
      if (!mounted) return;
      setState(() {
        _summary = bundle.summary;
        _chart = bundle.chart;
        _history = bundle.history;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handleRunDailyProtocol() async {
    // NOTE: no daily-run endpoint was provided alongside payout_reports.php.
    // Wire this to AdminEndpoints.processMonthlyYield (admin/run_daily_payout.php)
    // if that's the intended trigger — left as a refresh + toast for now so the
    // button doesn't silently do nothing.
    await _loadReport(silent: true);
    if (!mounted) return;
    ToastService.show(
      title: 'Protocol Refreshed',
      message: 'Latest payout data has been synced.',
      type: ToastType.success,
    );
  }

  bool _matchesStatus(PayoutTransaction t) {
    final s = t.status.toLowerCase();
    switch (_statusFilter) {
      case 'success':
        return s == 'success' || s == 'completed';
      case 'pending':
        return s == 'pending';
      case 'failed':
        return s == 'failed';
      default:
        return true;
    }
  }

  List<PayoutTransaction> get _filteredHistory {
    final q = _searchController.text.trim().toLowerCase();
    return _history
        .where(_matchesStatus)
        .where((t) =>
            q.isEmpty ||
            t.userName.toLowerCase().contains(q) ||
            t.userEmail.toLowerCase().contains(q) ||
            (t.bankName ?? '').toLowerCase().contains(q) ||
            (t.accountNo ?? '').toLowerCase().contains(q))
        .toList();
  }

  double get _peakYield => _chart.isEmpty ? 0 : _chart.map((p) => p.totalAmount).reduce((a, b) => a > b ? a : b);
  double get _totalPeriod => _chart.fold<double>(0, (acc, p) => acc + p.totalAmount);

  Future<void> _handleExportLedger() async {
    final pending = _history.where((t) => t.status.toLowerCase() == 'pending').toList();

    if (pending.isEmpty) {
      ToastService.show(
        title: 'Nothing to Export',
        message: 'There are no pending payouts to include in an export.',
        type: ToastType.warning,
      );
      return;
    }

    final totalAmount = pending.fold<double>(0, (acc, t) => acc + t.amount);

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'EXPORT LEDGER',
      message:
          'Export ${pending.length} pending payout${pending.length == 1 ? '' : 's'} totalling ${_currency.format(totalAmount)}? '
          'This will mark them as completed on the server.',
      confirmLabel: 'EXPORT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kPrimary,
    );
    if (confirmed != true) return;

    final filename = 'payout_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

    setState(() => _exporting = true);
    try {
      await _service.recordExport(
        filename: filename,
        totalAmount: totalAmount,
        totalRecords: pending.length,
        transactionIds: pending.map((t) => t.id).toList(),
      );
      if (!mounted) return;
      ToastService.show(
        title: 'Export Recorded',
        message: '$filename logged. ${pending.length} payouts marked completed.',
        type: ToastType.success,
      );
      await _loadReport(silent: true);
    } catch (e) {
      if (!mounted) return;
      ToastService.show(title: 'Export Failed', message: e.toString(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadReport(silent: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGlobalSearch(),
                const SizedBox(height: 24),
                if (_error != null) _buildErrorBanner(),
                _buildYieldVolumeHero(),
                const SizedBox(height: 24),
                _buildSummaryCard(
                  title: 'TOTAL CAPITAL DISBURSED',
                  value: _currency.format(_summary.successAmount),
                  subtext: '${_summary.successCount} SUCCESSFUL TRANSMISSIONS',
                  icon: Icons.attach_money,
                  iconColor: AppColors.goldColor,
                  backgroundColor: AppColors.goldBg,
                  borderColor: AppColors.goldBorder,
                  badgeBgColor: AppColors.goldBadgeBg,
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  title: 'PENDING AUTHORIZATIONS',
                  value: _currency.format(_summary.pendingAmount),
                  subtext: '${_summary.pendingCount} AWAITING PROTOCOL',
                  icon: Icons.schedule,
                  iconColor: const Color(0xFF3B82F6),
                  backgroundColor: const Color(0xFFF0F7FF),
                  borderColor: const Color(0xFFBFDBFE),
                  badgeBgColor: const Color(0xFFDBEAFE),
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  title: 'SYSTEM INTERCEPTS',
                  value: _currency.format(_summary.failedAmount),
                  subtext: '${_summary.failedCount} FAILED NODE MATCHES',
                  icon: Icons.error_outline,
                  iconColor: const Color(0xFFEF4444),
                  backgroundColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFECACA),
                  badgeBgColor: const Color(0xFFFEE2E2),
                ),
                const SizedBox(height: 24),
                _buildRegistryCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search users, banks, accounts...',
          hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFCA5A5))),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_error ?? 'Something went wrong.', style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600))),
          TextButton(onPressed: () => _loadReport(), child: const Text('RETRY', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  Widget _buildYieldVolumeHero() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kPrimary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppColors.kPrimary.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('YIELD VOLUME NODE',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text('LAST 15 DAYS PERFORMANCE LEDGER',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.7), letterSpacing: 1)),
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _handleRunDailyProtocol,
                    icon: _loading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.play_arrow, size: 16),
                    label: const Text('REFRESH LEDGER', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldColor,
                      foregroundColor: AppColors.kPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.star, size: 10, color: AppColors.goldColor),
                    label: const Text('LIVE PULSE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: _loading
                ? const Center(child: AppLoader())
                : _chart.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.show_chart, color: AppColors.goldColor, size: 32),
                          const SizedBox(height: 16),
                          const Text('LIVE DATABASE LINK ESTABLISHED',
                              style: TextStyle(color: AppColors.goldColor, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 6),
                          Text('AWAITING TRANSMISSION NODES...',
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1),
                              textAlign: TextAlign.center),
                        ],
                      )
                    : CustomPaint(size: Size.infinite, painter: _PayoutChartPainter(_chart)),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _buildHeroStat('PEAK YIELD', _currency.format(_peakYield))),
              Expanded(child: _buildHeroStat('TOTAL PERIOD', _currency.format(_totalPeriod))),
              Expanded(child: _buildHeroStat('SUCCESSFUL PAYOUTS', '${_summary.successCount}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required Color badgeBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderColor)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.star, size: 6, color: iconColor),
                  const SizedBox(width: 6),
                  Text(subtext, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: iconColor)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistryCard() {
    final rows = _filteredHistory;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: LayoutBuilder(builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 500;

              Widget titles = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.kPrimary, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.show_chart, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GLOBAL PAYOUT REGISTRY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kPrimary)),
                        const SizedBox(height: 2),
                        Text('LIVE MULTI-NODE TRANSACTION HISTORY',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              );

              final exportButton = ElevatedButton.icon(
                    onPressed: _exporting ? null : _handleExportLedger,
                    icon: _exporting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download, size: 14),
                    label: const Text('EXPORT LEDGER', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );

              // Status filter sits beside EXPORT LEDGER; stacks on phones.
              Widget actions = isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [_buildStatusFilter(rows.length), const SizedBox(height: 8), exportButton],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [_buildStatusFilter(rows.length), const SizedBox(width: 12), exportButton],
                    );

              if (isMobile) {
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [titles, const SizedBox(height: 20), actions]);
              }
              return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: titles), actions]);
            }),
          ),
          const Divider(height: 1, color: AppColors.kBorder),
          if (_loading)
            const Padding(padding: EdgeInsets.all(48), child: Center(child: AppLoader()))
          else if (rows.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.show_chart, size: 40, color: const Color(0xFFCBD5E1).withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                      _statusFilter == null
                          ? 'ZERO ANOMALIES DETECTED IN CURRENT PROTOCOL MATRIX'
                          : 'NO ${_statusOptions[_statusFilter]} RECORDS IN CURRENT PROTOCOL MATRIX',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1),
                      textAlign: TextAlign.center),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 48,
                headingRowHeight: 56,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 64,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                dividerThickness: 0,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 10, letterSpacing: 1.5),
                columns: const [
                  DataColumn(label: Text('INVESTOR\nENTITY')),
                  DataColumn(label: Text('BANKING\nNODE')),
                  DataColumn(label: Text('TRANSMISSION\nVALUE')),
                  DataColumn(label: Text('PROTOCOL\nSTATUS')),
                  DataColumn(label: Text('TIMESTAMP')),
                ],
                rows: rows.map((t) {
                  return DataRow(cells: [
                    DataCell(Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(t.initial, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.userName, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kPrimary, fontSize: 12)),
                            Text(t.userEmail, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                          ],
                        ),
                      ],
                    )),
                    DataCell(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(t.bankName ?? 'No bank on file', style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Color(0xFF64748B), fontSize: 11)),
                        Text(t.maskedAccount, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                      ],
                    )),
                    DataCell(Text(_currency.format(t.amount), style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kPrimary, fontSize: 13))),
                    DataCell(_buildStatusBadge(t.status)),
                    DataCell(Text(t.createdAt != null ? _dateFmt.format(t.createdAt!) : '-', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
                  ]);
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Gold-bordered status dropdown; shows how many rows match.
  Widget _buildStatusFilter(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.goldColor.withValues(alpha: 0.6), width: 1.4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _statusFilter,
          isDense: false,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.unfold_more, size: 16, color: AppColors.kTextMuted),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kPrimary, letterSpacing: 0.5),
          onChanged: (v) => setState(() => _statusFilter = v),
          selectedItemBuilder: (_) => [
            for (final label in _statusOptions.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 14, color: AppColors.kTextMuted),
                  const SizedBox(width: 8),
                  Text('$label · $count'),
                  const SizedBox(width: 6),
                ],
              ),
          ],
          items: [
            for (final e in _statusOptions.entries)
              DropdownMenuItem<String?>(value: e.key, child: Text(e.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF16A34A);
        break;
      case 'failed':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        break;
      case 'pending':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
    );
  }
}

/// Simple line chart of daily disbursement totals, drawn against real
/// [PayoutChartPoint] data (no external chart package required).
class _PayoutChartPainter extends CustomPainter {
  final List<PayoutChartPoint> points;
  _PayoutChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxVal = points.map((p) => p.totalAmount).reduce((a, b) => a > b ? a : b);
    final minVal = points.map((p) => p.totalAmount).reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs() < 0.01 ? 1.0 : (maxVal - minVal);

    final path = Path();
    final n = points.length;
    for (int i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : size.width * (i / (n - 1));
      final normalized = (points[i].totalAmount - minVal) / range;
      final y = size.height * (1 - normalized) * 0.85 + size.height * 0.075;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.goldColor.withOpacity(0.25),
          AppColors.goldColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.goldColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _PayoutChartPainter oldDelegate) => oldDelegate.points != points;
}