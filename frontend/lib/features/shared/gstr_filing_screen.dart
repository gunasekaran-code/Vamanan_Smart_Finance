import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/stat_card.dart'; // From your previous import

class GstrFilingScreen extends StatefulWidget {
  const GstrFilingScreen({super.key});

  @override
  State<GstrFilingScreen> createState() => _GstrFilingScreenState();
}

class _GstrFilingScreenState extends State<GstrFilingScreen> {
  static const Color _navyBlue = Color(0xFF223573);
  static const Color _gold = Color(0xFFC59B27);
  static const Color _bgLight = Color(0xFFF7F9FC);
  
  // State to manage which tab is currently active
  bool _isGstr1Active = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgLight,
      child: SingleChildScrollView(
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
              child: const TextField(
                decoration: InputDecoration(
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
              onPressed: () {},
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

            // 5. Dynamic Content based on Tab Selection
            if (_isGstr1Active) ...[
              _buildGstr1StatCards(),
              const SizedBox(height: 24),
              _buildGstr1RateSummaryTable(),
              const SizedBox(height: 24),
              _buildGstr1InvoiceBreakdownTable(),
            ] else ...[
              _buildGstr3bTable(),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // UI COMPONENTS
  // ===========================================================================

  Widget _buildHeaderControlsCard() {
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
                  children: const [
                    Text(
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
                      'REAL-TIME TAX MATRIX & RETURN DATA (CGST / SGST) • PERIOD: ALL TIME',
                      style: TextStyle(
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
                      value: 'ALL TIME',
                      icon: const Icon(Icons.unfold_more, size: 16),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                      items: ['ALL TIME', 'THIS MONTH'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh, size: 18, color: AppColors.kTextMuted),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.insert_drive_file_outlined, color: Colors.white, size: 14),
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
    // Responsive breakpoints for narrow screens
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 380;

    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: isSmallMobile ? 8.0 : 12.0,
          crossAxisSpacing: isSmallMobile ? 8.0 : 12.0,
          childAspectRatio: isSmallMobile ? 0.82 : 1.15,
          children: const [
            StatCard(
              label: 'TAXABLE VALUE',
              value: '₹1,88,06,774.50',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.kPrimary,
              badgeText: '42 ORDERS',
              backgroundColor: Color(0xFFF8FAFC),
              borderColor: Color(0xFFE2E8F0),
              badgeBackgroundColor: Color(0xFFEDF2F7),
              badgeTextColor: AppColors.kPrimary,
            ),
            StatCard(
              label: 'CGST COLLECTED',
              value: '₹3,05,851.64',
              icon: Icons.pie_chart_outline,
              color: Color(0xFF3B82F6),
              badgeText: 'CENTRAL GST',
              backgroundColor: Color(0xFFF0F7FF),
              borderColor: Color(0xFFBFDBFE),
              badgeBackgroundColor: Color(0xFFDBEAFE),
              badgeTextColor: Color(0xFF1D4ED8),
            ),
            StatCard(
              label: 'SGST COLLECTED',
              value: '₹3,05,851.61',
              icon: Icons.pie_chart_outline,
              color: Color(0xFF10B981),
              badgeText: 'STATE GST',
              backgroundColor: Color(0xFFECFDF5),
              borderColor: Color(0xFFA7F3D0),
              badgeBackgroundColor: Color(0xFFD1FAE5),
              badgeTextColor: Color(0xFF047857),
            ),
            StatCard(
              label: 'TOTAL GST',
              value: '₹6,11,703.25',
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
        const StatCard(
          label: 'INVOICE TOTAL',
          value: '₹1,94,18,477.75',
          icon: Icons.receipt_long,
          color: AppColors.kPrimary,
          badgeText: 'INCL. GST',
          backgroundColor: Color(0xFFF8FAFC),
          borderColor: Color(0xFFE2E8F0),
          badgeBackgroundColor: Color(0xFFEDF2F7),
          badgeTextColor: AppColors.kPrimary,
        ),
      ],
    );
  }

  Widget _buildGstr1RateSummaryTable() {
    return _buildResponsiveTableCard(
      title: 'GSTR-1 RATE-WISE OUTWARD SUPPLIES SUMMARY',
      tableWidth: 800, // Enforces horizontal scroll on small devices
      headers: ['GST RATE', 'TAXABLE VALUE', 'CGST', 'SGST', 'TOTAL GST LIABILITY', 'ORDERS'],
      columnWidths: const [150, 130, 110, 110, 150, 80],
      rows: [
        _buildDataRow([
          _styledText('3% (CGST 1.5% + SGST 1.5%)', _navyBlue),
          _styledText('₹1,85,76,774.50', _navyBlue),
          _styledText('₹2,78,651.64', _gold),
          _styledText('₹2,78,651.61', _gold),
          _styledText('₹5,57,303.25', _navyBlue),
          _styledText('40', _navyBlue),
        ]),
        _buildDataRow([
          _styledText('18% (CGST 9% + SGST 9%)', _navyBlue),
          _styledText('₹1,00,000.00', _navyBlue),
          _styledText('₹9,000.00', _gold),
          _styledText('₹9,000.00', _gold),
          _styledText('₹18,000.00', _navyBlue),
          _styledText('1', _navyBlue),
        ]),
        _buildDataRow([
          _styledText('28% (CGST 14% + SGST 14%)', _navyBlue),
          _styledText('₹1,30,000.00', _navyBlue),
          _styledText('₹18,200.00', _gold),
          _styledText('₹18,200.00', _gold),
          _styledText('₹36,400.00', _navyBlue),
          _styledText('1', _navyBlue),
        ], isLast: true),
      ],
    );
  }

  Widget _buildGstr1InvoiceBreakdownTable() {
    return _buildResponsiveTableCard(
      title: 'GSTR-1 B2C INVOICE-WISE BREAKDOWN',
      tableWidth: 1000, 
      headers: ['INVOICE', 'DATE', 'CUSTOMER', 'PRODUCT', 'TAXABLE', 'GST%', 'CGST', 'SGST', 'TOTAL'],
      columnWidths: const [80, 90, 140, 150, 100, 60, 90, 90, 110],
      rows: [
        _buildDataRow([
          _styledText('INV-61', _gold), _styledText('26 Aug 26', AppColors.kTextMuted),
          _styledText('Nandha Kumar.M', _navyBlue), _styledText('40 Gram(s) 24K Gold', _navyBlue),
          _styledText('₹8,15,540.00', _navyBlue), _styledText('3%', _navyBlue),
          _styledText('₹12,233.10', _gold), _styledText('₹12,233.10', _gold), _styledText('₹8,40,006.20', _navyBlue),
        ]),
        _buildDataRow([
          _styledText('INV-60', _gold), _styledText('26 Aug 26', AppColors.kTextMuted),
          _styledText('Prakash.A', _navyBlue), _styledText('8 Gram(s) 24K Gold', _navyBlue),
          _styledText('₹1,63,108.00', _navyBlue), _styledText('3%', _navyBlue),
          _styledText('₹2,446.62', _gold), _styledText('₹2,446.62', _gold), _styledText('₹1,68,001.24', _navyBlue),
        ]),
        _buildDataRow([
          _styledText('INV-59', _gold), _styledText('25 Aug 26', AppColors.kTextMuted),
          _styledText('Somasundaram.S', _navyBlue), _styledText('8 Gram(s) 24K Gold', _navyBlue),
          _styledText('₹1,63,108.00', _navyBlue), _styledText('3%', _navyBlue),
          _styledText('₹2,446.62', _gold), _styledText('₹2,446.62', _gold), _styledText('₹1,68,001.24', _navyBlue),
        ]),
        _buildDataRow([
          _styledText('INV-58', _gold), _styledText('25 Aug 26', AppColors.kTextMuted),
          _styledText('Kanagaraj K', _navyBlue), _styledText('32 Gram(s) 24K Gold', _navyBlue),
          _styledText('₹6,52,432.00', _navyBlue), _styledText('3%', _navyBlue),
          _styledText('₹9,786.48', _gold), _styledText('₹9,786.48', _gold), _styledText('₹6,72,004.96', _navyBlue),
        ], isLast: true),
      ],
    );
  }

  // ===========================================================================
  // GSTR-3B VIEW
  // ===========================================================================

  Widget _buildGstr3bTable() {
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
      rows: [
        _buildDataRow([
          _styledText('3.1(a) Outward Taxable Supplies (Other than Zero Rated, Nil Rated and Exempted)', _navyBlue),
          _styledText('₹1,88,06,774.50', _navyBlue),
          _styledText('₹0.00', AppColors.kTextMuted),
          _styledText('₹3,05,851.64', _gold),
          _styledText('₹3,05,851.61', _gold),
          _styledText('₹6,11,703.25', _navyBlue),
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
          _styledText('₹1,88,06,774.50', _navyBlue),
          _styledText('₹0.00', AppColors.kTextMuted),
          _styledText('₹3,05,851.64', _gold),
          _styledText('₹3,05,851.61', _gold),
          _styledText('₹6,11,703.25', _navyBlue),
        ], isLast: true),
      ],
    );
  }

  // ===========================================================================
  // REUSABLE TABLE BUILDERS (Ensures Mobile Responsiveness)
  // ===========================================================================

  Widget _buildResponsiveTableCard({
    required String title,
    String? subtitle,
    required double tableWidth,
    required List<String> headers,
    required List<double> columnWidths,
    required List<Widget> rows,
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
          // Scrollable Table Container
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
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
                    // Data Rows
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