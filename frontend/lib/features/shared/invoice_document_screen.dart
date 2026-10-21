import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';

/// Printed tax-invoice document.
///
/// Everything rendered here is the frozen snapshot the backend already returns
/// from `admin/invoices.php` — the document is re-read by id when it opens so
/// it always shows the server's copy, never a stale row from the register.

const Color _kInk = Color(0xFF151D30);
const double _kDocWidth = 860;

/// Seller block. The register endpoint carries no seller record, so the
/// letterhead is a constant (matches the printed stationery).
const String _kSellerName = 'VAMANAN ENTERPRISES V';
const String _kSellerAddress = 'KRISHNAGIRI, TAMIL NADU';

Future<void> showInvoiceDocument(BuildContext context, InvoiceModel invoice) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => InvoiceDocumentDialog(invoice: invoice),
  );
}

// =============================================================================
// Dialog shell — toolbar + live re-fetch around the paper itself.
// =============================================================================
class InvoiceDocumentDialog extends StatefulWidget {
  final InvoiceModel invoice;
  const InvoiceDocumentDialog({super.key, required this.invoice});

  @override
  State<InvoiceDocumentDialog> createState() => _InvoiceDocumentDialogState();
}

class _InvoiceDocumentDialogState extends State<InvoiceDocumentDialog> {
  late InvoiceModel _invoice = widget.invoice;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fresh = await InvoiceService.instance.fetchInvoiceById(
        widget.invoice.id,
        invoiceNo: widget.invoice.invoiceId,
      );
      if (!mounted) return;
      setState(() {
        _invoice = fresh;
        _loading = false;
      });
    } catch (e) {
      // Keep showing the row we already have; just flag that it is not live.
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: AppColors.kSurface,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _kDocWidth + 80,
          maxHeight: size.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToolbar(),
            if (_error != null) _buildStaleBanner(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                child: _HorizontalDocScroll(
                  child: InvoiceDocumentView(invoice: _invoice),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.kBorder)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, size: 18, color: AppColors.kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'INVOICE ${_invoice.invoiceId}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.kPrimary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          if (_loading)
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.kPrimary),
            )
          else
            IconButton(
              onPressed: _refresh,
              tooltip: 'Reload from server',
              icon: const Icon(Icons.refresh,
                  size: 18, color: AppColors.kTextMuted),
            ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
            icon:
                const Icon(Icons.close, size: 18, color: AppColors.kTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildStaleBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppColors.kWarning.withOpacity(0.08),
      child: Text(
        'Showing the register copy — could not reload from the server. $_error',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.kWarning,
        ),
      ),
    );
  }
}

/// Keeps the document at its printed width; narrow screens scroll sideways
/// instead of reflowing the tax tables.
class _HorizontalDocScroll extends StatelessWidget {
  final Widget child;
  const _HorizontalDocScroll({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kDocWidth) return child;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: _kDocWidth, child: child),
        );
      },
    );
  }
}

// =============================================================================
// The paper. Reusable on its own (route, print preview, share sheet …).
// =============================================================================
class InvoiceDocumentView extends StatelessWidget {
  final InvoiceModel invoice;
  const InvoiceDocumentView({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.kSurface,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLetterhead(),
          const SizedBox(height: 18),
          Container(height: 3, color: _kInk),
          const SizedBox(height: 22),
          _buildBillTo(),
          const SizedBox(height: 26),
          _buildItemsTable(),
          const SizedBox(height: 20),
          _buildGstBreakupTable(),
          const SizedBox(height: 24),
          _buildTotals(),
          const SizedBox(height: 26),
          const _DashedDivider(),
          const SizedBox(height: 16),
          _buildNotes(),
          const SizedBox(height: 44),
          _buildSignatures(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Letterhead
  // ---------------------------------------------------------------------------
  Widget _buildLetterhead() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: _kInk,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(text: '${_kSellerName.split(' ').first} '),
                    TextSpan(
                      text: _kSellerName
                          .substring(_kSellerName.indexOf(' ') + 1),
                      style: const TextStyle(color: AppColors.goldColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                _kSellerAddress,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.kTextMuted,
                  letterSpacing: 2.2,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'TAX INVOICE',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: _kInk,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            _metaLine('Invoice No: ', invoice.invoiceId),
            _metaLine('Date: ', invoice.dateFull, boldValue: false),
            _metaLine('Payment: ', invoice.paymentLabel, boldValue: false),
          ],
        ),
      ],
    );
  }

  Widget _metaLine(String label, String value, {bool boldValue = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.kTextMuted,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: label),
            TextSpan(
              text: value,
              style: TextStyle(
                color: boldValue ? _kInk : AppColors.kTextMuted,
                fontWeight: boldValue ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bill to
  // ---------------------------------------------------------------------------
  Widget _buildBillTo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BILL TO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextMuted,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 10),
        _billLine(invoice.customerName, emphasised: true),
        _billLine('Customer ID: ${invoice.customerCode}'),
        _billLine('Phone: ${invoice.phoneLabel}'),
        _billLine('Txn / UTR: ${invoice.transactionLabel}'),
      ],
    );
  }

  Widget _billLine(String text, {bool emphasised = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.35,
          color: emphasised ? _kInk : AppColors.kTextDark,
          fontWeight: emphasised ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Line items
  // ---------------------------------------------------------------------------
  Widget _buildItemsTable() {
    return Table(
      border: TableBorder.all(color: AppColors.kBorder, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(0.6),
        1: FlexColumnWidth(3.4),
        2: FlexColumnWidth(1.0),
        3: FlexColumnWidth(1.7),
        4: FlexColumnWidth(0.9),
        5: FlexColumnWidth(1.9),
      },
      children: [
        _headerRow(const [
          _HeadCell('#', align: TextAlign.center),
          _HeadCell('DESCRIPTION', align: TextAlign.center),
          _HeadCell('QTY', align: TextAlign.center),
          _HeadCell('RATE', align: TextAlign.center),
          _HeadCell('GST', align: TextAlign.center),
          _HeadCell('TAXABLE VALUE', align: TextAlign.center),
        ]),
        TableRow(
          children: [
            _bodyCell('1', align: TextAlign.center),
            _bodyCell(invoice.descriptionLabel),
            _bodyCell(invoice.qtyLabel, align: TextAlign.center),
            _bodyCell(invoice.rate, align: TextAlign.right),
            _bodyCell(invoice.gstRateLabel),
            _bodyCell(invoice.taxableValue, align: TextAlign.right),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CGST / SGST break-up
  // ---------------------------------------------------------------------------
  Widget _buildGstBreakupTable() {
    return Table(
      border: TableBorder.all(color: AppColors.kBorder, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.8),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.6),
        4: FlexColumnWidth(1.2),
        5: FlexColumnWidth(1.6),
      },
      children: [
        _headerRow(const [
          _HeadCell('GST RATE', align: TextAlign.center),
          _HeadCell('TAXABLE', align: TextAlign.center),
          _HeadCell('CGST %', align: TextAlign.center),
          _HeadCell('CGST AMT', align: TextAlign.center),
          _HeadCell('SGST %', align: TextAlign.center),
          _HeadCell('SGST AMT', align: TextAlign.center),
        ]),
        TableRow(
          children: [
            _bodyCell(invoice.gstRateLabel, align: TextAlign.center),
            _bodyCell(invoice.taxableValue, align: TextAlign.right),
            _bodyCell(invoice.cgstRateLabel, align: TextAlign.center),
            _bodyCell(invoice.cgst, align: TextAlign.right),
            _bodyCell(invoice.sgstRateLabel, align: TextAlign.center),
            _bodyCell(invoice.sgst, align: TextAlign.right),
          ],
        ),
      ],
    );
  }

  TableRow _headerRow(List<_HeadCell> cells) {
    return TableRow(
      decoration: const BoxDecoration(color: _kInk),
      children: [
        for (final cell in cells)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            child: Text(
              cell.text,
              textAlign: cell.align,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
      ],
    );
  }

  Widget _bodyCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppColors.kTextDark,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Totals
  // ---------------------------------------------------------------------------
  Widget _buildTotals() {
    return Row(
      children: [
        const Spacer(flex: 5),
        Expanded(
          flex: 6,
          child: Table(
            border: TableBorder.all(color: AppColors.kBorder, width: 1),
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(1.6),
            },
            children: [
              _totalRow('Taxable Amount', invoice.taxableValue),
              _totalRow('CGST', invoice.cgst),
              _totalRow('SGST', invoice.sgst),
              _totalRow('Total Amount', invoice.total, grand: true),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _totalRow(String label, String value, {bool grand = false}) {
    final style = TextStyle(
      fontSize: grand ? 16 : 14.5,
      fontWeight: grand ? FontWeight.w800 : FontWeight.w500,
      color: grand ? _kInk : AppColors.kTextDark,
    );

    return TableRow(
      decoration: grand
          ? const BoxDecoration(color: Color(0xFFFCF4D9))
          : const BoxDecoration(color: AppColors.kSurface),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Text(label, style: style),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Text(value, textAlign: TextAlign.right, style: style),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------
  Widget _buildNotes() {
    const noteStyle = TextStyle(
      fontSize: 11.5,
      height: 1.6,
      fontWeight: FontWeight.w500,
      color: AppColors.kTextMuted,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cashback is calculated only on the taxable product value '
          '(${invoice.taxableValue}); GST (CGST + SGST) is excluded from all '
          'cashback, referral and commission calculations.',
          style: noteStyle,
        ),
        const Text('This is a computer-generated tax invoice.',
            style: noteStyle),
      ],
    );
  }

  Widget _buildSignatures() {
    return Row(
      children: [
        Expanded(child: _signature('CUSTOMER SIGNATURE')),
        const Spacer(flex: 1),
        Expanded(child: _signature('FOR $_kSellerName')),
      ],
    );
  }

  Widget _signature(String label) {
    return Column(
      children: [
        Container(height: 1.5, color: _kInk),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.kTextMuted,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

class _HeadCell {
  final String text;
  final TextAlign align;
  const _HeadCell(this.text, {this.align = TextAlign.left});
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter: _DashedLinePainter(),
        size: const Size(double.infinity, 1),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.kBorder
      ..strokeWidth = 1.2;

    const dash = 7.0;
    const gap = 6.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
