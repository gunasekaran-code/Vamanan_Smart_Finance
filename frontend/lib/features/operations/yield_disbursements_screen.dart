import 'dart:async';

import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/csv_file_saver.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/stat_card.dart';

import '../../../models/wallet_account_model.dart' show formatInr;
import '../../../models/yield_disbursement_model.dart';
import '../../../services/yield_disbursement_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class YieldDisbursementsScreen extends StatefulWidget {
  const YieldDisbursementsScreen({super.key});

  @override
  State<YieldDisbursementsScreen> createState() =>
      _YieldDisbursementsScreenState();
}

class _YieldDisbursementsScreenState extends State<YieldDisbursementsScreen> {
  final YieldService _service = YieldService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  YieldSummary _summary = const YieldSummary();
  List<YieldDisbursement> _allRows = [];
  List<YieldDisbursement> _visibleRows = [];
  int _planMonths = 10;
  bool _isLoading = true;
  bool _exporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dashboard = await _service.fetchDashboard();
      if (!mounted) return;
      setState(() {
        _applyDashboard(dashboard);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyDashboard(YieldDashboardData dashboard) {
    _summary = dashboard.summary;
    _allRows = dashboard.disbursements;
    _planMonths = dashboard.planMonths;
    _visibleRows = _applyFilter(_allRows, _searchController.text);
  }

  // --------------------------------------------------------------------------
  // EXPORT
  // --------------------------------------------------------------------------

  /// Re-fetches the ledger so the file reflects the backend right now, then
  /// writes the rows matching the current search to an .xlsx and downloads it
  /// (browser download on web, share sheet on mobile).
  Future<void> _exportExcel() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final dashboard = await _service.fetchDashboard();
      if (!mounted) return;
      setState(() => _applyDashboard(dashboard));

      final rows = _visibleRows;
      if (rows.isEmpty) {
        ToastService.show(
            title: 'Nothing to Export',
            message: 'No disbursements match the current search.',
            type: ToastType.info);
        return;
      }

      final bytes = _buildWorkbook(rows);
      final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final saved = await saveBinaryFile(
        'yield_disbursements_$stamp.xlsx',
        bytes,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (!mounted || !saved) return;
      ToastService.show(
          title: 'Export Ready',
          message: '${rows.length} disbursement${rows.length == 1 ? '' : 's'} exported to Excel.',
          type: ToastType.success);
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
          title: 'Export Failed', message: e.toString(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  List<int> _buildWorkbook(List<YieldDisbursement> rows) {
    const sheetName = 'Yield Disbursements';
    final book = xl.Excel.createExcel();
    book.rename(book.getDefaultSheet() ?? 'Sheet1', sheetName);
    final sheet = book[sheetName];

    const headers = [
      'S.NO', 'DATE', 'TIME', 'CUSTOMER', 'EMAIL', 'CATEGORY', 'MONTH',
      'GROSS (₹)', 'TDS (₹)', 'CHARGES (₹)', 'NET CREDITED (₹)',
      'SETTLEMENT TARGET', 'BANK', 'ACCOUNT NO', 'IFSC', 'STATUS',
      'DESCRIPTION',
    ];
    const moneyColumns = {7, 8, 9, 10};

    xl.TextCellValue text(String? v) => xl.TextCellValue(v ?? '');
    final date = DateFormat('dd MMM yyyy');
    final time = DateFormat('hh:mm a');

    sheet.appendRow([for (final h in headers) xl.TextCellValue(h)]);
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final at = r.createdAt;
      sheet.appendRow([
        xl.IntCellValue(i + 1),
        text(at == null ? '' : date.format(at)),
        text(at == null ? '' : time.format(at)),
        text(r.customerName),
        text(r.customerEmail),
        text(r.categoryLabel),
        text(_monthLabel(r)),
        xl.DoubleCellValue(r.grossAmount),
        xl.DoubleCellValue(r.tdsAmount),
        xl.DoubleCellValue(r.chargesAmount),
        xl.DoubleCellValue(r.netAmount),
        text('WALLET SETTLEMENT'),
        text(r.bankName),
        text(r.bankAccountNumber),
        text(r.bankIfsc),
        text(_statusLabel(r)),
        text(r.description),
      ]);
    }

    double sum(double Function(YieldDisbursement) f) =>
        rows.fold(0, (a, r) => a + f(r));
    sheet.appendRow([
      null, null, null, xl.TextCellValue('TOTAL'), null, null, null,
      xl.DoubleCellValue(sum((r) => r.grossAmount)),
      xl.DoubleCellValue(sum((r) => r.tdsAmount)),
      xl.DoubleCellValue(sum((r) => r.chargesAmount)),
      xl.DoubleCellValue(sum((r) => r.netAmount)),
    ]);

    // Styling: navy header, ₹ number format, bold totals.
    final headerStyle = xl.CellStyle(
      bold: true,
      fontColorHex: xl.ExcelColor.white,
      backgroundColorHex: xl.ExcelColor.fromHexString('FF1E3A8A'),
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
    );
    final moneyStyle = xl.CellStyle(numberFormat: xl.NumFormat.standard_4);
    final totalStyle = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('FFFEF3C7'),
      numberFormat: xl.NumFormat.standard_4,
    );
    final lastRow = rows.length + 1;
    for (var c = 0; c < headers.length; c++) {
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .cellStyle = headerStyle;
      if (moneyColumns.contains(c)) {
        for (var r = 1; r < lastRow; r++) {
          sheet
              .cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
              .cellStyle = moneyStyle;
        }
      }
      if (c == 3 || moneyColumns.contains(c)) {
        sheet
            .cell(xl.CellIndex.indexByColumnRow(
                columnIndex: c, rowIndex: lastRow))
            .cellStyle = totalStyle;
      }
    }

    const widths = [
      7.0, 14.0, 10.0, 24.0, 30.0, 12.0, 16.0, 14.0, 12.0, 12.0, 18.0,
      20.0, 20.0, 20.0, 14.0, 18.0, 70.0,
    ];
    for (var c = 0; c < widths.length; c++) {
      sheet.setColumnWidth(c, widths[c]);
    }

    return book.encode() ?? (throw Exception('Could not build the Excel file.'));
  }

  // --------------------------------------------------------------------------
  // LABELS
  // --------------------------------------------------------------------------

  /// "MONTH 3 OF 10" — from the payout's own description when it says, else
  /// from its cycle's months-paid counter. Referral rows have no month.
  String _monthLabel(YieldDisbursement row) {
    final m = row.descriptionMonth;
    if (m != null) return 'MONTH ${m.$1} OF ${m.$2}';
    if (row.isReferral) return 'REFERRAL COMMISSION';
    return 'MONTH ${row.cycleMonthsPaid ?? 0} OF $_planMonths';
  }

  String _statusLabel(YieldDisbursement row) {
    if (row.isFailed) return 'FAILED';
    if (row.isPending) return 'PENDING';
    return 'WALLET CREDITED';
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _visibleRows = _applyFilter(_allRows, _searchController.text);
      });
    });
  }

  List<YieldDisbursement> _applyFilter(
      List<YieldDisbursement> rows, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((r) {
      return r.customerName.toLowerCase().contains(q) ||
          (r.customerEmail ?? '').toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q);
    }).toList();
  }

  void _showDetails(YieldDisbursement row) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.customerName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF1E3A8A))),
            const SizedBox(height: 4),
            Text(row.categoryLabel,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1)),
            const SizedBox(height: 16),
            _detailLine('GROSS', formatInr(row.grossAmount)),
            _detailLine('TDS', formatInr(row.tdsAmount)),
            _detailLine('CHARGES', formatInr(row.chargesAmount)),
            const Divider(height: 24),
            _detailLine('NET CREDITED', formatInr(row.netAmount), emphasize: true),
            const SizedBox(height: 16),
            _detailLine('MONTH', _monthLabel(row)),
            _detailLine('SETTLEMENT TARGET', row.settlementTargetLabel),
            _detailLine('STATUS', _statusLabel(row)),
            if (row.description != null) ...[
              const SizedBox(height: 16),
              Text(row.description!,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailLine(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5)),
          Text(value,
              style: TextStyle(
                  fontSize: emphasize ? 16 : 13,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF1E3A8A))),
        ],
      ),
    );
  }

  Color _statusColor(YieldDisbursement row) {
    if (row.isFailed) return const Color(0xFFDC2626);
    if (row.isPending) return const Color(0xFFD97706);
    return const Color(0xFF2F7D57);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          color: const Color(0xFF1E3A8A),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Header Section ---
                const Text(
                  'YIELD DISBURSEMENTS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF1E3A8A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'TRACK AND PROCESS THE MONTHLY CASHBACK PLAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF94A3B8).withOpacity(0.9),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // --- Search and Export Action Row ---
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 450) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearchBar(),
                          const SizedBox(height: 12),
                          _buildExportButton(),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: _buildSearchBar()),
                        const SizedBox(width: 16),
                        _buildExportButton(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                StatCardGrid(
                  children: [
                    StatCard(
                      label: 'YIELD DISPATCHED TODAY',
                      value: formatInr(_summary.dispatchedToday),
                      icon: Icons.bolt,
                      color: const Color(0xFFD97706),
                      badgeText: 'TODAY',
                      backgroundColor: AppColors.goldBg,
                      borderColor: AppColors.goldBorder,
                      badgeBackgroundColor: AppColors.goldBadgeBg,
                      badgeTextColor: AppColors.goldColor,
                    ),
                    StatCard(
                      label: 'CURRENT MONTH TOTAL',
                      value: formatInr(_summary.currentMonthTotal),
                      icon: Icons.attach_money,
                      color: const Color(0xFFD97706),
                      badgeText: 'MONTHLY',
                      backgroundColor: AppColors.goldBg,
                      borderColor: AppColors.goldBorder,
                      badgeBackgroundColor: AppColors.goldBadgeBg,
                      badgeTextColor: AppColors.goldColor,
                    ),
                    StatCard(
                      label: 'ACTIVE YIELD CYCLES',
                      value: '${_summary.activeCycles}',
                      icon: Icons.sync,
                      color: const Color(0xFF3B82F6),
                      badgeText: 'ACTIVE',
                      backgroundColor: const Color(0xFFF0F7FF),
                      borderColor: const Color(0xFFBFDBFE),
                      badgeBackgroundColor: const Color(0xFFDBEAFE),
                      badgeTextColor: const Color(0xFF1D4ED8),
                    ),
                    StatCard(
                      label: 'TOTAL CUMULATIVE YIELD',
                      value: formatInr(_summary.cumulativeTotal),
                      icon: Icons.call_made,
                      color: const Color(0xFF3B82F6),
                      badgeText: 'TOTAL',
                      backgroundColor: const Color(0xFFF0F7FF),
                      borderColor: const Color(0xFFBFDBFE),
                      badgeBackgroundColor: const Color(0xFFDBEAFE),
                      badgeTextColor: const Color(0xFF1D4ED8),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // --- Data Table / loading / error / empty ---
                _buildTableArea(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableArea() {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.kBorder),
        ),
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: const Center(child: AppLoader()),
      );
    }

    if (_error != null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.kBorder),
        ),
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _loadDashboard, child: const Text('RETRY')),
          ],
        ),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 48,
              ),
              child: DataTable(
                columnSpacing: 48,
                headingRowHeight: 56,
                dataRowMinHeight: 96,
                dataRowMaxHeight: 104,
                dividerThickness: 1,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
                columns: const [
                  DataColumn(label: Text('CUSTOMER')),
                  DataColumn(label: Text('YIELD DETAILS')),
                  DataColumn(label: Text('SETTLEMENT TARGET (BANK)')),
                  DataColumn(label: Text('DISPATCH STATUS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: _visibleRows.map((row) => _buildRow(row)).toList(),
              ),
            ),
          ),
          if (_visibleRows.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search,
                      size: 48, color: const Color(0xFFCBD5E1).withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.trim().isNotEmpty
                        ? 'NO DISBURSEMENTS MATCH YOUR SEARCH'
                        : 'NO DISBURSEMENTS FOUND IN HISTORICAL LEDGER',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFCBD5E1),
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

  DataRow _buildRow(YieldDisbursement row) {
    const navy = Color(0xFF1E3A8A);
    const muted = Color(0xFF94A3B8);
    final statusColor = _statusColor(row);
    final at = row.createdAt;
    final dateLabel =
        at == null ? '' : ' · ${DateFormat('dd MMM yyyy').format(at).toUpperCase()}';

    return DataRow(cells: [
      // CUSTOMER — initial tile, name, email
      DataCell(SizedBox(
        width: 230,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                row.customerName.trim().isEmpty
                    ? '?'
                    : row.customerName.trim()[0].toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(row.customerName.toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: navy,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  if ((row.customerEmail ?? '').isNotEmpty)
                    Text(row.customerEmail!,
                        style: const TextStyle(color: muted, fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      )),
      // YIELD DETAILS — net amount, month · date, description
      DataCell(SizedBox(
        width: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_inr(row.netAmount),
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFB8901F),
                    fontSize: 14)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 11, color: muted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text('${_monthLabel(row)}$dateLabel',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: muted,
                          letterSpacing: 0.2)),
                ),
              ],
            ),
            if ((row.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(row.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 12)),
            ],
          ],
        ),
      )),
      // SETTLEMENT TARGET — every payout is credited to the in-app wallet
      DataCell(Tooltip(
        message: row.settlementTargetLabel,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 12, color: muted),
            SizedBox(width: 6),
            Text('WALLET SETTLEMENT',
                style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.2)),
          ],
        ),
      )),
      // DISPATCH STATUS
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                row.isFailed
                    ? Icons.error_outline
                    : row.isPending
                        ? Icons.hourglass_empty
                        : Icons.check_circle_outline,
                size: 12,
                color: statusColor),
            const SizedBox(width: 6),
            Text(_statusLabel(row),
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.2)),
          ],
        ),
      )),
      // ACTIONS
      DataCell(Tooltip(
        message: 'View details',
        child: InkWell(
          onTap: () => _showDetails(row),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.kBorder, width: 1.4),
            ),
            child: const Icon(Icons.history, size: 16, color: muted),
          ),
        ),
      )),
    ]);
  }

  /// ₹ with Indian digit grouping; paise only when there are any.
  static String _inr(double value) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: (value * 100).round() % 100 == 0 ? 0 : 2,
      ).format(value);

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'SEARCH INVESTOR IDENTITIES...',
          hintStyle: const TextStyle(
            color: AppColors.kTextMuted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.kTextMuted, size: 20),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: AppColors.kTextMuted),
                  onPressed: () => _searchController.clear(),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return OutlinedButton.icon(
      onPressed: _exporting || _isLoading ? null : _exportExcel,
      icon: _exporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF1E3A8A)),
            )
          : const Icon(Icons.download_outlined, size: 18),
      label: Text(
        _exporting ? 'EXPORTING...' : 'EXPORT EXCEL',
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          fontSize: 11,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1E3A8A),
        side: const BorderSide(color: AppColors.kBorder),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
    );
  }
}
