import 'package:flutter/material.dart';
// Replace with your actual paths
import 'invoice_model.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/stat_card.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.kBackground,
      child: SingleChildScrollView(
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
            
            _buildInvoiceRegisterTable(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. SEARCH BAR
  // ===========================================================================
  Widget _buildTopSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
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
    );
  }

  // ===========================================================================
  // 2. PROCESS BUTTON
  // ===========================================================================
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }

  // ===========================================================================
  // 3. HEADER CONTROLS CARD
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
          // Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.kPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: AppColors.goldColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
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
                      'EVERY TAX INVOICE ISSUED · REAL-TIME · 45 TOTAL',
                      style: TextStyle(
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
          
          // Controls (Search, Filter, Refresh)
          Row(
            children: [
              Expanded(
                flex: isMobile ? 1 : 3,
                child: _buildMiniSearchBar(),
              ),
              const SizedBox(width: 8),
              if (!isMobile) ...[
                Expanded(
                  flex: 2,
                  child: _buildFilterDropdown(),
                ),
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
          
          // Export Button
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.insert_drive_file_outlined, color: AppColors.kSurface, size: 14),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
      child: const Row(
        children: [
          SizedBox(width: 12),
          Icon(Icons.search, size: 16, color: AppColors.kTextMuted),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
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
          value: 'ACTIVE',
          icon: const Icon(Icons.unfold_more, size: 16, color: AppColors.kTextMuted),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: AppColors.kPrimary,
          ),
          items: ['ACTIVE', 'ALL'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.kBorder),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.refresh, size: 18, color: AppColors.kTextMuted),
    );
  }

  // ===========================================================================
  // 4. STAT CARDS
  // ===========================================================================
  Widget _buildResponsiveStatCards(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Column(
      children: [
        GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 1.05 : 1.25,
          children: const [
            StatCard(
              label: 'INVOICES ISSUED',
              value: '45',
              icon: Icons.receipt_long_outlined,
              color: AppColors.kPrimary,
              badgeText: 'TOTAL COUNT',
            ),
            StatCard(
              label: 'TAXABLE VALUE',
              value: '₹2,19,05,773.50',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.kPrimary,
              badgeText: 'EX-GST',
            ),
            StatCard(
              label: 'CGST',
              value: '₹7,27,211.54',
              icon: Icons.pie_chart_outline_rounded,
              color: AppColors.kPrimary,
              badgeText: 'CENTRAL GST',
            ),
            StatCard(
              label: 'SGST',
              value: '₹7,27,211.54',
              icon: Icons.pie_chart_outline_rounded,
              color: AppColors.kPrimary,
              badgeText: 'STATE GST',
            ),
          ],
        ),
        const SizedBox(height: 12),
        const StatCard(
          label: 'GRAND TOTAL',
          value: '₹2,33,60,196.57',
          icon: Icons.payments_outlined,
          color: AppColors.goldColor,
          badgeText: 'INCL. GST',
          backgroundColor: AppColors.kPrimary,
          borderColor: AppColors.kPrimary,
          badgeBackgroundColor: AppColors.kPrimaryAccent,
          badgeTextColor: AppColors.goldColor,
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. INVOICE TABLE
  // ===========================================================================
  Widget _buildInvoiceRegisterTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimary.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.kPrimary,
                letterSpacing: 1.0,
              ),
            ),
          ),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              // Forces the table to a minimum width so columns don't compress
              // and the dividers span the full necessary width natively.
              constraints: const BoxConstraints(minWidth: 1300),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headers
                    Row(
                      children: const [
                        SizedBox(width: 110, child: _TableHeader('INVOICE')),
                        SizedBox(width: 100, child: _TableHeader('DATE')),
                        SizedBox(width: 170, child: _TableHeader('CUSTOMER')),
                        SizedBox(width: 180, child: _TableHeader('PRODUCT')),
                        SizedBox(width: 130, child: _TableHeader('TAXABLE')),
                        SizedBox(width: 70, child: _TableHeader('GST%')),
                        SizedBox(width: 110, child: _TableHeader('CGST')),
                        SizedBox(width: 110, child: _TableHeader('SGST')),
                        SizedBox(width: 130, child: _TableHeader('TOTAL')),
                        SizedBox(width: 90, child: _TableHeader('STATUS')),
                        SizedBox(width: 100, child: _TableHeader('ACTION')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.kBorder, height: 1, thickness: 1),
                    const SizedBox(height: 16),
                    
                    // Rows
                    ...sampleInvoices.map((invoice) {
                      return Column(
                        children: [
                          _buildTableRow(invoice),
                          const Divider(color: Color(0xFFF8FAFC), height: 32, thickness: 1.5),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(InvoiceModel invoice) {
    return Row(
      children: [
        // INVOICE ID
        SizedBox(
          width: 110,
          child: Text(
            invoice.invoiceId.replaceFirst('-', '-\n'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: AppColors.goldColor,
              height: 1.3,
            ),
          ),
        ),
        // DATE
        SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice.dateDay,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: AppColors.kTextMuted,
                ),
              ),
              Text(
                invoice.dateMonthYear,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: AppColors.kTextMuted,
                ),
              ),
            ],
          ),
        ),
        // CUSTOMER
        SizedBox(
          width: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice.customerName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: AppColors.kPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                invoice.customerCode,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: AppColors.kTextMuted,
                ),
              ),
            ],
          ),
        ),
        // PRODUCT
        SizedBox(
          width: 180,
          child: Text(
            invoice.productDetails,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: AppColors.kPrimary,
            ),
          ),
        ),
        // TAXABLE (Using FittedBox for financial safety)
        SizedBox(
          width: 130,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              invoice.taxableValue,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.kPrimary,
              ),
            ),
          ),
        ),
        // GST%
        SizedBox(
          width: 70,
          child: Text(
            invoice.gstRate,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: AppColors.kPrimary,
            ),
          ),
        ),
        // CGST
        SizedBox(
          width: 110,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              invoice.cgst,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.goldColor,
              ),
            ),
          ),
        ),
        // SGST
        SizedBox(
          width: 110,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              invoice.sgst,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.goldColor,
              ),
            ),
          ),
        ),
        // TOTAL
        SizedBox(
          width: 130,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              invoice.total,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.kPrimary,
              ),
            ),
          ),
        ),
        // STATUS
        SizedBox(
          width: 90,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.kSuccess.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              invoice.status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.kSuccess,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        // ACTION BUTTON
        SizedBox(
          width: 100,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.print_outlined, size: 12, color: AppColors.kSurface),
            label: const Text(
              'VIEW',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.kSurface,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

// Helper Widget for Table Headers
class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: AppColors.kTextMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}