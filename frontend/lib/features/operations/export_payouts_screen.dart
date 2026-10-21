import 'dart:async';

import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/core/utils/csv_file_saver.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

import '../../models/export_payout_model.dart';
import '../../models/wallet_account_model.dart' show WalletAccount;
import '../../services/export_payouts_service.dart';
import '../../services/wallet_account_service.dart';
import 'wallet_purchase_history.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

/// Export Payout File — the latest cashback payouts with the payee's bank
/// details, and a bulk-transfer file built from whatever the filters show.
///
/// Rows and stat cards: `GET admin/payout_history.php` (one request).
/// GENERATE BULK TRANSFER: builds an .xlsx bank file from the visible rows,
/// downloads it, then `POST admin/export_payouts.php` logs the batch in
/// export history with the rows' `transactions.id`s (the backend marks those
/// transactions completed). Past batches: `GET admin/export_payouts.php`.
class ExportPayoutsScreen extends StatefulWidget {
  const ExportPayoutsScreen({super.key});

  @override
  State<ExportPayoutsScreen> createState() => _ExportPayoutsScreenState();
}

class _ExportPayoutsScreenState extends State<ExportPayoutsScreen> {
  static const Color _navy = Color(0xFF1E3A8A);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _surface = Color(0xFFF8FAFC);
  static const Duration _syncInterval = Duration(seconds: 30);

  /// Bank filter values that aren't a bank name.
  static const String _bankConfigured = '__configured__';
  static const String _bankMissing = '__missing__';

  final ExportPayoutsService _service = ExportPayoutsService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  Timer? _syncTimer;

  PayoutStats _stats = const PayoutStats();
  List<PayoutTransfer> _transfers = [];
  List<ExportHistoryRecord> _history = [];

  /// Filters — every one starts at "all".
  String? _statusFilter; // null = ALL STATUS
  String? _bankFilter; // null = every bank node
  DateTime? _dateFilter; // null = any date

  /// Wallet rows, fetched on the first LEDGER tap: payout_history.php has
  /// no user_id, so the payee is matched to their wallet by email.
  List<WalletAccount>? _wallets;
  final Set<String> _openingLedger = {};

  bool _isLoading = true;
  bool _syncing = false;
  bool _generating = false;
  String? _error;
  DateTime? _lastSyncedAt;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _searchController.addListener(_onSearchChanged);
    _syncTimer = Timer.periodic(_syncInterval, (_) => _loadAll(silent: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _syncTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------

  Future<void> _loadAll({bool silent = false}) async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      if (!silent) {
        _isLoading = _transfers.isEmpty;
        _error = null;
      }
    });
    try {
      final results = await Future.wait([
        _service.fetchPayoutHistory(),
        _service.fetchExportHistory(),
      ]);
      if (!mounted) return;
      final bundle = results[0] as PayoutHistoryBundle;
      setState(() {
        _stats = bundle.stats;
        _transfers = bundle.transfers;
        _history = results[1] as List<ExportHistoryRecord>;
        _lastSyncedAt = DateTime.now();
        _error = null;
        _isLoading = false;
        _syncing = false;
        // Drop a bank filter that no longer matches any bank in the data.
        if (_bankFilter != null &&
            _bankFilter != _bankConfigured &&
            _bankFilter != _bankMissing &&
            !_bankNames.contains(_bankFilter)) {
          _bankFilter = null;
        }
      });
    } on WalletServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        // A failed background sync keeps the rows already on screen.
        if (!silent || _transfers.isEmpty) _error = e.message;
        _isLoading = false;
        _syncing = false;
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() {});
    });
  }

  List<String> get _bankNames {
    final names = <String>{
      for (final t in _transfers)
        if ((t.bankName ?? '').isNotEmpty) t.bankName!,
    }.toList()
      ..sort();
    return names;
  }

  List<PayoutTransfer> get _visible {
    final q = _searchController.text.trim().toLowerCase();
    return _transfers.where((t) {
      if (_statusFilter != null) {
        if (_statusFilter == 'completed' && !t.isCompleted) return false;
        if (_statusFilter != 'completed' && t.status != _statusFilter) {
          return false;
        }
      }
      if (_bankFilter == _bankConfigured && !t.hasBankDetails) return false;
      if (_bankFilter == _bankMissing && t.hasBankDetails) return false;
      if (_bankFilter != null &&
          _bankFilter != _bankConfigured &&
          _bankFilter != _bankMissing &&
          t.bankName != _bankFilter) {
        return false;
      }
      final d = _dateFilter;
      if (d != null) {
        final at = t.createdAt;
        if (at == null ||
            at.year != d.year ||
            at.month != d.month ||
            at.day != d.day) {
          return false;
        }
      }
      if (q.isEmpty) return true;
      return t.customerName.toLowerCase().contains(q) ||
          (t.customerEmail ?? '').toLowerCase().contains(q) ||
          (t.accountNumber ?? '').toLowerCase().contains(q) ||
          (t.ifscCode ?? '').toLowerCase().contains(q) ||
          (t.bankName ?? '').toLowerCase().contains(q);
    }).toList();
  }

  double _total(List<PayoutTransfer> rows) =>
      rows.fold(0.0, (sum, t) => sum + t.amount);

  // ---------------------------------------------------------------------------
  // BULK TRANSFER FILE
  // ---------------------------------------------------------------------------

  String _buildFilename() =>
      'bulk_transfer_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

  List<int> _buildWorkbook(List<PayoutTransfer> rows) {
    const sheetName = 'Bulk Transfer';
    final book = xl.Excel.createExcel();
    book.rename(book.getDefaultSheet() ?? 'Sheet1', sheetName);
    final sheet = book[sheetName];

    const headers = [
      'S.NO', 'TXN ID', 'BENEFICIARY NAME', 'EMAIL', 'BANK NAME',
      'ACCOUNT NUMBER', 'IFSC', 'AMOUNT (₹)', 'PAYOUT', 'DATE', 'STATUS',
      'NARRATION',
    ];
    const amountColumn = 7;
    xl.TextCellValue text(String? v) => xl.TextCellValue(v ?? '');
    final date = DateFormat('dd MMM yyyy');

    sheet.appendRow([for (final h in headers) xl.TextCellValue(h)]);
    for (var i = 0; i < rows.length; i++) {
      final t = rows[i];
      sheet.appendRow([
        xl.IntCellValue(i + 1),
        text(t.transactionId),
        text(t.customerName),
        text(t.customerEmail),
        text(t.bankName),
        text(t.accountNumber),
        text(t.ifscCode),
        xl.DoubleCellValue(t.amount),
        text(t.yieldLabel),
        text(t.createdAt == null ? '' : date.format(t.createdAt!)),
        text(t.status.toUpperCase()),
        text(t.description),
      ]);
    }
    sheet.appendRow([
      null, null, xl.TextCellValue('TOTAL (${rows.length})'), null, null,
      null, null, xl.DoubleCellValue(_total(rows)),
    ]);

    final headerStyle = xl.CellStyle(
      bold: true,
      fontColorHex: xl.ExcelColor.white,
      backgroundColorHex: xl.ExcelColor.fromHexString('FF1E3A8A'),
      horizontalAlign: xl.HorizontalAlign.Center,
    );
    final moneyStyle = xl.CellStyle(numberFormat: xl.NumFormat.standard_4);
    final totalStyle = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('FFFEF3C7'),
      numberFormat: xl.NumFormat.standard_4,
    );
    xl.Data cell(int c, int r) =>
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));

    final lastRow = rows.length + 1;
    for (var c = 0; c < headers.length; c++) {
      cell(c, 0).cellStyle = headerStyle;
    }
    for (var r = 1; r < lastRow; r++) {
      cell(amountColumn, r).cellStyle = moneyStyle;
    }
    cell(2, lastRow).cellStyle = totalStyle;
    cell(amountColumn, lastRow).cellStyle = totalStyle;

    const widths = [
      7.0, 10.0, 26.0, 30.0, 22.0, 22.0, 14.0, 16.0, 14.0, 14.0, 12.0, 70.0,
    ];
    for (var c = 0; c < widths.length; c++) {
      sheet.setColumnWidth(c, widths[c]);
    }
    return book.encode() ?? (throw Exception('Could not build the file.'));
  }

  void _previewBatch() {
    final batch = _visible;
    if (batch.isEmpty) {
      ToastService.show(
        title: 'Nothing to preview',
        message: 'No payouts match the current filters.',
        type: ToastType.warning,
      );
      return;
    }
    final missingBank = batch.where((t) => !t.hasBankDetails).length;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'BATCH PREVIEW',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: _navy,
          ),
        ),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${batch.length} RECORDS · ${_inr(_total(batch))}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: _gold,
                  letterSpacing: 1,
                ),
              ),
              if (missingBank > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '$missingBank of them have no bank details configured and '
                  'will export with blank account fields.',
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                ),
              ],
              const SizedBox(height: 16),
              Flexible(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var i = 0; i < batch.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AppColors.kBorder),
                          _previewRow(batch[i]),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _generateBulkTransfer();
            },
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: const Text('GENERATE'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _navy, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(PayoutTransfer t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.customerName.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: _navy,
                          fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    t.hasBankDetails
                        ? '${t.bankName ?? 'BANK'} · ${t.accountNumber} · ${t.ifscCode}'
                        : 'BANK NOT CONFIGURED',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10,
                        color: t.hasBankDetails
                            ? _muted
                            : const Color(0xFFB91C1C)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(_inr(t.amount),
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: _navy)),
          ],
        ),
      );

  Future<void> _generateBulkTransfer() async {
    if (_generating) return;
    final batch = _visible;
    if (batch.isEmpty) {
      ToastService.show(
        title: 'Nothing to export',
        message: 'No payouts match the current filters.',
        type: ToastType.warning,
      );
      return;
    }

    final filename = _buildFilename();
    final total = _total(batch);
    final missingBank = batch.where((t) => !t.hasBankDetails).length;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'GENERATE BULK TRANSFER',
      message: 'Generate "$filename" with ${batch.length} payout'
          '${batch.length == 1 ? '' : 's'} totalling ${_inr(total)}?\n\n'
          'The Excel bank file downloads now, the batch is logged in export '
          'history and these payouts are marked COMPLETED.'
          '${missingBank > 0 ? '\n\n$missingBank payee${missingBank == 1 ? ' has' : 's have'} no bank details configured.' : ''}',
      confirmLabel: 'GENERATE',
      cancelLabel: 'CANCEL',
      confirmButtonColor: _navy,
    );
    if (confirmed != true) return;

    setState(() => _generating = true);
    try {
      final saved = await saveBinaryFile(
        filename,
        _buildWorkbook(batch),
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (!saved) return; // share sheet dismissed — nothing to record

      await _service.recordExport(
        filename: filename,
        exportType: 'Bank Bulk Transfer',
        totalAmount: total,
        totalRecords: batch.length,
        transactionIds: [
          for (final t in batch)
            if (int.tryParse(t.transactionId) != null)
              int.parse(t.transactionId),
        ],
      );
      if (!mounted) return;
      ToastService.show(
        title: 'Bulk Transfer Ready',
        message: '$filename downloaded and logged in export history.',
        type: ToastType.success,
      );
      await _loadAll();
    } on WalletServiceException catch (e) {
      if (!mounted) return;
      ToastService.show(
        title: 'Export Not Recorded',
        message: 'The file was downloaded, but logging the batch failed: '
            '${e.message}',
        type: ToastType.error,
      );
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
          title: 'Export Failed', message: '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  WalletAccount? _walletFor(PayoutTransfer t) {
    final email = (t.customerEmail ?? '').trim().toLowerCase();
    for (final w in _wallets ?? const <WalletAccount>[]) {
      if (email.isNotEmpty && (w.userEmail ?? '').trim().toLowerCase() == email) {
        return w;
      }
    }
    return null;
  }

  /// LEDGER — opens the payee's transaction ledger.
  Future<void> _openLedger(PayoutTransfer t) async {
    if (_openingLedger.contains(t.transactionId)) return;
    setState(() => _openingLedger.add(t.transactionId));
    try {
      var wallet = _wallets == null ? null : _walletFor(t);
      if (wallet == null) {
        // First use, or a payee added since the cache was filled.
        _wallets = await WalletService().fetchWallets();
        wallet = _walletFor(t);
      }
      if (!mounted) return;
      if (wallet == null) {
        ToastService.show(
          title: 'Ledger Unavailable',
          message: 'No wallet was found for ${t.customerName}.',
          type: ToastType.warning,
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => WalletPurchaseHistoryScreen(wallet: wallet!)),
      );
    } on WalletServiceException catch (e) {
      if (!mounted) return;
      ToastService.show(
          title: 'Ledger Unavailable', message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _openingLedger.remove(t.transactionId));
    }
  }

  Widget _ledgerButton(PayoutTransfer t) {
    final busy = _openingLedger.contains(t.transactionId);
    return OutlinedButton.icon(
      onPressed: busy ? null : () => _openLedger(t),
      icon: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _muted),
            )
          : const Icon(Icons.history, size: 20),
      label: const Text('LEDGER',
          style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.6)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF475569),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.kBorder, width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null && mounted) setState(() => _dateFilter = picked);
  }

  void _showDetails(PayoutTransfer t) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.customerName.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: _navy)),
              if (t.customerEmail != null)
                Text(t.customerEmail!,
                    style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 18),
              _detailLine('PAYOUT', '${_inr(t.amount)} · ${t.yieldLabel}'),
              _detailLine('BANK', t.bankName ?? 'NOT CONFIGURED'),
              _detailLine('ACCOUNT', t.accountNumber ?? 'N/A'),
              _detailLine('IFSC', t.ifscCode ?? 'N/A'),
              _detailLine('STATUS', t.status.toUpperCase()),
              _detailLine(
                  'DATE',
                  t.createdAt == null
                      ? '—'
                      : DateFormat('dd MMM yyyy, hh:mm a').format(t.createdAt!)),
              _detailLine('TXN ID', '#${t.transactionId}'),
              if (t.description != null) ...[
                const SizedBox(height: 12),
                Text(t.description!,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 12, height: 1.4)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailLine(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _muted,
                      letterSpacing: 1)),
            ),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: _navy)),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return RefreshIndicator(
            onRefresh: _loadAll,
            color: _navy,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 14 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActionHeader(isMobile),
                  SizedBox(height: isMobile ? 20 : 32),
                  _buildStatsGrid(constraints.maxWidth),
                  SizedBox(height: isMobile ? 20 : 32),
                  _buildFiltersBar(isMobile),
                  SizedBox(height: isMobile ? 20 : 32),
                  _buildTable(isMobile),
                  const SizedBox(height: 32),
                  _buildExportHistory(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 36}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      );

  Widget _buildActionHeader(bool isMobile) {
    final t = _lastSyncedAt;
    final pulse = t == null
        ? 'AWAITING FIRST SYNC'
        : 'LIVE SYNC ACTIVE • PULSE: ${DateFormat('h:mm:ss a').format(t)}';

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description_outlined, color: _gold, size: 30),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                'EXPORT PAYOUT FILE',
                style: TextStyle(
                    fontSize: isMobile ? 20 : 28,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -1,
                    color: _navy),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  const BoxDecoration(color: _gold, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                pulse,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: _muted,
                    letterSpacing: 2.2),
              ),
            ),
          ],
        ),
      ],
    );

    final count = _visible.length;
    final buttons = Wrap(
      spacing: 14,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Tooltip(
          message: 'Sync now',
          child: InkWell(
            onTap: _syncing ? null : _loadAll,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.kBorder),
              ),
              child: _syncing
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _muted),
                    )
                  : const Icon(Icons.sync, size: 22, color: _muted),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _previewBatch,
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('PREVIEW BATCH',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.6)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF334155),
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.kBorder, width: 1.4),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _generating ? null : _generateBulkTransfer,
          icon: _generating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.file_download_outlined,
                  size: 20, color: _gold),
          label: Text(
            _generating
                ? 'GENERATING...'
                : 'GENERATE BULK TRANSFER${count > 0 ? ' ($count)' : ''}',
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: 12,
                letterSpacing: 2.2),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _navy.withValues(alpha: 0.6),
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            elevation: 10,
            shadowColor: _navy.withValues(alpha: 0.35),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: _cardDecoration(),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 20), buttons],
            )
          : Row(
              children: [
                Expanded(child: title),
                const SizedBox(width: 16),
                buttons,
              ],
            ),
    );
  }

  // --- Stats ----------------------------------------------------------------

  Widget _buildStatsGrid(double width) {
    final cards = [
      _statCard(Icons.attach_money, "TODAY'S YIELD", _inr(_stats.todayYield),
          _gold, const Color(0xFFFBF6E9)),
      _statCard(Icons.people_outline, 'ACTIVE CYCLES', '${_stats.activeCycles}',
          _blue, const Color(0xFFEEF4FF)),
      _statCard(Icons.check_circle_outline, 'TOTAL PAID',
          _inr(_stats.totalPaid), _gold, const Color(0xFFFBF6E9)),
      _statCard(Icons.calendar_today_outlined, 'LAST PAYOUT',
          _stats.lastPayout.split(' ').first, _blue, const Color(0xFFEEF4FF)),
    ];
    final columns = width >= 1000 ? 4 : (width >= 340 ? 2 : 1);
    const gap = 20.0;
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final card in cards) SizedBox(width: w, child: card)],
      );
    });
  }

  Widget _statCard(
      IconData icon, String label, String value, Color accent, Color tint) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(radius: 40),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(height: 26),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: _muted,
                        letterSpacing: 1.8)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -1,
                          color: _navy)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Filters --------------------------------------------------------------

  Widget _buildFiltersBar(bool isMobile) {
    final search = Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, color: _navy),
        decoration: InputDecoration(
          hintText: 'SEARCH INVESTOR OR ACCOUNT...',
          hintStyle: const TextStyle(
              color: _muted,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 20, right: 12),
            child: Icon(Icons.search, color: _muted, size: 22),
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: _muted),
                  onPressed: _searchController.clear,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 22),
        ),
      ),
    );

    final bankItems = <String?, String>{
      null: 'BANK NODE',
      _bankConfigured: 'CONFIGURED',
      _bankMissing: 'NOT CONFIGURED',
      for (final b in _bankNames) b: b.toUpperCase(),
    };
    const statusItems = <String?, String>{
      null: 'ALL STATUS',
      'completed': 'COMPLETED',
      'pending': 'PENDING',
      'failed': 'FAILED',
    };

    final filters = Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _dropdownPill(Icons.account_balance_outlined, _bankFilter, bankItems,
            (v) => setState(() => _bankFilter = v)),
        _dropdownPill(Icons.verified_user_outlined, _statusFilter, statusItems,
            (v) => setState(() => _statusFilter = v)),
        _datePill(),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 32),
      decoration: _cardDecoration(radius: 44),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [search, const SizedBox(height: 16), filters],
            )
          : Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 24),
                filters,
              ],
            ),
    );
  }

  Widget _pillShell({required Widget child}) => Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.kBorder),
        ),
        alignment: Alignment.center,
        child: child,
      );

  Widget _dropdownPill(IconData icon, String? value, Map<String?, String> items,
      ValueChanged<String?> onChanged) {
    return _pillShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          icon: const SizedBox.shrink(),
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF0F172A)),
          onChanged: onChanged,
          selectedItemBuilder: (_) => [
            for (final label in items.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: _muted),
                  const SizedBox(width: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(label, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 18),
                ],
              ),
          ],
          items: [
            for (final e in items.entries)
              DropdownMenuItem<String?>(value: e.key, child: Text(e.value)),
          ],
        ),
      ),
    );
  }

  Widget _datePill() {
    final d = _dateFilter ?? DateTime.now();
    final set = _dateFilter != null;
    TextStyle part(bool strong) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: set ? _navy : (strong ? const Color(0xFF0F172A) : _muted));
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(22),
      child: _pillShell(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 20, color: _muted),
            const SizedBox(width: 18),
            Text.rich(TextSpan(children: [
              TextSpan(text: d.day.toString().padLeft(2, '0'), style: part(false)),
              TextSpan(text: '/', style: part(true)),
              TextSpan(
                  text: d.month.toString().padLeft(2, '0'), style: part(false)),
              TextSpan(text: '/', style: part(true)),
              TextSpan(text: '${d.year}', style: part(false)),
            ])),
            if (set) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () => setState(() => _dateFilter = null),
                child: const Icon(Icons.close, size: 16, color: _muted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Table ----------------------------------------------------------------

  Widget _buildTable(bool isMobile) {
    final rows = _visible;
    Widget body;
    if (_isLoading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: AppLoader()),
      );
    } else if (_error != null && _transfers.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _loadAll, child: const Text('RETRY')),
          ],
        ),
      );
    } else if (rows.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(
          child: Text(
            'NO PAYOUTS MATCH THE CURRENT FILTERS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: _muted,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );
    } else if (isMobile) {
      body = Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.kBorder),
            _mobileRow(rows[i]),
          ],
        ],
      );
    } else {
      body = LayoutBuilder(builder: (context, c) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: c.maxWidth),
            child: DataTable(
              horizontalMargin: 32,
              columnSpacing: 40,
              headingRowHeight: 72,
              dataRowMinHeight: 128,
              dataRowMaxHeight: 136,
              headingRowColor: WidgetStateProperty.all(_surface),
              dividerThickness: 1,
              showCheckboxColumn: false,
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: _muted,
                fontSize: 12,
                letterSpacing: 2,
              ),
              columns: const [
                DataColumn(label: Text('CUSTOMER')),
                DataColumn(label: Text('BANK DETAILS')),
                DataColumn(label: Text('PAYOUT VALUE')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS'), numeric: true),
              ],
              rows: [
                for (final t in rows)
                  DataRow(
                    onSelectChanged: (_) => _showDetails(t),
                    cells: [
                      DataCell(SizedBox(width: 300, child: _customerCell(t))),
                      DataCell(_bankCell(t)),
                      DataCell(_payoutCell(t)),
                      DataCell(_statusChip(t)),
                      DataCell(_ledgerButton(t)),
                    ],
                  ),
              ],
            ),
          ),
        );
      });
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(radius: 44),
      child: body,
    );
  }

  Widget _mobileRow(PayoutTransfer t) {
    return InkWell(
      onTap: () => _showDetails(t),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _customerCell(t)),
                const SizedBox(width: 12),
                _ledgerButton(t),
              ],
            ),
            const SizedBox(height: 14),
            _bankCell(t),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [_payoutCell(t), _statusChip(t)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _customerCell(PayoutTransfer t) {
    final name = t.customerName.trim();
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _navy,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE0E7FF), width: 3),
          ),
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            style: const TextStyle(
                color: Color(0xFFFBBF24),
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: 17),
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: _navy,
                      letterSpacing: -0.4,
                      fontSize: 16)),
              if (t.customerEmail != null)
                Text(t.customerEmail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bankCell(PayoutTransfer t) {
    const meta = TextStyle(
        color: _muted,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_outlined, size: 16, color: _gold),
            const SizedBox(width: 12),
            Text(
              (t.bankName ?? 'NOT CONFIGURED').toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: _navy,
                  fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('ACC: ${t.accountNumber ?? 'N/A'}', style: meta),
        const SizedBox(height: 6),
        Text('IFSC: ${(t.ifscCode ?? 'N/A').toUpperCase()}', style: meta),
      ],
    );
  }

  Widget _payoutCell(PayoutTransfer t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_inr(t.amount),
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: _navy,
                letterSpacing: -0.4,
                fontSize: 17)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(t.yieldLabel,
              style: const TextStyle(
                  color: _blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4)),
        ),
      ],
    );
  }

  Widget _statusChip(PayoutTransfer t) {
    final (bg, border, fg) = t.isFailed
        ? (const Color(0xFFFEF2F2), const Color(0xFFFECACA),
            const Color(0xFFDC2626))
        : t.isPending
            ? (const Color(0xFFFFF7ED), const Color(0xFFFED7AA),
                const Color(0xFFEA580C))
            : (const Color(0xFFFEF9EC), const Color(0xFFF5E6B8), _gold);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(t.status.toUpperCase(),
              style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                  letterSpacing: 1.4)),
        ],
      ),
    );
  }

  // --- Export history -------------------------------------------------------

  Widget _buildExportHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: _gold, size: 18),
            const SizedBox(width: 8),
            const Text(
              'EXPORT HISTORY',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: _navy,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Text(
              '${_history.length} BATCHES',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: _muted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: _cardDecoration(radius: 28),
          child: _history.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'NO EXPORT BATCHES RECORDED YET',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFCBD5E1),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < _history.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.kBorder),
                      _historyRow(_history[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _historyRow(ExportHistoryRecord h) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 18, color: _muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.filename ?? 'Unnamed batch',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: _navy,
                      fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${h.exportType ?? 'Export'} · ${h.createdAtLabel}',
                  style: const TextStyle(color: _muted, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _inr(h.totalAmount),
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: _navy,
                    fontSize: 13),
              ),
              Text(
                '${h.totalRecords} RECORDS',
                style: const TextStyle(
                    color: _muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ₹ with Indian digit grouping; paise only when there are any.
  static String _inr(double value) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: (value * 100).round() % 100 == 0 ? 0 : 2,
      ).format(value);
}
