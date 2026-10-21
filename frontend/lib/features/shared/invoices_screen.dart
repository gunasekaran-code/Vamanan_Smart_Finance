import 'dart:async';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import 'invoice_document_screen.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/core/utils/csv_file_saver.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/stat_card.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Show the complete invoice register by default. Individual states can then
  // narrow it down from the status menu.
  String _filter = 'ALL';
  bool _loading = true;
  bool _exporting = false;
  String? _error;
  List<InvoiceModel> _invoices = [];
  InvoiceSummary _summary = const InvoiceSummary(
      count: 0, taxable: 0, cgst: 0, sgst: 0, grandTotal: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await InvoiceService.instance.fetchInvoices(
        status: _filter == 'ALL' ? 'all' : _filter.toLowerCase(),
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _invoices = result.invoices;
        _summary = result.summary;
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

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _exportCsv() async {
    if (_exporting || _loading) return;

    if (_invoices.isEmpty) {
      ToastService.show(
        title: 'Nothing to export',
        message: 'There are no invoices in the current view.',
        type: ToastType.info,
      );
      return;
    }

    final search = _searchController.text.trim();
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'EXPORT INVOICES',
      message: 'Download the ${_filter == 'ALL' ? 'full' : 'active'} invoice '
          'register${search.isEmpty ? '' : ' matching "$search"'} as a CSV '
          'file? The latest invoices will be fetched from the server.',
      confirmLabel: 'EXPORT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kPrimary,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _exporting = true);
    try {
      // Pull a fresh copy so the file matches what the backend holds right now.
      final result = await InvoiceService.instance.fetchInvoices(
        status: _filter == 'ALL' ? 'all' : _filter.toLowerCase(),
        search: search,
      );
      if (!mounted) return;
      setState(() {
        _invoices = result.invoices;
        _summary = result.summary;
      });

      if (result.invoices.isEmpty) {
        ToastService.show(
          title: 'Nothing to export',
          message: 'The server returned no invoices for this filter.',
          type: ToastType.info,
        );
        return;
      }

      final filename = 'Invoices_${_filter}_'
          '${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      final saved = await saveCsvFile(filename, _buildCsv(result.invoices));
      if (!mounted) return;

      ToastService.show(
        title: saved ? 'CSV exported' : 'Export cancelled',
        message: saved
            ? '${result.invoices.length} invoice(s) saved to $filename.'
            : 'The file was not saved.',
        type: saved ? ToastType.success : ToastType.info,
      );
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
        title: 'Export failed',
        message: e is InvoiceServiceException
            ? e.message
            : 'Could not export invoices: $e',
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _buildCsv(List<InvoiceModel> invoices) {
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    String money(double v) => v.toStringAsFixed(2);

    double taxable = 0, cgst = 0, sgst = 0, gst = 0, total = 0;
    final rows = <List<Object?>>[
      [
        'Invoice No',
        'Date',
        'Customer',
        'Customer ID',
        'Phone',
        'Email',
        'Product',
        'Asset Type',
        'Weight (g)',
        'Taxable Value',
        'GST Rate (%)',
        'CGST',
        'SGST',
        'Total GST',
        'Invoice Total',
        'Payment Method',
        'Transaction ID',
        'Status',
      ],
    ];
    for (final i in invoices) {
      taxable += i.taxableAmount;
      cgst += i.cgstAmount;
      sgst += i.sgstAmount;
      gst += i.gstTotal;
      total += i.totalAmount;
      rows.add([
        i.invoiceId,
        dateFmt.format(i.issuedAt),
        i.customerName,
        i.customerCode,
        i.customerPhone,
        i.customerEmail,
        i.productName,
        i.assetType.toUpperCase(),
        i.weight,
        money(i.taxableAmount),
        i.gstRate % 1 == 0 ? i.gstRate.toInt() : i.gstRate,
        money(i.cgstAmount),
        money(i.sgstAmount),
        money(i.gstTotal),
        money(i.totalAmount),
        i.paymentMethod,
        i.transactionId,
        i.status,
      ]);
    }
    rows.add([
      'TOTAL',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      money(taxable),
      '',
      money(cgst),
      money(sgst),
      money(gst),
      money(total),
      '',
      '',
      '',
    ]);

    // BOM so Excel opens the file as UTF-8.
    return Csv(addBom: true).encode(rows);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.kBackground,
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopSearchBar(),
              const SizedBox(height: 16),
              _buildProcessYieldButton(),
              const SizedBox(height: 24),
              _buildHeaderControlsCard(context),
              const SizedBox(height: 24),
              _buildResponsiveStatCards(context),
              const SizedBox(height: 24),
              if (_error != null)
                _buildErrorBanner()
              else
                _buildInvoiceRegisterTable(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        children: [
          Text(_error!,
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. SEARCH BAR (top-level, mirrors mini search)
  // ===========================================================================
  Widget _buildTopSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: const InputDecoration(
          hintText: 'Search users, orders, assets...',
          hintStyle: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
          prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildProcessYieldButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.bolt, color: AppColors.goldColor, size: 20),
      label: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'PROCESS MONTHLY YIELD',
          style: TextStyle(
            color: AppColors.kSurface,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.5,
            fontSize: 13,
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.kPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  // ===========================================================================
  // 2. HEADER CONTROLS CARD
  // ===========================================================================
  Widget _buildHeaderControlsCard(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimary.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.kPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long,
                    color: AppColors.goldColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INVOICES',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.kPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'EVERY TAX INVOICE ISSUED · REAL-TIME · ${_summary.count} TOTAL',
                      style: const TextStyle(
                        fontSize: 9,
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
              Expanded(flex: isMobile ? 1 : 3, child: _buildMiniSearchBar()),
              const SizedBox(width: 8),
              if (!isMobile) ...[
                Expanded(flex: 2, child: _buildFilterDropdown()),
                const SizedBox(width: 8),
              ],
              _buildRefreshButton(),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 12),
            _buildFilterDropdown(),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: (_loading || _exporting) ? null : _exportCsv,
            icon: _exporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.kSurface),
                  )
                : const Icon(Icons.insert_drive_file_outlined,
                    color: AppColors.kSurface, size: 14),
            label: const Text(
              'EXPORT CSV',
              style: TextStyle(
                color: AppColors.kSurface,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: 10,
                letterSpacing: 1.0,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kPrimary,
              disabledBackgroundColor: AppColors.kPrimary.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.kBorder),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 16, color: AppColors.kTextMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'SEARCH INV / NAM',
                hintStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: AppColors.kTextMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.kBorder),
        borderRadius: BorderRadius.circular(22),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _filter,
          icon: const Icon(Icons.unfold_more,
              size: 16, color: AppColors.kTextMuted),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: AppColors.kPrimary,
          ),
          items: const [
            DropdownMenuItem(value: 'ALL', child: Text('ALL STATUS')),
            DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
            DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')),
            DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
            DropdownMenuItem(value: 'REJECTED', child: Text('REJECTED')),
            DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _filter = v);
            _load();
          },
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return InkWell(
      onTap: _load,
      customBorder: const CircleBorder(),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.kBorder),
            shape: BoxShape.circle),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.kPrimary),
              )
            : const Icon(Icons.refresh, size: 18, color: AppColors.kTextMuted),
      ),
    );
  }

  // ===========================================================================
  // 3. STAT CARDS
  // ===========================================================================
  Widget _buildResponsiveStatCards(BuildContext context) {
    return Column(
      children: [
        StatCardGrid(
          children: [
            StatCard(
              label: 'INVOICES ISSUED',
              value: '${_summary.count}',
              icon: Icons.receipt_long_outlined,
              color: AppColors.kPrimary,
              badgeText: 'TOTAL COUNT',
            ),
            StatCard(
              label: 'TAXABLE VALUE',
              value: _summary.taxableDisplay,
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.kPrimary,
              badgeText: 'EX-GST',
            ),
            StatCard(
              label: 'CGST',
              value: _summary.cgstDisplay,
              icon: Icons.pie_chart_outline_rounded,
              color: AppColors.kPrimary,
              badgeText: 'CENTRAL GST',
            ),
            StatCard(
              label: 'SGST',
              value: _summary.sgstDisplay,
              icon: Icons.pie_chart_outline_rounded,
              color: AppColors.kPrimary,
              badgeText: 'STATE GST',
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatCard(
          label: 'GRAND TOTAL',
          value: _summary.grandTotalDisplay,
          icon: Icons.payments_outlined,
          color: AppColors.goldColor,
          badgeText: 'INCL. GST',
          backgroundColor: AppColors.kPrimary,
          borderColor: AppColors.kPrimary,
          badgeBackgroundColor: AppColors.kPrimaryAccent,
          badgeTextColor: AppColors.goldColor,
          valueColor: AppColors.goldColor,
          labelColor: Colors.white70,
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. INVOICE TABLE (Responsive & Stylish)
  // ===========================================================================
  Widget _buildInvoiceRegisterTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimary.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              'INVOICE REGISTER',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.kPrimary,
                letterSpacing: 1.0,
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: AppLoader()),
            )
          else if (_invoices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                  child: Text('No invoices found.',
                      style: TextStyle(color: AppColors.kTextMuted))),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // If screen is smaller than 950px, show mobile cards instead of a wide table
                if (constraints.maxWidth < 950) {
                  return _buildMobileInvoiceList();
                } else {
                  return _buildDesktopTable();
                }
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP TABLE VIEW
  // ---------------------------------------------------------------------------
  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1470),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  SizedBox(width: 110, child: _TableHeader('INVOICE')),
                  SizedBox(width: 100, child: _TableHeader('DATE')),
                  SizedBox(width: 180, child: _TableHeader('CUSTOMER')),
                  SizedBox(width: 180, child: _TableHeader('PRODUCT')),
                  SizedBox(width: 120, child: _TableHeader('TAXABLE')),
                  SizedBox(width: 60, child: _TableHeader('GST%')),
                  SizedBox(width: 100, child: _TableHeader('CGST')),
                  SizedBox(width: 100, child: _TableHeader('SGST')),
                  SizedBox(width: 160, child: _TableHeader('TOTAL')),
                  SizedBox(width: 110, child: _TableHeader('STATUS')),
                  SizedBox(width: 120, child: _TableHeader('INVOICE')),
                  SizedBox(width: 16),
                  SizedBox(width: 120, child: _TableHeader('ACTION')),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.kBorder, height: 1, thickness: 1),
              const SizedBox(height: 16),
              ..._invoices.map((invoice) {
                return Column(
                  children: [
                    _buildTableRow(invoice),
                    const Divider(
                        color: Color(0xFFF8FAFC), height: 32, thickness: 1.5),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(InvoiceModel invoice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            invoice.invoiceId.replaceFirst('-', '-\n'),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.goldColor,
                height: 1.3),
          ),
        ),
        SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(invoice.dateDay,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppColors.kTextMuted)),
              Text(invoice.dateMonthYear,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      color: AppColors.kTextMuted)),
            ],
          ),
        ),
        SizedBox(
          width: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(invoice.customerName,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppColors.kPrimary)),
              const SizedBox(height: 2),
              Text(invoice.customerCode,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      color: AppColors.kTextMuted)),
            ],
          ),
        ),
        SizedBox(
          width: 180,
          child: Text(invoice.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: AppColors.kPrimary)),
        ),
        SizedBox(
          width: 120,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(invoice.taxableValue,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kPrimary)),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(invoice.gstRateLabel,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: AppColors.kPrimary)),
        ),
        SizedBox(
          width: 100,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(invoice.cgst,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.goldColor)),
          ),
        ),
        SizedBox(
          width: 100,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(invoice.sgst,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.goldColor)),
          ),
        ),
        SizedBox(
          width: 160,
          child: _buildStyledTotal(invoice.total),
        ),
        SizedBox(
          width: 110,
          child: _buildStyledStatusPill(invoice.status),
        ),
        SizedBox(width: 120, child: _buildViewButton(invoice)),
        const SizedBox(width: 16),
        SizedBox(width: 120, child: _buildDeleteButton(invoice)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE CARD VIEW (Responsive layout for phones)
  // ---------------------------------------------------------------------------
  Widget _buildMobileInvoiceList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _invoices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final invoice = _invoices[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.kBorder),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(invoice.invoiceId,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.goldColor,
                          fontSize: 13)),
                  Text('${invoice.dateDay} ${invoice.dateMonthYear}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          color: AppColors.kTextMuted,
                          fontSize: 11)),
                ],
              ),
              const SizedBox(height: 16),

              // Customer & Product
              Text(invoice.customerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppColors.kPrimary,
                      fontSize: 16)),
              const SizedBox(height: 4),
              Text(invoice.productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: AppColors.kTextMuted,
                      fontSize: 13)),

              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: AppColors.kBorder, height: 1)),

              // Financial Breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat('TAXABLE', invoice.taxableValue),
                  _buildMiniStat('CGST', invoice.cgst),
                  _buildMiniStat('SGST', invoice.sgst),
                ],
              ),

              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: AppColors.kBorder, height: 1)),

              // Footer: Styled Total, Status, Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _buildStyledTotal(invoice.total)),
                  _buildStyledStatusPill(invoice.status),
                ],
              ),
              const SizedBox(height: 16),
              _buildInvoiceActions(invoice, expand: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.kTextMuted,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.kPrimary)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STYLED WIDGETS (Matched perfectly to image_a3b620.png)
  // ---------------------------------------------------------------------------

  Widget _buildStyledTotal(String totalAmount) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        totalAmount,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: Color(0xFF233261), // Dark navy blue matching the screenshot
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildStyledStatusPill(String status) {
    // Determine colors based on status (assuming "ACTIVE" is success/green)
    final bool isActive = status.toUpperCase() == 'ACTIVE';
    final Color bgColor =
        isActive ? const Color(0xFFE8F5E9) : AppColors.kBorder;
    final Color textColor =
        isActive ? const Color(0xFF2E7D32) : AppColors.kTextMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20), // Highly rounded pill
      ),
      child: Text(
        status.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInvoiceActions(InvoiceModel invoice, {bool expand = false}) {
    final viewButton = _buildViewButton(invoice);
    final deleteButton = _buildDeleteButton(invoice);

    if (expand) {
      return Row(
        children: [
          Expanded(child: viewButton),
          const SizedBox(width: 12),
          Expanded(child: deleteButton),
        ],
      );
    }

    return Row(
      children: [
        viewButton,
        const SizedBox(width: 10),
        deleteButton,
      ],
    );
  }

  Widget _buildViewButton(InvoiceModel invoice) {
    return ElevatedButton.icon(
      onPressed: () => showInvoiceDocument(context, invoice),
      icon: const Icon(Icons.print_outlined, size: 14, color: Colors.white),
      label: const Text('VIEW',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.0)),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            const Color(0xFF233261), // Dark navy blue matching the screenshot
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)), // Highly rounded pill
        elevation: 0,
      ),
    );
  }

  Widget _buildDeleteButton(InvoiceModel invoice) {
    return OutlinedButton.icon(
      onPressed: () => _showDeleteUnavailable(invoice),
      icon: const Icon(Icons.delete_outline, size: 16),
      label: const Text(
        'DELETE',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.kDanger,
        side: BorderSide(color: AppColors.kDanger.withValues(alpha: 0.24)),
        backgroundColor: AppColors.kDanger.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Future<void> _showDeleteUnavailable(InvoiceModel invoice) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'DELETE INVOICE',
      message: 'Delete invoice ${invoice.invoiceId}? This action is not '
          'available until the server provides an invoice-delete endpoint.',
      confirmLabel: 'UNDERSTOOD',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kDanger,
    );
    if (confirmed == true && mounted) {
      ToastService.show(
        title: 'Invoice not deleted',
        message: 'The current backend exposes invoice records as read-only.',
        type: ToastType.info,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// TABLE HEADER HELPER
// ---------------------------------------------------------------------------
class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: AppColors.kTextMuted,
        letterSpacing:
            1.0, // Added letter spacing to match the header style in the screenshot
      ),
    );
  }
}
