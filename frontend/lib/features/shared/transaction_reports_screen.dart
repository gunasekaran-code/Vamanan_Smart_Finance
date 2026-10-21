import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/report_components.dart';
import '../../models/transaction_report_models.dart';
import '../../services/transaction_report_service.dart';

class TransactionReportsScreen extends StatefulWidget {
  const TransactionReportsScreen({super.key});

  @override
  State<TransactionReportsScreen> createState() => _TransactionReportsScreenState();
}

class _TransactionReportsScreenState extends State<TransactionReportsScreen> {
  final TransactionReportService _service = TransactionReportService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  TransactionReport _report = TransactionReport.empty();
  DateTime? _lastSync;

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
      message: _error ?? 'Transaction ledger synced from the server.',
      type: _error == null ? ToastType.success : ToastType.error,
    );
  }

  List<TransactionReportRow> get _filteredRows => _report.history.where((t) {
        if (_statusFilter != null && t.status != _statusFilter) return false;
        if (_searchQuery.isEmpty) return true;
        return [t.userName, t.userEmail, '#ID-${t.id}', t.category, t.description].join(' ').toLowerCase().contains(_searchQuery);
      }).toList();

  Future<void> _handleExportLedger() async {
    final rows = _filteredRows;
    if (rows.isEmpty) {
      ToastService.show(title: 'Nothing to export', message: 'There are no transactions in the current view.', type: ToastType.info);
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'EXPORT LEDGER',
      message: 'Copy a CSV of the ${rows.length} transaction(s) currently in view to your clipboard?',
      confirmLabel: 'EXPORT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: ReportColors.navy,
    );
    if (confirmed != true) return;

    String esc(Object? v) => '"${(v ?? '').toString().replaceAll('"', '""')}"';
    final b = StringBuffer('ID,Name,Email,Type,Category,Amount,Gross,TDS,Charges,Status,Description,Created At\n');
    for (final t in rows) {
      b.writeln([
        t.id,
        esc(t.userName),
        esc(t.userEmail),
        t.type,
        t.category,
        t.amount.toStringAsFixed(2),
        t.grossAmount?.toStringAsFixed(2) ?? '',
        t.tdsAmount?.toStringAsFixed(2) ?? '',
        t.chargesAmount?.toStringAsFixed(2) ?? '',
        t.status,
        esc(t.description),
        t.createdAt?.toIso8601String() ?? '',
      ].join(','));
    }
    await Clipboard.setData(ClipboardData(text: b.toString()));

    if (!mounted) return;
    ToastService.show(title: 'Copied to clipboard', message: '${rows.length} row(s) exported as CSV.', type: ToastType.success);
  }

  /// e.g. "CASHBACK · CREDIT" / "PURCHASE REQUEST · DEBIT"
  String? _categoryLine(TransactionReportRow t) {
    final parts = [t.category.replaceAll('_', ' '), t.type].where((s) => s.isNotEmpty).map((s) => s.toUpperCase());
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReportColors.tile,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 600;
              final pad = isMobile ? 16.0 : 24.0;
              final gap = isMobile ? 16.0 : 24.0;
              final contentWidth = width - pad * 2;
              final statuses = (_report.history.map((t) => t.status).toSet().toList()..sort());

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
                          navyTitle: 'TRANSACTION',
                          goldTitle: 'REPORTS',
                          isMobile: isMobile,
                          loading: _loading,
                          lastSync: _lastSync,
                          onRefresh: _handleRefresh,
                        ),
                        SizedBox(height: gap + 8),
                        ReportOverviewRow(
                          width: contentWidth,
                          gap: gap,
                          velocity: ReportVelocityCard(
                            values: _report.chart.map((p) => p.totalAmount).toList(),
                            loading: _loading,
                            isMobile: isMobile,
                            aggregateValue: formatInr(_report.total),
                            nodeCount: '${_report.count}',
                            healthy: _error == null,
                            lineColor: ReportColors.chartBlue,
                          ),
                          efficiency: ReportEfficiencyCard(efficiency: _report.efficiency),
                          registry: ReportRegistryCard(registryCount: _report.registryCount, onExport: _loading ? null : _handleExportLedger),
                        ),
                        SizedBox(height: gap + 8),
                        ReportHistoryCard(
                          width: contentWidth,
                          isMobile: isMobile,
                          loading: _loading,
                          icon: Icons.monitor_heart_outlined,
                          iconColor: ReportColors.chartBlue,
                          iconBackground: const Color(0xFFEFF6FF),
                          searchController: _searchController,
                          filter: ReportStatusFilter(
                            selected: _statusFilter,
                            options: {for (final s in statuses) s: s.toUpperCase()},
                            onChanged: (v) => setState(() => _statusFilter = v),
                          ),
                          rows: _filteredRows
                              .map((t) => ReportHistoryRow(
                                    name: t.userName,
                                    email: t.userEmail,
                                    ref: '#ID-${t.id}',
                                    refDetail: _categoryLine(t),
                                    value: formatInr(t.amount),
                                    valueDetail: deductionLine(gross: t.grossAmount, tds: t.tdsAmount, charges: t.chargesAmount),
                                    statusLabel: t.status.toUpperCase(),
                                    statusKey: t.status,
                                    timestamp: t.createdAt,
                                  ))
                              .toList(),
                        ),
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
}
