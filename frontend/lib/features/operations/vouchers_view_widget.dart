import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/models/tally_integration_model.dart';
import 'package:frontend/services/tally_integration_service.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tally_state_views.dart';
import 'voucher_form_dialog.dart';

/// Managed vouchers (`tally_vouchers`) — create, auto-generate from a ledger,
/// post, delete, export and push the whole set into Tally.
class VouchersViewWidget extends StatefulWidget {
  const VouchersViewWidget({super.key});

  @override
  State<VouchersViewWidget> createState() => _VouchersViewWidgetState();
}

class _VouchersViewWidgetState extends State<VouchersViewWidget> {
  static const String _autoGeneratePlaceholder = '+ AUTO-GENERATE FROM...';

  final TallyIntegrationService _service = TallyIntegrationService();

  TallyVoucherResult _result = const TallyVoucherResult();
  bool _isLoading = true;
  bool _isBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.fetchVouchers();
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

  // --- Actions ---

  /// Runs [action], showing a toast for whatever it returns and reloading the
  /// list afterwards. Keeps every button's error handling identical.
  Future<void> _run(
    Future<String> Function() action, {
    required String successTitle,
  }) async {
    setState(() => _isBusy = true);
    try {
      final message = await action();
      if (!mounted) return;
      ToastService.show(
        title: successTitle,
        message: message,
        type: ToastType.success,
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
    ToastService.show(title: 'Action Failed', message: message, type: ToastType.error);
  }

  Future<void> _handleNewVoucher() async {
    final draft = await VoucherFormDialog.show(context);
    if (draft == null) return;
    await _run(
      () async {
        await _service.createVoucher(draft);
        return 'Voucher ${draft.voucherNo.isEmpty ? '' : '${draft.voucherNo} '}created as a draft.';
      },
      successTitle: 'Voucher Created',
    );
  }

  Future<void> _handleEditVoucher(TallyVoucher voucher) async {
    final draft = await VoucherFormDialog.show(context, existing: voucher);
    if (draft == null) return;
    await _run(
      () async {
        await _service.updateVoucher(draft);
        return 'Voucher ${draft.voucherNo} updated.';
      },
      successTitle: 'Voucher Updated',
    );
  }

  Future<void> _handlePostVoucher(TallyVoucher voucher) => _run(
        () async {
          await _service.postVoucher(voucher.id);
          return '${voucher.voucherNo} is now marked posted and ready to sync.';
        },
        successTitle: 'Voucher Posted',
      );

  Future<void> _handleDeleteVoucher(TallyVoucher voucher) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'DELETE VOUCHER',
      message: 'Remove ${voucher.voucherNo} (${voucher.amountDisplay})? '
          'This cannot be undone.',
      confirmLabel: 'DELETE',
      cancelLabel: 'CANCEL',
    );
    if (confirmed != true) return;

    await _run(
      () async {
        await _service.deleteVoucher(voucher.id);
        return '${voucher.voucherNo} was removed.';
      },
      successTitle: 'Voucher Deleted',
    );
  }

  Future<void> _handleAutoGenerate(TallyLedger source) => _run(
        () async {
          final created = await _service.generateVouchers(source);
          return created == 0
              // The backend skips references that already have a voucher.
              ? 'Nothing new to generate — every ${source.label.toLowerCase()} entry already has a voucher.'
              : 'Generated $created draft voucher(s) from the ${source.label.toLowerCase()}.';
        },
        successTitle: 'Auto-Generate Complete',
      );

  Future<void> _handleSyncAll() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'SYNC ALL VOUCHERS',
      message:
          'Push every draft and posted voucher into Tally? Make sure TallyPrime is open with the gateway enabled (port 9000).',
      confirmLabel: 'OK',
      cancelLabel: 'CANCEL',
      confirmButtonColor: kTallyGold,
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final result = await _service.syncVouchers();
      if (!mounted) return;
      ToastService.show(
        title: result.isOffline ? 'Tally Not Reachable' : 'Sync Complete',
        message: result.message,
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

  Future<void> _handleExport(TallyExportFormat format) async {
    final uri = _service.buildVoucherExportUri(format);
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
      final xml = await _service.previewVoucherXml();
      if (!mounted) return;
      await TallyXmlPreviewDialog.show(context, 'VOUCHERS · TALLY XML', xml);
    } on TallyIntegrationException catch (e) {
      _toastError(e.message);
    } catch (e) {
      _toastError('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- 1. Voucher Management Action Card ---
        TallyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VOUCHER MANAGEMENT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: kTallyNavy,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _result.headline,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: kTallyMuted.withOpacity(0.8),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),

              // Auto-Generate Dropdown — the value always snaps back to the
              // placeholder, since picking a ledger is an action, not a state.
              Container(
                width: 250,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _autoGeneratePlaceholder,
                    icon: const Icon(Icons.unfold_more, size: 16, color: kTallyNavy),
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: kTallyNavy,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: _autoGeneratePlaceholder,
                        child: Text(_autoGeneratePlaceholder),
                      ),
                      ...TallyLedger.values.map(
                        (ledger) => DropdownMenuItem<String>(
                          value: ledger.wire,
                          child: Text(ledger.label),
                        ),
                      ),
                    ],
                    onChanged: _isBusy
                        ? null
                        : (value) {
                            if (value == null || value == _autoGeneratePlaceholder) {
                              return;
                            }
                            _handleAutoGenerate(
                              TallyLedger.values.firstWhere((l) => l.wire == value),
                            );
                          },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons Grid (Responsive Wrap)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildFilledButton(
                    label: 'NEW VOUCHER',
                    icon: Icons.add,
                    color: kTallyNavy,
                    onPressed: _isBusy ? null : _handleNewVoucher,
                  ),
                  _buildFilledButton(
                    label: 'SYNC ALL',
                    icon: Icons.send,
                    color: const Color(0xFFB48A28),
                    onPressed: _isBusy || _result.vouchers.isEmpty ? null : _handleSyncAll,
                  ),
                  _buildFilledButton(
                    label: 'XML',
                    icon: Icons.code,
                    color: kTallyNavy,
                    onPressed: () => _handleExport(TallyExportFormat.xml),
                  ),
                  _buildFilledButton(
                    label: 'EXCEL',
                    icon: Icons.table_view,
                    color: const Color(0xFFB48A28),
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
                ],
              ),
              const SizedBox(height: 12),

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
        ),
        const SizedBox(height: 24),

        // --- 2. Voucher List ---
        _buildVoucherSection(),
      ],
    );
  }

  Widget _buildVoucherSection() {
    if (_isLoading && _result.vouchers.isEmpty) {
      return const TallyLoadingCard(label: 'LOADING VOUCHERS');
    }
    if (_error != null && _result.vouchers.isEmpty) {
      return TallyErrorCard(message: _error!, onRetry: _load);
    }
    if (_result.vouchers.isEmpty) {
      return const TallyEmptyCard(
        message: 'NO VOUCHERS YET — CREATE ONE OR AUTO-GENERATE FROM A LEDGER',
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
                const Text('MANAGED VOUCHERS',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: kTallyNavy,
                        letterSpacing: 1.5)),
                Text(_result.totalDisplay,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: kTallyGold)),
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
                columnSpacing: 28,
                headingRowHeight: 56,
                dataRowMinHeight: 72,
                dataRowMaxHeight: 72,
                headingRowColor: WidgetStateProperty.all(kTallyTint),
                dividerThickness: 1,
                headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: kTallyMuted,
                    fontSize: 9,
                    letterSpacing: 1.5),
                columns: const [
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('VOUCHER NO')),
                  DataColumn(label: Text('TYPE')),
                  DataColumn(label: Text('PARTICULARS')),
                  DataColumn(label: Text('AMOUNT'), numeric: true),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: _result.vouchers.map(_buildVoucherRow).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  DataRow _buildVoucherRow(TallyVoucher voucher) {
    const cellStyle = TextStyle(
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: kTallySlate,
        fontSize: 12);

    return DataRow(
      cells: [
        DataCell(Text(voucher.voucherDate, style: cellStyle)),
        DataCell(Text(voucher.voucherNo,
            style: cellStyle.copyWith(color: kTallyNavy))),
        DataCell(Text(voucher.voucherType, style: cellStyle)),
        DataCell(
          SizedBox(
            width: 220,
            child: Text(
              voucher.partyLedger.isNotEmpty ? voucher.partyLedger : voucher.narration,
              style: cellStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(voucher.amountDisplay,
            style: cellStyle.copyWith(color: kTallyNavy, fontSize: 13))),
        DataCell(_buildStatusPill(voucher.syncStatus)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit',
              onPressed: _isBusy ? null : () => _handleEditVoucher(voucher),
              icon: const Icon(Icons.edit_outlined, size: 18, color: kTallyNavy),
            ),
            // Posting only makes sense while the voucher is still a draft.
            if (voucher.isDraft)
              IconButton(
                tooltip: 'Mark posted',
                onPressed: _isBusy ? null : () => _handlePostVoucher(voucher),
                icon: const Icon(Icons.task_alt, size: 18, color: kTallyGold),
              ),
            IconButton(
              tooltip: 'Delete',
              onPressed: _isBusy ? null : () => _handleDeleteVoucher(voucher),
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.kDanger),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildStatusPill(String status) {
    final isSynced = status == 'synced';
    final isError = status == 'error';
    final Color fg = isError
        ? AppColors.kDanger
        : isSynced
            ? AppColors.kSuccess
            : kTallyGold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fg.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(0.4)),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: fg,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic)),
    );
  }

  ButtonStyle get _outlinedStyle => OutlinedButton.styleFrom(
        foregroundColor: kTallySlate,
        side: const BorderSide(color: AppColors.kBorder),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _buildFilledButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
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
}
