import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/csv_file_saver.dart';
import 'package:frontend/shared/widgets/app_loader.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../../models/payout_reconciliation_model.dart';
import '../../../services/payout_reconciliation_service.dart';
import 'payout_detail_screen.dart';

class PayoutReconciliationScreen extends StatefulWidget {
  const PayoutReconciliationScreen({super.key});

  @override
  State<PayoutReconciliationScreen> createState() =>
      _PayoutReconciliationScreenState();
}

class _PayoutReconciliationScreenState
    extends State<PayoutReconciliationScreen> {
  final _service = PayoutReconciliationService();

  bool _isBusy = false;
  String? _busyLabel;
  String? _errorMessage;
  ReconciliationSummary? _summary;
  DateTime _lastUpdated = DateTime.now();

  /// Cashback payouts from `admin/payout_reports.php` — the STATUS MATRIX rows
  /// and the SYSTEM PULSE counts.
  List<ReconciliationLedgerRow> _ledger = const [];
  bool _loadingLedger = true;
  String? _ledgerError;

  /// null = ALL STATUS, else 'completed' | 'pending' | 'failed'.
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    setState(() {
      _loadingLedger = true;
      _ledgerError = null;
    });
    try {
      final rows = await _service.fetchLedger();
      if (!mounted) return;
      setState(() {
        _ledger = rows;
        _loadingLedger = false;
        _lastUpdated = DateTime.now();
      });
    } on ReconciliationException catch (e) {
      if (!mounted) return;
      setState(() {
        _ledgerError = e.message;
        _loadingLedger = false;
      });
    }
  }

  List<ReconciliationLedgerRow> get _visibleLedger {
    switch (_statusFilter) {
      case 'completed':
        return _ledger.where((r) => r.isSuccess).toList();
      case 'pending':
        return _ledger.where((r) => r.isPending).toList();
      case 'failed':
        return _ledger.where((r) => r.isFailed).toList();
      default:
        return _ledger;
    }
  }

  /// GET LIVE TEMPLATE — a CSV in the DOCUMENT SPECIFICATION layout,
  /// pre-filled with every payout still awaiting a bank result (pending or
  /// failed). Status defaults to Success; change it to Failed and add a
  /// reason for any transfer the bank rejected, then upload it back.
  Future<void> _downloadTemplate() async {
    final open = _ledger.where((r) => !r.isSuccess).toList();
    String esc(String v) => v.contains(',') || v.contains('"')
        ? '"${v.replaceAll('"', '""')}"'
        : v;
    final buffer = StringBuffer('Transaction ID,Status,Failure Reason\n');
    for (final r in open) {
      buffer.writeln('${r.transactionId},Success,${esc(r.failureReason ?? '')}');
    }
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    try {
      final saved =
          await saveCsvFile('bank_response_template_$stamp.csv', buffer.toString());
      if (!mounted || !saved) return;
      ToastService.show(
        title: 'Template Ready',
        message: open.isEmpty
            ? 'No payouts are awaiting a bank result — the template has headers only.'
            : '${open.length} open payout(s) pre-filled. Mark rejected ones as Failed.',
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
          title: 'Download Failed', message: '$e', type: ToastType.error);
    }
  }

  bool get _isMobile => MediaQuery.of(context).size.width < 600;

  Future<void> _handleFileSelected(PlatformFile file) async {
    setState(() {
      _isBusy = true;
      _busyLabel = 'Reading file...';
      _errorMessage = null;
    });

    try {
      // file_picker 12 dropped PlatformFile.bytes — the contents are read on
      // demand instead, which also works for files the picker never buffered.
      final Uint8List bytes = await file.readAsBytes();

      final rows = _service.parseFile(file.name, bytes);
      if (rows.isEmpty) {
        throw ReconciliationException(
          'No data rows found. Check the file matches the column spec.',
        );
      }

      if (!mounted) return;
      setState(() => _busyLabel = 'Reconciling ${rows.length} record(s)...');
      final summary = await _service.submitReconciliation(rows);

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _lastUpdated = DateTime.now();
      });
      await _loadLedger();
    } on ReconciliationException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Something went wrong: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _busyLabel = null;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    // file_picker 12 made pickFiles a static that returns the selected files
    // directly (empty when the user cancels) instead of a nullable result.
    final List<PlatformFile> files = await FilePicker.pickFiles(
      dialogTitle: 'Select the bank response file',
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx', 'xls'],
    );
    if (files.isEmpty) return;
    await _handleFileSelected(files.first);
  }

  void _handleRefresh() {
    setState(() {
      _summary = null;
      _errorMessage = null;
    });
    _loadLedger();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = _isMobile ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(horizontalPadding),
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
                    hintStyle: TextStyle(
                      color: AppColors.kTextMuted,
                      fontSize: 14,
                    ),
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

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBankResponseHub(context),
                        const SizedBox(height: 24),
                        _buildSystemPulse(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildBankResponseHub(context)),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: _buildSystemPulse()),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              _buildStatusMatrix(context),
              const SizedBox(height: 40),
            ],
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
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFFB91C1C)),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  // --- 1. Bank Response Hub ---
  Widget _buildBankResponseHub(BuildContext context) {
    final cardPadding = _isMobile ? 20.0 : 32.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BANK RESPONSE HUB',
                      style: TextStyle(
                        fontSize: _isMobile ? 18 : 22,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PAYOUT RECONCILIATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          InkWell(
            onTap: _isBusy ? null : _pickFile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: _isBusy
                  ? Column(
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          (_busyLabel ?? 'Processing...').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(Icons.upload_file,
                            color: Colors.white.withOpacity(0.8), size: 32),
                        const SizedBox(height: 12),
                        const Text(
                          'UPLOAD BANK RESPONSE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Excel or CSV documents.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          if (_summary != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFFFBBF24), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Processed ${_summary!.totalProcessed} record(s): '
                      '${_summary!.successCount} succeeded, '
                      '${_summary!.failedCount} failed.',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          const Text(
            'DOCUMENT SPECIFICATION',
            style: TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpecItem('Column 1: Transaction ID'),
          const SizedBox(height: 8),
          _buildSpecItem('Column 2: Status (Success/Failed)'),
          const SizedBox(height: 8),
          _buildSpecItem('Column 3: Failure Reason'),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loadingLedger ? null : _downloadTemplate,
              icon: const Icon(Icons.download, size: 16),
              label: const Text(
                'GET LIVE TEMPLATE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                backgroundColor: Colors.white.withOpacity(0.05),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String text) {
    return Row(
      children: [
        const Icon(Icons.star, size: 4, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --- 2. System Pulse ---
  Widget _buildSystemPulse() {
    final pending = _ledger.where((r) => r.isPending).length;
    final success = _ledger.where((r) => r.isSuccess).length;
    final failed = _ledger.where((r) => r.isFailed).length;
    final timeLabel = DateFormat('h:mm:ss a').format(_lastUpdated);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      padding: EdgeInsets.all(_isMobile ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SYSTEM PULSE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.5,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.star,
                      size: 8, color: _isBusy ? const Color(0xFFD97706) : const Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF94A3B8).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPulseStatRow('PENDING BATCH', '$pending', Icons.pending_actions, const Color(0xFFD97706)),
          const SizedBox(height: 12),
          _buildPulseStatRow('RECONCILED SUCCESS', '$success', Icons.check_circle_outline, const Color(0xFF16A34A)),
          const SizedBox(height: 12),
          _buildPulseStatRow('FAILURE INTERCEPTS', '$failed', Icons.cancel_outlined, const Color(0xFF3B82F6)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isBusy || _loadingLedger ? null : _handleRefresh,
              icon: _loadingLedger
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: const Text(
                'REFRESH RECORDS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseStatRow(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Status Matrix ---
  // Every cashback payout from admin/payout_reports.php, with its current
  // status and the bank's failure reason (if any).
  static const Map<String?, String> _statusOptions = {
    null: 'ALL STATUS',
    'completed': 'COMPLETED',
    'pending': 'PENDING',
    'failed': 'FAILED',
  };

  Widget _buildStatusMatrix(BuildContext context) {
    final rows = _visibleLedger;

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storage, color: Color(0xFFD97706), size: 20),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STATUS MATRIX',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'DATA VERIFICATION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF94A3B8).withOpacity(0.8),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton<String?>(
                  tooltip: 'Filter by status',
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) => setState(() => _statusFilter = v),
                  itemBuilder: (_) => [
                    for (final e in _statusOptions.entries)
                      PopupMenuItem<String?>(
                        value: e.key,
                        child: Text(e.value,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF1E3A8A))),
                      ),
                  ],
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.kBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_alt_outlined,
                            size: 16, color: AppColors.kTextMuted),
                        const SizedBox(width: 8),
                        Text(
                          _statusOptions[_statusFilter]!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.kBorder),

          if (_loadingLedger && _ledger.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: AppLoader()),
            )
          else if (_ledgerError != null && _ledger.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
              child: Column(
                children: [
                  Text(_ledgerError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFB91C1C))),
                  const SizedBox(height: 16),
                  OutlinedButton(
                      onPressed: _loadLedger, child: const Text('RETRY')),
                ],
              ),
            )
          else if (rows.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columnSpacing: 48,
                  horizontalMargin: 32,
                  headingRowHeight: 56,
                  dataRowMinHeight: 76,
                  dataRowMaxHeight: 84,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  dividerThickness: 1,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                  columns: const [
                    DataColumn(label: Text('INVESTOR ID')),
                    DataColumn(label: Text('TRANSACTION')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ACTION NEEDED')),
                    DataColumn(label: Text('ACTIONS'), numeric: true),
                  ],
                  rows: rows.map(_buildLedgerRow).toList(),
                ),
              ),
            ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 40,
                    color: const Color(0xFFCBD5E1).withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusFilter == null
                        ? 'NO PAYOUT RECORDS FOUND'
                        : 'NO ${_statusOptions[_statusFilter]} RECORDS',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  DataRow _buildLedgerRow(ReconciliationLedgerRow r) {
    final (Color bg, Color fg, IconData icon) = r.isFailed
        ? (const Color(0xFFFEF2F2), const Color(0xFFB91C1C), Icons.cancel_outlined)
        : r.isPending
            ? (const Color(0xFFFFF7ED), const Color(0xFFEA580C), Icons.schedule)
            : (const Color(0xFFFEF9EC), const Color(0xFFC9A227),
                Icons.check_circle_outline);
    final at = r.createdAt;

    return DataRow(cells: [
      DataCell(SizedBox(
        width: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(r.investorName.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF1E3A8A),
                    letterSpacing: -0.3,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text('ID: ${r.investorId}',
                style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      )),
      DataCell(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('#${r.transactionId}',
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF334155),
                  letterSpacing: 0.5,
                  fontSize: 12)),
          const SizedBox(height: 2),
          Text(at == null ? '—' : DateFormat('d/M/yyyy, h:mm:ss a').format(at),
              style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
        ],
      )),
      DataCell(Container(
        constraints: const BoxConstraints(minWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 8),
            Text(r.status.toUpperCase(),
                style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 10,
                    letterSpacing: 1.2)),
          ],
        ),
      )),
      DataCell(Text(
        (r.failureReason ?? 'NOT SPECIFIED').toUpperCase(),
        style: TextStyle(
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            fontSize: 11,
            letterSpacing: 0.6,
            color: r.isFailed
                ? const Color(0xFFB91C1C)
                : const Color(0xFF334155)),
      )),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionIcon(Icons.visibility_outlined, 'View payout', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PayoutDetailScreen(payout: r)),
            );
          }),
          const SizedBox(width: 12),
          _actionIcon(
            Icons.history,
            'Customer ledger',
            r.investorId.isEmpty
                ? null
                : () => PayoutDetailScreen.openLedger(context, r),
          ),
        ],
      )),
    ]);
  }

  Widget _actionIcon(IconData icon, String tooltip, VoidCallback? onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.kBorder, width: 1.4),
          ),
          child: Icon(icon,
              size: 18,
              color: onTap == null
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF475569)),
        ),
      ),
    );
  }
}
