import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/core/utils/csv_file_saver.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:intl/intl.dart';
import 'package:frontend/shared/widgets/stat_card.dart';
import 'package:frontend/models/gst_filing_model.dart';
import 'package:frontend/services/gst_filing_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class GstrFilingScreen extends StatefulWidget {
  const GstrFilingScreen({super.key});

  @override
  State<GstrFilingScreen> createState() => _GstrFilingScreenState();
}

class _GstrFilingScreenState extends State<GstrFilingScreen> {
  static const Color _navyBlue = Color(0xFF223573);
  static const Color _gold = Color(0xFFC59B27);
  static const Color _bgLight = Color(0xFFF7F9FC);

  final GstFilingService _service = GstFilingService.instance;

  bool _isGstr1Active = true;
  bool _loading = true;
  String? _error;
  GstFilingReport _report = GstFilingReport.empty;

  bool _exporting = false;

  String _selectedMonth = 'ALL TIME';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  // --------------------------------------------------------------------------
  // DATA LOADING
  // --------------------------------------------------------------------------
  Future<void> _loadReport({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final month = _selectedMonth == 'ALL TIME' ? null : _selectedMonth;
    final response = await _service.fetchReport(month: month);

    if (!mounted) return;

    if (response.success && response.data != null) {
      setState(() {
        _report = response.data!;
        _loading = false;
        _error = null;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response.message ?? 'Unable to load GST filing report.';
      });
    }
  }

  List<GstOrder> get _filteredOrders => _applySearch(_report.orders);

  List<GstOrder> _applySearch(List<GstOrder> orders) {
    if (_query.trim().isEmpty) return orders;
    final q = _query.trim().toLowerCase();
    return orders.where((o) {
      return o.customerName.toLowerCase().contains(q) ||
          o.invoiceNo.toLowerCase().contains(q) ||
          o.productName.toLowerCase().contains(q);
    }).toList();
  }

  // --------------------------------------------------------------------------
  // CSV EXPORT
  // --------------------------------------------------------------------------
  Future<void> _exportCsv() async {
    if (_exporting || _loading) return;

    if (_filteredOrders.isEmpty) {
      ToastService.show(
        title: 'Nothing to export',
        message: _report.orders.isEmpty
            ? 'There are no GST invoices for this period.'
            : 'No invoices match your search.',
        type: ToastType.info,
      );
      return;
    }

    final periodLabel =
        _selectedMonth == 'ALL TIME' ? 'All Time' : _selectedMonth;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'EXPORT GST CSV',
      message: 'Download the GSTR-1 invoice-wise breakdown for $periodLabel'
          '${_query.trim().isEmpty ? '' : ' (matching "${_query.trim()}")'}'
          ' as a CSV file? The latest figures will be fetched from the server.',
      confirmLabel: 'EXPORT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: _navyBlue,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _exporting = true);
    try {
      // Pull a fresh copy so the file matches what the backend holds right now.
      final month = _selectedMonth == 'ALL TIME' ? null : _selectedMonth;
      final response = await _service.fetchReport(month: month);
      if (!mounted) return;

      if (!response.success || response.data == null) {
        ToastService.show(
          title: 'Export failed',
          message: response.message,
          type: ToastType.error,
        );
        return;
      }

      final report = response.data!;
      setState(() => _report = report);

      final orders = _applySearch(report.orders);
      if (orders.isEmpty) {
        ToastService.show(
          title: 'Nothing to export',
          message: 'The server returned no invoices for this filter.',
          type: ToastType.info,
        );
        return;
      }

      final filename = 'GSTR1_${_selectedMonth == 'ALL TIME' ? 'ALL' : _selectedMonth}'
          '_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      final saved = await saveCsvFile(filename, _buildCsv(orders));
      if (!mounted) return;

      ToastService.show(
        title: saved ? 'CSV exported' : 'Export cancelled',
        message: saved
            ? '${orders.length} invoice(s) saved to $filename.'
            : 'The file was not saved.',
        type: saved ? ToastType.success : ToastType.info,
      );
    } catch (error) {
      if (!mounted) return;
      ToastService.show(
        title: 'Export failed',
        message: 'Could not create the CSV file: $error',
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _buildCsv(List<GstOrder> orders) {
    final dateFmt = DateFormat('yyyy-MM-dd');
    String money(double v) => v.toStringAsFixed(2);

    double taxable = 0, cgst = 0, sgst = 0, gst = 0, total = 0;
    final rows = <List<Object?>>[
      [
        'Invoice No',
        'Date',
        'Customer',
        'Customer ID',
        'Product',
        'Status',
        'Taxable Value',
        'GST Rate (%)',
        'CGST',
        'SGST',
        'Total GST',
        'Invoice Total',
      ],
    ];
    for (final o in orders) {
      taxable += o.taxable;
      cgst += o.cgst;
      sgst += o.sgst;
      gst += o.gst;
      total += o.total;
      rows.add([
        o.invoiceNo,
        o.createdAt != null ? dateFmt.format(o.createdAt!) : '',
        o.customerName,
        o.customerCode ?? '',
        o.productName,
        o.status.toUpperCase(),
        money(o.taxable),
        o.rate % 1 == 0 ? o.rate.toInt() : o.rate,
        money(o.cgst),
        money(o.sgst),
        money(o.gst),
        money(o.total),
      ]);
    }
    rows.add([
      'TOTAL', '', '', '', '', '',
      money(taxable), '', money(cgst), money(sgst), money(gst), money(total),
    ]);

    // BOM so Excel opens the file as UTF-8.
    return Csv(addBom: true).encode(rows);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgLight,
      child: RefreshIndicator(
        color: _navyBlue,
        onRefresh: () => _loadReport(silent: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search users, orders, assets...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
                    prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Process Button
              ElevatedButton.icon(
                onPressed: _loading ? null : () => _loadReport(),
                icon: const Icon(Icons.bolt, color: Color(0xFFFFD700), size: 18),
                label: const Text(
                  'PROCESS MONTHLY YIELD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navyBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 24),

              // 3. Header Controls
              _buildHeaderControlsCard(),
              const SizedBox(height: 24),

              // 4. Custom Tabs (GSTR-1 vs GSTR-3B)
              _buildTabs(),
              const SizedBox(height: 24),

              // 5. Dynamic Content
              _buildBody(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: AppLoader()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.kDanger, size: 32),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: () => _loadReport(), child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_isGstr1Active) {
      return Column(
        children: [
          _buildGstr1StatCards(),
          const SizedBox(height: 24),
          _buildGstr1RateSummaryTable(),
          const SizedBox(height: 24),
          _buildGstr1InvoiceBreakdownTable(),
        ],
      );
    }
    return _buildGstr3bTable();
  }

  // ===========================================================================
  // UI COMPONENTS
  // ===========================================================================

  Widget _buildHeaderControlsCard() {
    final monthOptions = <String>['ALL TIME', ..._report.months];
    final dropdownValue =
        monthOptions.contains(_selectedMonth) ? _selectedMonth : 'ALL TIME';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _navyBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt, color: Color(0xFFFFD700), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GSTR FILING (GSTR-1 & GSTR-3B)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: _navyBlue,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'REAL-TIME TAX MATRIX & RETURN DATA (CGST / SGST) • PERIOD: ${_report.period.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: AppColors.kTextMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: dropdownValue,
                      icon: const Icon(Icons.unfold_more, size: 16),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                      items: monthOptions.map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedMonth = value);
                        _loadReport();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _loading ? null : () => _loadReport(),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh, size: 18, color: AppColors.kTextMuted),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: (_loading || _exporting) ? null : _exportCsv,
                icon: _exporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.insert_drive_file_outlined,
                        color: Colors.white, size: 14),
                label: const Text(
                  'EXPORT CSV',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 10,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navyBlue,
                  disabledBackgroundColor: _navyBlue.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isGstr1Active = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _isGstr1Active ? _gold : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                'GSTR-1 (OUTWARD\nSUPPLIES & B2C INVOICES)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: _isGstr1Active ? _navyBlue : AppColors.kTextMuted,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isGstr1Active = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: !_isGstr1Active ? _gold : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                'GSTR-3B (MONTHLY\nSUMMARY & TAX LIABILITIES)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: !_isGstr1Active ? _navyBlue : AppColors.kTextMuted,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // GSTR-1 VIEWS
  // ===========================================================================

  Widget _buildGstr1StatCards() {
    final summary = _report.summary;

    return Column(
      children: [
        StatCardGrid(
          children: [
            StatCard(
              label: 'TAXABLE VALUE',
              value: summary.taxableDisplay,
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.kPrimary,
              badgeText: summary.ordersDisplay,
              backgroundColor: const Color(0xFFF8FAFC),
              borderColor: const Color(0xFFE2E8F0),
              badgeBackgroundColor: const Color(0xFFEDF2F7),
              badgeTextColor: AppColors.kPrimary,
            ),
            StatCard(
              label: 'CGST COLLECTED',
              value: summary.cgstDisplay,
              icon: Icons.pie_chart_outline,
              color: const Color(0xFF3B82F6),
              badgeText: 'CENTRAL GST',
              backgroundColor: const Color(0xFFF0F7FF),
              borderColor: const Color(0xFFBFDBFE),
              badgeBackgroundColor: const Color(0xFFDBEAFE),
              badgeTextColor: const Color(0xFF1D4ED8),
            ),
            StatCard(
              label: 'SGST COLLECTED',
              value: summary.sgstDisplay,
              icon: Icons.pie_chart_outline,
              color: const Color(0xFF10B981),
              badgeText: 'STATE GST',
              backgroundColor: const Color(0xFFECFDF5),
              borderColor: const Color(0xFFA7F3D0),
              badgeBackgroundColor: const Color(0xFFD1FAE5),
              badgeTextColor: const Color(0xFF047857),
            ),
            StatCard(
              label: 'TOTAL GST',
              value: summary.totalGstDisplay,
              icon: Icons.payments_outlined,
              color: AppColors.goldColor,
              badgeText: 'CGST + SGST',
              backgroundColor: AppColors.goldBg,
              borderColor: AppColors.goldBorder,
              badgeBackgroundColor: AppColors.goldBadgeBg,
              badgeTextColor: AppColors.goldColor,
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatCard(
          label: 'INVOICE TOTAL',
          value: _report.invoiceTotalDisplay,
          icon: Icons.receipt_long,
          color: AppColors.kPrimary,
          badgeText: 'INCL. GST',
          backgroundColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
          badgeBackgroundColor: const Color(0xFFEDF2F7),
          badgeTextColor: AppColors.kPrimary,
        ),
      ],
    );
  }

  Widget _buildGstr1RateSummaryTable() {
    final slabs = _report.rateSlabs;

    return _buildResponsiveTableCard(
      title: 'GSTR-1 RATE-WISE OUTWARD SUPPLIES SUMMARY',
      tableWidth: 800,
      headers: ['GST RATE', 'TAXABLE VALUE', 'CGST', 'SGST', 'TOTAL GST LIABILITY', 'ORDERS'],
      columnWidths: const [150, 130, 110, 110, 150, 80],
      emptyLabel: 'No rate slabs for this period.',
      rows: [
        for (var i = 0; i < slabs.length; i++)
          _buildDataRow([
            _styledText(slabs[i].rateLabel, _navyBlue),
            _styledText(slabs[i].taxableDisplay, _navyBlue),
            _styledText(slabs[i].cgstDisplay, _gold),
            _styledText(slabs[i].sgstDisplay, _gold),
            _styledText(slabs[i].totalGstDisplay, _navyBlue),
            _styledText(slabs[i].ordersDisplay, _navyBlue),
          ], isLast: i == slabs.length - 1),
      ],
    );
  }

  Widget _buildGstr1InvoiceBreakdownTable() {
    final orders = _filteredOrders;

    return _buildResponsiveTableCard(
      title: 'GSTR-1 B2C INVOICE-WISE BREAKDOWN',
      tableWidth: 1000,
      headers: ['INVOICE', 'DATE', 'CUSTOMER', 'PRODUCT', 'TAXABLE', 'GST%', 'CGST', 'SGST', 'TOTAL'],
      columnWidths: const [80, 90, 140, 150, 100, 60, 90, 90, 110],
      emptyLabel: _report.orders.isEmpty
          ? 'No invoices for this period.'
          : 'No invoices match your search.',
      rows: [
        for (var i = 0; i < orders.length; i++)
          _buildDataRow([
            _styledText(orders[i].invoiceNo, _gold),
            _styledText(orders[i].dateDisplay, AppColors.kTextMuted),
            _styledText(orders[i].customerName, _navyBlue),
            _styledText(orders[i].productName, _navyBlue),
            _styledText(orders[i].taxableDisplay, _navyBlue),
            _styledText(orders[i].rateDisplay, _navyBlue),
            _styledText(orders[i].cgstDisplay, _gold),
            _styledText(orders[i].sgstDisplay, _gold),
            _styledText(orders[i].totalDisplay, _navyBlue),
          ], isLast: i == orders.length - 1),
      ],
    );
  }

  // ===========================================================================
  // GSTR-3B VIEW
  // ===========================================================================

  Widget _buildGstr3bTable() {
    final summary = _report.summary;

    return _buildResponsiveTableCard(
      title: 'GSTR-3B BOX 3.1: OUTWARD SUPPLIES & NET TAX LIABILITIES',
      subtitle: 'SUMMARY RETURN TABLE FOR DIRECT FILING ON THE GST PORTAL',
      tableWidth: 900,
      headers: [
        'NATURE OF SUPPLIES (BOX 3.1)',
        'TOTAL TAXABLE VALUE',
        'INTEGRATED TAX (IGST)',
        'CENTRAL TAX (CGST)',
        'STATE/UT TAX (SGST)',
        'TOTAL TAX PAYABLE'
      ],
      columnWidths: const [250, 140, 120, 120, 120, 130],
      emptyLabel: 'No data for this period.',
      rows: [
        _buildDataRow([
          _styledText(
            '3.1(a) Outward Taxable Supplies (Other than Zero Rated, Nil Rated and Exempted)',
            _navyBlue,
          ),
          _styledText(summary.taxableDisplay, _navyBlue),
          _styledText('₹0.00', AppColors.kTextMuted),
          _styledText(summary.cgstDisplay, _gold),
          _styledText(summary.sgstDisplay, _gold),
          _styledText(summary.totalGstDisplay, _navyBlue),
        ]),
        _buildDataRow([
          _styledText('3.1(b) Outward Taxable Supplies (Zero Rated)', AppColors.kTextMuted),
          _styledText('₹0.00', AppColors.kTextMuted),
          _styledText('₹0.00', AppColors.kTextMuted),
          _styledText('₹0.00', AppColors.kTextMuted),
          _styledText('₹0.00', AppColors.kTextMuted),
          _styledText('₹0.00', AppColors.kTextMuted),
        ]),
        _buildDataRow([
          _styledText('TOTAL NET TAX LIABILITY (BOX 3.1)', _navyBlue),
          _styledText(summary.taxableDisplay, _navyBlue),
          _styledText('₹0.00', AppColors.kTextMuted),
          _styledText(summary.cgstDisplay, _gold),
          _styledText(summary.sgstDisplay, _gold),
          _styledText(summary.totalGstDisplay, _navyBlue),
        ], isLast: true),
      ],
    );
  }

  // ===========================================================================
  // REUSABLE TABLE BUILDERS
  // ===========================================================================

  Widget _buildResponsiveTableCard({
    required String title,
    String? subtitle,
    required double tableWidth,
    required List<String> headers,
    required List<double> columnWidths,
    required List<Widget> rows,
    String emptyLabel = 'No data available.',
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 20, bottom: 12, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: _navyBlue,
                    letterSpacing: 1.0,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppColors.kTextMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ]
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Text(
                emptyLabel,
                style: const TextStyle(color: AppColors.kTextMuted, fontSize: 12),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          headers.length,
                          (i) => SizedBox(
                            width: columnWidths[i],
                            child: Text(
                              headers[i],
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: AppColors.kTextMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
                      const SizedBox(height: 12),
                      ...rows,
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataRow(List<Widget> cells, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: cells.map((cell) => Expanded(child: cell)).toList(),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1),
          )
        else
          const SizedBox(height: 16),
      ],
    );
  }

  Widget _styledText(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: color,
        height: 1.3,
      ),
    );
  }
}