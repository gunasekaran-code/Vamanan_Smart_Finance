import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

import '../../models/investment_report_model.dart';
import '../../services/investment_report_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class InvestmentReportsScreen extends StatefulWidget {
  const InvestmentReportsScreen({super.key});

  @override
  State<InvestmentReportsScreen> createState() => _InvestmentReportsScreenState();
}

class _InvestmentReportsScreenState extends State<InvestmentReportsScreen>
    with SingleTickerProviderStateMixin {
  final InvestmentService _service = InvestmentService();
  final TextEditingController _registrySearchController = TextEditingController();
  late final TabController _tabController;

  List<Investment> _pending = [];
  List<Investment> _history = [];

  bool _loading = true;
  String? _error;
  final Set<int> _actionInFlight = {}; // cycleIds currently being approved/rejected

  final NumberFormat _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final DateFormat _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _registrySearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        _service.fetchPendingInvestments(),
        _service.fetchInvestmentHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        _pending = results[0];
        _history = results[1];
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

  Future<void> _handleRefreshProtocol() async {
    await _loadAll(silent: true);
    if (!mounted) return;
    if (_error == null) {
      ToastService.show(
        title: 'Protocol Refreshed',
        message: 'Investment intelligence data synced with the backend.',
        type: ToastType.success,
      );
    } else {
      ToastService.show(
        title: 'Refresh Failed',
        message: _error!,
        type: ToastType.error,
      );
    }
  }

  Future<void> _handleDecision(Investment inv, {required bool approve}) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: approve ? 'APPROVE INVESTMENT' : 'REJECT INVESTMENT',
      message: approve
          ? 'Activate this investment for ${inv.userName}? This will start their monthly payouts and pay any eligible referral commission.'
          : 'Reject this investment for ${inv.userName}? This cannot be undone from here.',
      confirmLabel: approve ? 'APPROVE' : 'REJECT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: approve ? const Color(0xFF1E3A8A) : const Color(0xFFDC2626),
    );

    if (confirmed != true) return;

    setState(() => _actionInFlight.add(inv.cycleId));
    try {
      await _service.decideInvestment(cycleId: inv.cycleId, approve: approve);
      if (!mounted) return;
      ToastService.show(
        title: approve ? 'Investment Approved' : 'Investment Rejected',
        message: approve
            ? '${inv.userName}\'s investment is now active.'
            : '${inv.userName}\'s investment was rejected.',
        type: approve ? ToastType.success : ToastType.warning,
      );
      await _loadAll(silent: true);
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
        title: 'Action Failed',
        message: e.toString(),
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _actionInFlight.remove(inv.cycleId));
    }
  }

  List<Investment> get _filteredPending => _applySearch(_pending);
  List<Investment> get _filteredHistory => _applySearch(_history);

  List<Investment> _applySearch(List<Investment> source) {
    final q = _registrySearchController.text.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source
        .where((e) =>
            e.userName.toLowerCase().contains(q) ||
            e.userEmail.toLowerCase().contains(q) ||
            (e.transactionId ?? '').toLowerCase().contains(q))
        .toList();
  }

  double get _aggregateValue {
    final active = _history.where((e) => e.status == InvestmentStatus.active);
    final sum = active.fold<double>(0, (acc, e) => acc + e.cashbackEligibleAmount);
    return sum;
  }

  int get _nodeCount => _pending.length + _history.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadAll(silent: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGlobalSearch(),
                const SizedBox(height: 32),
                _buildHeader(),
                const SizedBox(height: 32),
                if (_error != null) _buildErrorBanner(),
                _buildSummaryCard(),
                const SizedBox(height: 24),
                _buildProtocolTableCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Sections ---

  Widget _buildGlobalSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: TextField(
        controller: _registrySearchController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search by name, email, or transaction ID...',
          hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        Widget titleContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 32, height: 2, color: const Color(0xFFD97706)),
                const SizedBox(width: 8),
                const Text(
                  'ANALYTICAL COMMAND NODE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFD97706),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 32, height: 2, color: const Color(0xFFD97706)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'INVESTMENT',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1E3A8A),
                height: 0.9,
                letterSpacing: -1,
              ),
            ),
            const Text(
              'REPORTS',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFFD97706),
                height: 0.9,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'HIGH-FIDELITY FISCAL INTELLIGENCE & ASSET OVERSIGHT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF94A3B8).withOpacity(0.8),
                letterSpacing: 1.5,
              ),
            ),
          ],
        );

        Widget actionContent = Column(
          crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _loading ? null : _handleRefreshProtocol,
              icon: _loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, size: 16),
              label: const Text(
                'REFRESH PROTOCOL',
                style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFD97706),
                side: const BorderSide(color: Color(0xFFFDE68A)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                elevation: 2,
                shadowColor: const Color(0xFFD97706).withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loading ? 'SYNCING...' : 'LAST UPDATED: JUST NOW',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF94A3B8).withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleContent, const SizedBox(height: 24), actionContent],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [Expanded(child: titleContent), actionContent],
        );
      },
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error ?? 'Something went wrong.',
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => _loadAll(),
            child: const Text('RETRY', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStat('ACTIVE VALUE', _currency.format(_aggregateValue), const Color(0xFF1E3A8A)),
          _buildStat('NODE COUNT', '$_nodeCount', const Color(0xFF1E3A8A)),
          _buildStat('PENDING REVIEW', '${_pending.length}', const Color(0xFFD97706)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: valueColor)),
      ],
    );
  }

  Widget _buildProtocolTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.receipt_long_outlined, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('PROTOCOL\nHISTORY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), height: 1.1)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1E3A8A),
            unselectedLabelColor: AppColors.kTextMuted,
            indicatorColor: const Color(0xFFD97706),
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1),
            tabs: [
              Tab(text: 'PENDING (${_pending.length})'),
              Tab(text: 'HISTORY (${_history.length})'),
            ],
          ),
          const Divider(height: 1, color: AppColors.kBorder),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: AppLoader()),
            )
          else
            SizedBox(
              height: 480,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingTable(),
                  _buildHistoryTable(),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPendingTable() {
    final rows = _filteredPending;
    if (rows.isEmpty) return _buildEmptyState('No pending investments.');

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 32,
          headingRowHeight: 48,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 72,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 9, letterSpacing: 1),
          columns: const [
            DataColumn(label: Text('ENTITY NODE')),
            DataColumn(label: Text('ASSET')),
            DataColumn(label: Text('VALUE')),
            DataColumn(label: Text('SUBMITTED')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: rows.map((inv) {
            final busy = _actionInFlight.contains(inv.cycleId);
            return DataRow(cells: [
              DataCell(_buildEntityCell(inv)),
              DataCell(Text(inv.productName ?? inv.assetType, style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Color(0xFF64748B), fontSize: 12))),
              DataCell(Text(_currency.format(inv.cashbackEligibleAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13))),
              DataCell(Text(inv.createdAt != null ? _dateFmt.format(inv.createdAt!) : '-', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
              DataCell(
                busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Row(
                        children: [
                          _actionButton(
                            label: 'APPROVE',
                            color: const Color(0xFF16A34A),
                            onTap: () => _handleDecision(inv, approve: true),
                          ),
                          const SizedBox(width: 8),
                          _actionButton(
                            label: 'REJECT',
                            color: const Color(0xFFDC2626),
                            onTap: () => _handleDecision(inv, approve: false),
                          ),
                        ],
                      ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHistoryTable() {
    final rows = _filteredHistory;
    if (rows.isEmpty) return _buildEmptyState('No processed investments yet.');

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 32,
          headingRowHeight: 48,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 72,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 9, letterSpacing: 1),
          columns: const [
            DataColumn(label: Text('ENTITY NODE')),
            DataColumn(label: Text('VALUE')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('PROCESSED')),
          ],
          rows: rows.map((inv) {
            return DataRow(cells: [
              DataCell(_buildEntityCell(inv)),
              DataCell(Text(_currency.format(inv.cashbackEligibleAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13))),
              DataCell(_buildStatusBadge(inv.status)),
              DataCell(Text(inv.processedDate != null ? _dateFmt.format(inv.processedDate!) : '-', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEntityCell(Investment inv) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(inv.initial, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(inv.userName, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 12)),
            const SizedBox(height: 2),
            Text(inv.userEmail, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(InvestmentStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case InvestmentStatus.active:
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF16A34A);
        break;
      case InvestmentStatus.rejected:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        investmentStatusLabel(status),
        style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5),
      ),
    );
  }

  Widget _actionButton({required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}