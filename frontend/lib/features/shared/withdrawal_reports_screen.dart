import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/withdrawal_report_model.dart';
import '../../services/withdrawal_report_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class WithdrawalReportsScreen extends StatefulWidget {
  const WithdrawalReportsScreen({super.key});

  @override
  State<WithdrawalReportsScreen> createState() =>
      _WithdrawalReportsScreenState();
}

class _WithdrawalReportsScreenState extends State<WithdrawalReportsScreen> {
  final WithdrawalReportService _service = WithdrawalReportService();
  final TextEditingController _registrySearchController =
      TextEditingController();

  bool _loading = true;
  String? _error;
  WithdrawalListResult _result = WithdrawalListResult.empty();

  // Client-side only — the backend has no status query param.
  WithdrawalStatus? _statusFilter;
  String _searchQuery = '';
  final Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _registrySearchController.addListener(() {
      setState(() =>
          _searchQuery = _registrySearchController.text.trim().toLowerCase());
    });
    _load();
  }

  @override
  void dispose() {
    _registrySearchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.fetchWithdrawals();
      if (!mounted) return;
      setState(() {
        _result = result;
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

  List<WithdrawalRecord> get _filteredWithdrawals {
    Iterable<WithdrawalRecord> list = _result.withdrawals;
    if (_statusFilter != null) {
      list = list.where((w) => w.status == _statusFilter);
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((w) {
        final haystack = [
          w.userName,
          w.userEmail,
          w.transactionId,
          w.paymentMethod,
          w.bankDetails,
        ].where((e) => e != null).map((e) => e!.toLowerCase()).join(' ');
        return haystack.contains(_searchQuery);
      });
    }
    return list.toList();
  }

  // --- Handlers ---

  Future<void> _handleRefreshProtocol() async {
    await _load();
    if (!mounted) return;
    if (_error == null) {
      ToastService.show(
        title: 'Refreshed',
        message: 'Withdrawal data synced from the server.',
        type: ToastType.success,
      );
    } else {
      ToastService.show(
          title: 'Refresh failed', message: _error!, type: ToastType.error);
    }
  }

  Future<void> _handleApprove(WithdrawalRecord withdrawal) async {
    final transactionController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('APPROVE WITHDRAWAL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Approve ${_formatCurrency(withdrawal.amount)} for ${withdrawal.userName ?? 'this user'}?'),
            const SizedBox(height: 16),
            TextField(
              controller: transactionController,
              decoration: const InputDecoration(
                labelText: 'Transaction / UTR reference (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL')),
          ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('APPROVE')),
        ],
      ),
    );
    final transactionId = transactionController.text;
    transactionController.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _processingIds.add(withdrawal.id));
    try {
      await _service.approve(withdrawal.id, transactionId: transactionId);
      if (!mounted) return;
      ToastService.show(
          title: 'Approved',
          message: 'Withdrawal #${withdrawal.id} approved.',
          type: ToastType.success);
      await _load();
    } catch (e) {
      if (mounted)
        ToastService.show(
            title: 'Approval failed',
            message: e.toString(),
            type: ToastType.error);
    } finally {
      if (mounted) setState(() => _processingIds.remove(withdrawal.id));
    }
  }

  Future<void> _handleReject(WithdrawalRecord withdrawal) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'REJECT WITHDRAWAL',
      message:
          'Reject ${_formatCurrency(withdrawal.amount)} from ${withdrawal.userName ?? 'this user'}? The locked funds will be restored to the wallet.',
      confirmLabel: 'REJECT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFFDC2626),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _processingIds.add(withdrawal.id));
    try {
      await _service.reject(withdrawal.id);
      if (!mounted) return;
      ToastService.show(
          title: 'Rejected',
          message: 'Withdrawal #${withdrawal.id} rejected and refunded.',
          type: ToastType.success);
      await _load();
    } catch (e) {
      if (mounted)
        ToastService.show(
            title: 'Rejection failed',
            message: e.toString(),
            type: ToastType.error);
    } finally {
      if (mounted) setState(() => _processingIds.remove(withdrawal.id));
    }
  }

  Future<void> _handleExportLedger() async {
    final rows = _filteredWithdrawals;
    if (rows.isEmpty) {
      ToastService.show(
        title: 'Nothing to export',
        message: 'There are no withdrawals in the current view.',
        type: ToastType.info,
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'EXPORT LEDGER',
      message:
          'Copy a CSV of the ${rows.length} withdrawal(s) currently in view to your clipboard?',
      confirmLabel: 'EXPORT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );
    if (confirmed != true) return;

    final csv = _buildCsv(rows);
    await Clipboard.setData(ClipboardData(text: csv));

    if (!mounted) return;
    ToastService.show(
      title: 'Copied to clipboard',
      message: '${rows.length} row(s) exported as CSV.',
      type: ToastType.success,
    );
  }

  String _buildCsv(List<WithdrawalRecord> rows) {
    String esc(String? v) => '"${(v ?? '').replaceAll('"', '""')}"';
    final buffer = StringBuffer()
      ..writeln(
          'ID,User,Email,Amount,Payment Method,Transaction ID,Status,Created At,Processed At');
    for (final w in rows) {
      buffer.writeln([
        w.id,
        esc(w.userName),
        esc(w.userEmail),
        w.amount.toStringAsFixed(2),
        esc(w.paymentMethod),
        esc(w.transactionId),
        w.status.value,
        w.createdAt?.toIso8601String() ?? '',
        w.processedAt?.toIso8601String() ?? '',
      ].join(','));
    }
    return buffer.toString();
  }

  // --- Derived stats ---

  int get _pendingCount => _result.withdrawals
      .where((w) => w.status == WithdrawalStatus.pending)
      .length;
  int get _approvedCount => _result.withdrawals
      .where((w) => w.status == WithdrawalStatus.approved)
      .length;
  int get _rejectedCount => _result.withdrawals
      .where((w) => w.status == WithdrawalStatus.rejected)
      .length;

  double _sumForStatus(WithdrawalStatus status) => _result.withdrawals
      .where((w) => w.status == status)
      .fold<double>(0, (s, w) => s + w.amount);

  double get _approvalRate {
    if (_result.withdrawals.isEmpty) return 0;
    return (_approvedCount / _result.withdrawals.length) * 100;
  }

  Map<String, double> get _valueByPaymentMethod {
    final map = <String, double>{};
    for (final w in _result.withdrawals) {
      final key = w.paymentMethod.isEmpty ? 'Unknown' : w.paymentMethod;
      map[key] = (map[key] ?? 0) + w.amount;
    }
    return map;
  }

  String _formatCurrency(double value) {
    final rounded = value.round();
    final s = rounded.toString();
    final chars = s.split('');
    final out = <String>[];
    for (int i = 0; i < chars.length; i++) {
      final fromRight = chars.length - i;
      out.add(chars[i]);
      if (fromRight > 1 && fromRight % 3 == 1) out.add(',');
    }
    return '₹ ${out.join()}';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) _buildErrorBanner(),
                if (_error != null) const SizedBox(height: 16),

                // --- 1. Global Search Bar ---
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: TextField(
                    controller: _registrySearchController,
                    decoration: const InputDecoration(
                      hintText:
                          'Search by user, email, transaction ID, method...',
                      hintStyle:
                          TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.kTextMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // --- 2. Header Section ---
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isMobile = constraints.maxWidth < 600;

                    Widget titleContent = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                                width: 32,
                                height: 2,
                                color: const Color(0xFFD97706)),
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
                            Container(
                                width: 32,
                                height: 2,
                                color: const Color(0xFFD97706)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'WITHDRAWAL',
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
                      crossAxisAlignment: isMobile
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _handleRefreshProtocol,
                          icon: _loading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Color(0xFFD97706)),
                                )
                              : const Icon(Icons.sync, size: 16),
                          label: const Text(
                            'REFRESH PROTOCOL',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                fontSize: 11,
                                letterSpacing: 1),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFD97706),
                            side: const BorderSide(color: Color(0xFFFDE68A)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32)),
                            elevation: 2,
                            shadowColor:
                                const Color(0xFFD97706).withOpacity(0.1),
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
                        children: [
                          titleContent,
                          const SizedBox(height: 24),
                          actionContent
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [Expanded(child: titleContent), actionContent],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // --- 3. Overview Card ---
                _buildOverviewCard(),
                const SizedBox(height: 24),

                // --- 4. Approval Rate & Registry Size Row ---
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isMobile = constraints.maxWidth < 800;
                    Widget approvalCard = _buildApprovalRateCard();
                    Widget dataDumpCard = _buildGlobalDataDumpCard();
                    if (isMobile) {
                      return Column(children: [
                        approvalCard,
                        const SizedBox(height: 24),
                        dataDumpCard
                      ]);
                    }
                    return Row(
                      children: [
                        Expanded(child: approvalCard),
                        const SizedBox(width: 24),
                        Expanded(child: dataDumpCard),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // --- 5. 4-Grid Navy Stats Cards (real status counts + sums) ---
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth < 600
                        ? 1
                        : (constraints.maxWidth < 1000 ? 2 : 4);
                    final totalValue = _result.withdrawals
                        .fold<double>(0, (s, w) => s + w.amount);
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: constraints.maxWidth < 600 ? 2.5 : 1.8,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildNavyStatCard(
                            'TOTAL WITHDRAWALS',
                            _formatCurrency(totalValue),
                            Icons.account_balance_wallet_outlined),
                        _buildNavyStatCard(
                            'SUCCESSFUL TRANSFERS',
                            _formatCurrency(
                                _sumForStatus(WithdrawalStatus.approved)),
                            Icons.verified_outlined),
                        _buildNavyStatCard(
                            'FAILED PROCESSING',
                            _formatCurrency(
                                _sumForStatus(WithdrawalStatus.rejected)),
                            Icons.cancel_outlined),
                        _buildNavyStatCard(
                            'PENDING REQUESTS',
                            _formatCurrency(
                                _sumForStatus(WithdrawalStatus.pending)),
                            Icons.hourglass_empty),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // --- 6. Value by Payment Method ---
                _buildPaymentMethodBreakdown(),
                const SizedBox(height: 24),

                // --- 7. Registry Table ---
                _buildRegistryCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Sub-Components ---

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_error ?? '',
                style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
          TextButton(onPressed: _load, child: const Text('RETRY')),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final total = _result.withdrawals.fold<double>(0, (s, w) => s + w.amount);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WITHDRAWAL\nOVERVIEW',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E3A8A),
                          height: 1.1)),
                  const SizedBox(height: 4),
                  Text('LIVE FROM WITHDRAWALS TABLE',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF94A3B8).withOpacity(0.8),
                          letterSpacing: 1,
                          height: 1.3)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _loading
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _loading
                          ? AppColors.kBorder
                          : const Color(0xFFFDE68A)),
                ),
                child: Text(
                  _loading ? 'SYNCING' : 'LIVE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _loading
                        ? AppColors.kTextMuted
                        : const Color(0xFFD97706),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVelocityStat('AGGREGATE\nVALUE', _formatCurrency(total),
                  const Color(0xFF1E3A8A)),
              _buildVelocityStat('NODE COUNT', '${_result.withdrawals.length}',
                  const Color(0xFF1E3A8A)),
              _buildVelocityStat(
                  'CURRENT\nFILTER',
                  _statusFilter?.value.toUpperCase() ?? 'ALL',
                  const Color(0xFFD97706)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFF94A3B8),
                letterSpacing: 1,
                height: 1.4)),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: valueColor)),
      ],
    );
  }

  Widget _buildApprovalRateCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFC29B38),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFD97706).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.show_chart, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 24),
          const Text('APPROVAL RATE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('${_approvalRate.toStringAsFixed(1)}%',
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  height: 1)),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.arrow_right, color: Colors.white, size: 14),
              Text('$_approvedCount OF ${_result.withdrawals.length} APPROVED',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalDataDumpCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
                color: Color(0xFFFFFBEB), shape: BoxShape.circle),
            child:
                const Icon(Icons.language, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(height: 24),
          const Text('REGISTRY SIZE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('${_result.withdrawals.length} NODE REGISTRY',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF1E3A8A))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleExportLedger,
              icon: const Icon(Icons.download, size: 14),
              label: const Text('EXPORT LEDGER (CSV)',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                      letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavyStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFF112255),
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('SYSTEM READY',
                  style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 0.5))),
                ],
              ),
              const SizedBox(height: 16),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodBreakdown() {
    final byMethod = _valueByPaymentMethod;
    final total = _result.withdrawals.fold<double>(0, (s, w) => s + w.amount);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('VALUE BY PAYMENT METHOD',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 4),
                  Text('SUM OF AMOUNT GROUPED BY PAYMENT_METHOD',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF94A3B8).withOpacity(0.8),
                          letterSpacing: 1)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.account_balance,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (byMethod.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'NO DATA YET',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF94A3B8).withOpacity(0.6),
                    letterSpacing: 1),
              ),
            )
          else
            Column(
              children: byMethod.entries.map((entry) {
                final pct = total > 0 ? (entry.value / total * 100) : 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(entry.key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                      Text('${pct.toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.kTextMuted)),
                      const SizedBox(width: 16),
                      Text(_formatCurrency(entry.value),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Color(0xFF1E3A8A))),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRegistryCard() {
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
            padding: const EdgeInsets.all(32.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 700;

                Widget titleArea = Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.account_balance,
                          color: Color(0xFF3B82F6), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PROTOCOL HISTORY',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF1E3A8A),
                                  height: 1.1)),
                          const SizedBox(height: 4),
                          Text('withdrawals · live',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color:
                                      const Color(0xFF94A3B8).withOpacity(0.8),
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ],
                );

                Widget searchArea = Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _registrySearchController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'SEARCH IDENTITY...',
                            hintStyle: const TextStyle(
                                color: AppColors.kTextMuted,
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w900),
                            prefixIcon: const Icon(Icons.search,
                                size: 16, color: AppColors.kTextMuted),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: AppColors.kBorder)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusFilterButton(),
                  ],
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleArea,
                      const SizedBox(height: 24),
                      searchArea
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(flex: 3, child: titleArea),
                    const SizedBox(width: 32),
                    Expanded(flex: 4, child: searchArea),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.kBorder),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: AppLoader()),
            )
          else
            _buildTransactionsTable(),
        ],
      ),
    );
  }

  Widget _buildStatusFilterButton() {
    return PopupMenuButton<WithdrawalStatus?>(
      onSelected: (value) => setState(() => _statusFilter = value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('ALL STATUSES')),
        const PopupMenuItem(
            value: WithdrawalStatus.pending, child: Text('PENDING')),
        const PopupMenuItem(
            value: WithdrawalStatus.approved, child: Text('APPROVED')),
        const PopupMenuItem(
            value: WithdrawalStatus.rejected, child: Text('REJECTED')),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.kBorder),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list,
                size: 16, color: AppColors.kTextMuted),
            const SizedBox(width: 8),
            Text(
              _statusFilter == null
                  ? 'ALL NODES'
                  : _statusFilter!.value.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down,
                size: 16, color: AppColors.kTextMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTable() {
    final rows = _filteredWithdrawals;

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
        alignment: Alignment.center,
        child: const Text(
          'NO REGISTRY ENTRIES FOUND',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFFCBD5E1),
              letterSpacing: 2),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
        child: DataTable(
          columnSpacing: 40,
          headingRowHeight: 56,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 72,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dividerThickness: 0,
          headingTextStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF94A3B8),
              fontSize: 9,
              letterSpacing: 1.5),
          columns: const [
            DataColumn(label: Text('ENTITY NODE')),
            DataColumn(label: Text('PROTOCOL REF')),
            DataColumn(label: Text('METHOD')),
            DataColumn(label: Text('VALUE (₹)')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('TIMESTAMP')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: rows.map((w) => _buildDataRow(w)).toList(),
        ),
      ),
    );
  }

  DataRow _buildDataRow(WithdrawalRecord w) {
    return DataRow(
      cells: [
        DataCell(Text(w.userName ?? '—',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        DataCell(Text(w.transactionId ?? '#${w.id}',
            style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted))),
        DataCell(Text(w.paymentMethod,
            style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted))),
        DataCell(Text(_formatCurrency(w.amount),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
        DataCell(_buildStatusBadge(w.status)),
        DataCell(Text(_formatDate(w.createdAt),
            style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted))),
        DataCell(_buildActionCell(w)),
      ],
    );
  }

  Widget _buildActionCell(WithdrawalRecord withdrawal) {
    if (withdrawal.status != WithdrawalStatus.pending) {
      return const Text('—', style: TextStyle(color: AppColors.kTextMuted));
    }

    final busy = _processingIds.contains(withdrawal.id);
    if (busy) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Approve withdrawal',
          onPressed: () => _handleApprove(withdrawal),
          icon:
              const Icon(Icons.check_circle_outline, color: Color(0xFF047857)),
        ),
        IconButton(
          tooltip: 'Reject withdrawal',
          onPressed: () => _handleReject(withdrawal),
          icon: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(WithdrawalStatus status) {
    late Color bg;
    late Color fg;
    switch (status) {
      case WithdrawalStatus.approved:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        break;
      case WithdrawalStatus.rejected:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
      case WithdrawalStatus.pending:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.value.toUpperCase(),
        style: TextStyle(
            color: fg,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5),
      ),
    );
  }
}
