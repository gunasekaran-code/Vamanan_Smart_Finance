import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/models/tally_integration_model.dart';
import 'package:frontend/services/tally_integration_service.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/stat_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tally_state_views.dart';

/// The six ledgers from `?resource=ledger`, with date filtering, XML/Excel/CSV
/// export, an XML preview and a direct push to the Tally gateway.
class LedgerViewWidget extends StatefulWidget {
  const LedgerViewWidget({super.key});

  @override
  State<LedgerViewWidget> createState() => _LedgerViewWidgetState();
}

class _LedgerViewWidgetState extends State<LedgerViewWidget> {
  final TallyIntegrationService _service = TallyIntegrationService();

  TallyLedger _activeLedger = TallyLedger.inventory;
  TallyLedgerResult? _result;
  bool _isLoading = true;
  bool _isBusy = false; // a sync / preview is in flight
  String? _error;

  /// The backend defaults to the last twelve months; the pickers start there
  /// so what's shown matches what an unfiltered request would return.
  late DateTime _fromDate =
      DateTime.now().subtract(const Duration(days: 365));
  late DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _wireDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.fetchLedger(
        _activeLedger,
        startDate: _wireDate(_fromDate),
        endDate: _wireDate(_toDate),
      );
      if (!mounted) return;
      setState(() => _result = result);
    } on TallyIntegrationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectLedger(TallyLedger ledger) {
    if (ledger == _activeLedger) return;
    setState(() {
      _activeLedger = ledger;
      _result = null;
    });
    _load();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });
  }

  Future<void> _handleExport(TallyExportFormat format) async {
    final uri = _service.buildLedgerExportUri(
      _activeLedger,
      format,
      startDate: _wireDate(_fromDate),
      endDate: _wireDate(_toDate),
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ToastService.show(
        title: 'Could not start download',
        message: 'Try opening the link manually: $uri',
        type: ToastType.error,
      );
    }
  }

  Future<void> _handlePreview() async {
    setState(() => _isBusy = true);
    try {
      final xml = await _service.previewLedgerXml(
        _activeLedger,
        startDate: _wireDate(_fromDate),
        endDate: _wireDate(_toDate),
      );
      if (!mounted) return;
      await TallyXmlPreviewDialog.show(
        context,
        '${_activeLedger.label} · TALLY XML',
        xml,
      );
    } on TallyIntegrationException catch (e) {
      _toastError(e.message);
    } catch (e) {
      _toastError('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleSyncToTally() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'SYNC TO TALLY',
      message:
          'Push these vouchers directly into Tally? Make sure TallyPrime is open with the gateway enabled (port 9000).',
      confirmLabel: 'OK',
      cancelLabel: 'CANCEL',
      confirmButtonColor: kTallyGold,
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final result = await _service.syncLedger(_activeLedger);
      if (!mounted) return;
      ToastService.show(
        title: result.isOffline ? 'Tally Not Reachable' : 'Sync Complete',
        message: result.message,
        // 'offline' isn't a failure — the XML is still there to import by hand.
        type: result.isOffline ? ToastType.warning : ToastType.success,
        duration: const Duration(seconds: 7),
      );
      await _load();
    } on TallyIntegrationException catch (e) {
      _toastError(e.message);
    } catch (e) {
      _toastError('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _toastError(String message) {
    if (!mounted) return;
    ToastService.show(
      title: 'Action Failed',
      message: message,
      type: ToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _result?.summary ?? TallyLedgerSummary.empty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- 1. Ledger Filters & Export Controls ---
        TallyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ledger Sub-Tabs
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSubTab(TallyLedger.sales, Icons.trending_up),
                  _buildSubTab(TallyLedger.customer, Icons.people_outline),
                  _buildSubTab(TallyLedger.cashback, Icons.monetization_on_outlined),
                  _buildSubTab(TallyLedger.referral, Icons.link),
                  _buildSubTab(TallyLedger.withdrawal, Icons.upload_outlined),
                  _buildSubTab(TallyLedger.inventory, Icons.inventory_2_outlined),
                ],
              ),
              const SizedBox(height: 32),

              // Date Range & Exports (Responsive Wrap)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDateField('FROM', _fromDate, isFrom: true),
                      const SizedBox(width: 12),
                      _buildDateField('TO', _toDate, isFrom: false),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _load,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kTallyGold,
                      side: const BorderSide(color: Color(0xFFFDE68A)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('APPLY',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            fontSize: 11)),
                  ),

                  // Visual divider
                  Container(
                    height: 48,
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: AppColors.kBorder)),
                    ),
                    margin: const EdgeInsets.only(left: 8, right: 8),
                  ),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildActionButton(
                        label: 'XML',
                        icon: Icons.code,
                        color: kTallyNavy,
                        onPressed: () => _handleExport(TallyExportFormat.xml),
                      ),
                      _buildActionButton(
                        label: 'EXCEL',
                        icon: Icons.table_view,
                        color: kTallyGold,
                        onPressed: () => _handleExport(TallyExportFormat.excel),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _handleExport(TallyExportFormat.csv),
                        icon: const Icon(Icons.text_snippet_outlined, size: 14),
                        label: const Text('CSV',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                fontSize: 11)),
                        style: _outlinedStyle,
                      ),
                      OutlinedButton.icon(
                        onPressed: _isBusy ? null : _handlePreview,
                        icon: const Icon(Icons.visibility_outlined, size: 14),
                        label: const Text('PREVIEW',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                fontSize: 11)),
                        style: _outlinedStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- 2. Stats & Sync Action Row ---
        LayoutBuilder(builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

          Widget stats = Row(
            children: [
              Expanded(
                flex: 2,
                child: StatCard(
                  label: summary.label.toUpperCase(),
                  value: summary.totalDisplay,
                  icon: Icons.inventory_2_outlined,
                  color: kTallyNavy,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: StatCard(
                  label: 'ENTRIES',
                  value: '${summary.count}',
                  icon: Icons.description_outlined,
                  color: const Color(0xFF3B82F6),
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          );

          Widget syncSection = TallyCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('PUSH TO TALLY',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: kTallyMuted,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isBusy ? null : _handleSyncToTally,
                    icon: _isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync, size: 16),
                    label: Text(_activeLedger.syncLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                            letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTallyGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [stats, const SizedBox(height: 16), syncSection],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: stats),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: syncSection),
            ],
          );
        }),

        // --- Sales ledger also reports the output GST it collected ---
        if (summary.hasGst) ...[
          const SizedBox(height: 16),
          _buildGstStrip(summary),
        ],
        const SizedBox(height: 24),

        // --- 3. Ledger Entries Table ---
        _buildEntriesSection(),
      ],
    );
  }

  Widget _buildEntriesSection() {
    if (_isLoading && _result == null) {
      return TallyLoadingCard(label: 'LOADING ${_activeLedger.label}');
    }
    if (_error != null && _result == null) {
      return TallyErrorCard(message: _error!, onRetry: _load);
    }

    final rows = _result?.rows ?? const <TallyLedgerRow>[];
    if (rows.isEmpty) {
      return TallyEmptyCard(
        message: 'NO ENTRIES IN ${_activeLedger.label} FOR THIS DATE RANGE',
      );
    }

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
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('LEDGER ENTRIES',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: kTallyNavy,
                        letterSpacing: 1.5)),
                Text('${rows.length} RECORD(S)',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: kTallyMuted.withOpacity(0.8),
                        letterSpacing: 1)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.kBorder),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 48,
              ),
              child: DataTable(
                columnSpacing: 32,
                headingRowHeight: 56,
                dataRowMinHeight: 72,
                dataRowMaxHeight: 72,
                headingRowColor: WidgetStateProperty.all(kTallyTint),
                dividerThickness: 1,
                headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: kTallyMuted,
                    fontSize: 10,
                    letterSpacing: 1.5),
                columns: const [
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('REF')),
                  DataColumn(label: Text('PARTICULARS')),
                  DataColumn(label: Text('DEBIT')),
                  DataColumn(label: Text('CREDIT')),
                  DataColumn(label: Text('STATUS')),
                ],
                rows: rows.map((entry) {
                  return DataRow(
                    cells: [
                      DataCell(Text(entry.date,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: kTallySlate,
                              fontSize: 12))),
                      DataCell(Text(entry.ref,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: kTallyNavy,
                              fontSize: 12))),
                      DataCell(
                        SizedBox(
                          width: 250,
                          child: Text(entry.particulars,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: kTallySlate,
                                  fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(Text(entry.debitDisplay,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: kTallyNavy,
                              fontSize: 13))),
                      DataCell(Text(entry.creditDisplay,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: kTallyNavy,
                              fontSize: 13))),
                      DataCell(_buildStatusPill(entry.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGstStrip(TallyLedgerSummary summary) {
    return TallyCard(
      child: Wrap(
        spacing: 32,
        runSpacing: 16,
        children: [
          _buildGstFigure('OUTPUT GST COLLECTED', summary.gstCollected ?? 0),
          _buildGstFigure('CGST', summary.cgst ?? 0),
          _buildGstFigure('SGST', summary.sgst ?? 0),
          _buildGstFigure('GROSS INVOICE VALUE', summary.grossInvoice ?? 0),
        ],
      ),
    );
  }

  Widget _buildGstFigure(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: kTallyMuted,
                letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(formatInr(value),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: kTallyNavy)),
      ],
    );
  }

  Widget _buildStatusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Text(status.toUpperCase(),
          style: const TextStyle(
              color: kTallyGold,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic)),
    );
  }

  // --- Utility Builders ---

  ButtonStyle get _outlinedStyle => OutlinedButton.styleFrom(
        foregroundColor: kTallySlate,
        side: const BorderSide(color: AppColors.kBorder),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildSubTab(TallyLedger ledger, IconData icon) {
    bool isActive = _activeLedger == ledger;
    return InkWell(
      onTap: () => _selectLedger(ledger),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? kTallyNavy : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? kTallyNavy : AppColors.kBorder),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: kTallyNavy.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? kTallyAmber : AppColors.kTextMuted),
            const SizedBox(width: 8),
            Text(ledger.label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: isActive ? Colors.white : kTallyNavy)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime value, {required bool isFrom}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: kTallyMuted,
                letterSpacing: 1)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pickDate(isFrom: isFrom),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: kTallyTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Text(_displayDate(value),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: kTallyNavy)),
          ),
        ),
      ],
    );
  }
}
