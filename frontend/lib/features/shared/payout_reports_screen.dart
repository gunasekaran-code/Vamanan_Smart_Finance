import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../../models/payout_report_model.dart';
import '../../../services/payout_reports_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class PayoutReportsScreen extends StatefulWidget {
  const PayoutReportsScreen({super.key});

  @override
  State<PayoutReportsScreen> createState() => _PayoutReportsScreenState();
}

class _PayoutReportsScreenState extends State<PayoutReportsScreen> {
  final TextEditingController _registrySearchController = TextEditingController();
  final _service = PayoutReportsService();

  PayoutReportsData? _data;
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
    _registrySearchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _registrySearchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _service.fetchReports();
      setState(() {
        _data = data;
        _lastUpdated = DateTime.now();
      });
    } on PayoutReportsException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<PayoutHistoryRecord> get _filteredHistory {
    final history = _data?.history ?? const <PayoutHistoryRecord>[];
    final query = _registrySearchController.text;
    if (query.trim().isEmpty) return history;
    return history.where((r) => r.matches(query)).toList();
  }

  // --- Handlers ---
  void _handleRefreshProtocol() {
    _load().then((_) {
      if (_errorMessage == null) {
        ToastService.show(
          title: 'Protocol Refreshed',
          message: 'Fiscal intelligence data synced with the global node.',
          type: ToastType.success,
        );
      }
    });
  }

  Future<void> _handleExportLedger() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'EXPORT LEDGER',
      message: 'Generate a full data dump of the global node registry?',
      confirmLabel: 'EXPORT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );

    if (confirmed == true) {
      // NOTE: actual export/download hits a separate endpoint
      // (admin/export_payouts.php) which wasn't part of this wiring —
      // this just acknowledges the action for now.
      ToastService.show(
        title: 'Export Initiated',
        message: 'The ledger is being prepared for download.',
        type: ToastType.success,
      );
    }
  }

  String _formatCurrency(double value) {
    final rounded = value.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromEnd = str.length - i;
      buffer.write(str[i]);
      if (posFromEnd > 1 && posFromEnd <= 3) continue;
      if (posFromEnd > 3 && (posFromEnd - 3) % 2 == 0) buffer.write(',');
    }
    return '₹ ${buffer.toString()}';
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 10) return 'JUST NOW';
    if (diff.inMinutes < 1) return '${diff.inSeconds}S AGO';
    if (diff.inHours < 1) return '${diff.inMinutes}M AGO';
    if (diff.inDays < 1) return '${diff.inHours}H AGO';
    return '${diff.inDays}D AGO';
  }

  @override
  Widget build(BuildContext context) {
    final summary = _data?.summary ?? PayoutSummary.empty();
    final chart = _data?.chart ?? const <PayoutChartPoint>[];

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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search users, orders, assets...',
                      hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  _buildErrorBanner(_errorMessage!),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),
                LayoutBuilder(
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
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706), letterSpacing: 2),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 32, height: 2, color: const Color(0xFFD97706)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'PAYOUT\nREPORTS',
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), height: 0.9, letterSpacing: -1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'HIGH-FIDELITY FISCAL INTELLIGENCE & ASSET OVERSIGHT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1.5),
                        ),
                      ],
                    );

                    Widget actionContent = Column(
                      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleRefreshProtocol,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)),
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
                          'LAST UPDATED: ${_timeAgo(_lastUpdated)}',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.7), letterSpacing: 1),
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
                ),
                const SizedBox(height: 32),

                _buildTransmissionVelocityCard(chart, summary),
                const SizedBox(height: 24),

                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isMobile = constraints.maxWidth < 800;
                    Widget marketCard = _buildMarketTrajectoryCard(summary);
                    Widget dataDumpCard = _buildGlobalDataDumpCard(summary);

                    if (isMobile) {
                      return Column(children: [marketCard, const SizedBox(height: 24), dataDumpCard]);
                    }
                    return Row(children: [Expanded(child: marketCard), const SizedBox(width: 24), Expanded(child: dataDumpCard)]);
                  },
                ),
                const SizedBox(height: 24),

                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth < 600 ? 1 : (constraints.maxWidth < 1000 ? 2 : 4);
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: constraints.maxWidth < 600 ? 2.5 : 1.8,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildNavyStatCard('TOTAL PAYOUTS', _formatCurrency(summary.totalAmount), Icons.account_balance_wallet_outlined),
                        _buildNavyStatCard('GUARANTEED TRANSACTIONS', _formatCurrency(summary.successAmount), Icons.verified_outlined),
                        _buildNavyStatCard('FAILED PROCESSING', _formatCurrency(summary.failedAmount), Icons.cancel_outlined),
                        _buildNavyStatCard('PENDING REQUESTS', _formatCurrency(summary.pendingAmount), Icons.hourglass_empty),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                _buildPayoutVelocityMatrix(chart),
                const SizedBox(height: 24),

                _buildProtocolHistoryCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFFB91C1C)),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  // --- Sub-Components ---

  Widget _buildTransmissionVelocityCard(List<PayoutChartPoint> chart, PayoutSummary summary) {
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
                  const Text('TRANSMISSION VELOCITY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 4),
                  Text('TEMPORAL YIELD ANALYSIS (${chart.length} CYCLES)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
                child: const Row(
                  children: [
                    Icon(Icons.star, size: 8, color: Color(0xFFD97706)),
                    SizedBox(width: 6),
                    Text('LIVE SYNC ACTIVE', style: TextStyle(color: Color(0xFFD97706), fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 200,
            child: _isLoading
                ? const Center(child: AppLoader())
                : chart.isEmpty
                    ? Center(
                        child: Icon(Icons.monitor_heart_outlined, size: 48, color: const Color(0xFFE2E8F0).withOpacity(0.5)),
                      )
                    : CustomPaint(
                        size: const Size(double.infinity, 200),
                        painter: _SparklinePainter(chart.map((p) => p.totalAmount).toList()),
                      ),
          ),
          const Divider(height: 1, color: AppColors.kBorder),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVelocityStat('AGGREGATE YIELD (₹)', _formatCurrency(summary.totalAmount), const Color(0xFF1E3A8A)),
              _buildVelocityStat('NODE COUNT', '${summary.totalCount}', const Color(0xFF1E3A8A)),
              _buildVelocityStat(
                'EMISSION STATUS',
                summary.failedCount > summary.successCount ? 'DEGRADED' : 'OPTIMAL',
                const Color(0xFFD97706),
              ),
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
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: valueColor)),
      ],
    );
  }

  Widget _buildMarketTrajectoryCard(PayoutSummary summary) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFC29B38),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: const Color(0xFFD97706).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.show_chart, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 24),
          const Text('MARKET TRAJECTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('${summary.successRate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white, height: 1)),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.arrow_right, color: Colors.white, size: 14),
              Text('INSTITUTIONAL GRADE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.8), letterSpacing: 1.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalDataDumpCard(PayoutSummary summary) {
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
            decoration: BoxDecoration(color: const Color(0xFFFFFBEB), shape: BoxShape.circle),
            child: const Icon(Icons.cloud_download_outlined, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(height: 24),
          const Text('GLOBAL DATA DUMP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('${summary.totalCount} NODE REGISTRY', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleExportLedger,
              icon: const Icon(Icons.download, size: 14),
              label: const Text('EXPORT LEDGER', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF112255), borderRadius: BorderRadius.circular(6)),
              child: const Text('SYSTEM READY', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 7, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
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
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.7), letterSpacing: 0.5))),
                ],
              ),
              const SizedBox(height: 16),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutVelocityMatrix(List<PayoutChartPoint> chart) {
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
                  const Text('PAYOUT VELOCITY MATRIX', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 4),
                  Text('INSTITUTIONAL DISBURSEMENT TIMELINE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 180,
            child: chart.isEmpty
                ? const SizedBox.shrink()
                : CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: _SparklinePainter(chart.map((p) => p.totalAmount).toList(), barMode: true),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolHistoryCard() {
    final filtered = _filteredHistory;

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
                bool isMobile = constraints.maxWidth < 600;

                Widget titleArea = Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.attach_money, color: Color(0xFFD97706), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PROTOCOL\nHISTORY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), height: 1.1)),
                          const SizedBox(height: 4),
                          Text('IMMUTABLE TRANSACTION REGISTRY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ],
                );

                Widget searchArea = Column(
                  children: [
                    SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _registrySearchController,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'SEARCH REGISTRY...',
                          hintStyle: const TextStyle(color: AppColors.kTextMuted, fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900),
                          prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.kTextMuted),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.kBorder)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.kBorder), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.filter_list, size: 16, color: AppColors.kTextMuted),
                          Text('ALL NODES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                          Icon(Icons.arrow_drop_down, size: 16, color: AppColors.kTextMuted),
                        ],
                      ),
                    ),
                  ],
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [titleArea, const SizedBox(height: 24), searchArea],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Expanded(flex: 3, child: titleArea), const SizedBox(width: 32), Expanded(flex: 2, child: searchArea)],
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.kBorder),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: AppLoader()),
            )
          else if (filtered.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
                child: DataTable(
                  columnSpacing: 48,
                  headingRowHeight: 56,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  dividerThickness: 0,
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 9, letterSpacing: 1.5),
                  columns: const [
                    DataColumn(label: Text('ENTITY NODE')),
                    DataColumn(label: Text('PROTOCOL REF')),
                    DataColumn(label: Text('VALIDATE')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('QUANTUM (₹)')),
                  ],
                  rows: filtered.map((r) => _buildHistoryRow(r)).toList(),
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              alignment: Alignment.center,
              child: const Text(
                'NO REGISTRY ENTRIES FOUND',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1), letterSpacing: 2),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  DataRow _buildHistoryRow(PayoutHistoryRecord r) {
    Color statusColor;
    switch (r.status) {
      case 'success':
      case 'completed':
        statusColor = const Color(0xFF16A34A);
        break;
      case 'failed':
        statusColor = const Color(0xFFB91C1C);
        break;
      case 'pending':
        statusColor = const Color(0xFFD97706);
        break;
      default:
        statusColor = const Color(0xFF94A3B8);
    }

    return DataRow(cells: [
      DataCell(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.userName ?? '—', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            if (r.userEmail != null)
              Text(r.userEmail!, style: const TextStyle(fontSize: 10, color: AppColors.kTextMuted)),
          ],
        ),
      ),
      DataCell(Text('#${r.id}')),
      DataCell(Text(r.bankName != null ? '${r.bankName} • ${r.ifscCode ?? ''}' : '—', style: const TextStyle(fontSize: 11))),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(
            r.status.toUpperCase(),
            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
          ),
        ),
      ),
      DataCell(Text(_formatCurrency(r.amount), style: const TextStyle(fontWeight: FontWeight.w900))),
    ]);
  }
}

/// Minimal line/bar sparkline so the two chart placeholders show real data
/// without pulling in a charting package.
class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final bool barMode;

  _SparklinePainter(this.values, {this.barMode = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1 : maxVal;

    if (barMode) {
      final barWidth = size.width / (values.length * 1.6);
      final gap = barWidth * 0.6;
      double x = gap;
      final paint = Paint()..color = const Color(0xFF1E3A8A);
      for (final v in values) {
        final barHeight = (v / safeMax) * size.height;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
            const Radius.circular(4),
          ),
          paint,
        );
        x += barWidth + gap;
      }
    } else {
      final path = Path();
      final stepX = size.width / (values.length - 1).clamp(1, values.length);
      for (int i = 0; i < values.length; i++) {
        final x = i * stepX;
        final y = size.height - (values[i] / safeMax) * size.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final linePaint = Paint()
        ..color = const Color(0xFFD97706)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.barMode != barMode;
}