// lib/screens/purchases/purchase_verification_page.dart
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'purchase_verification_details_page.dart'; // Import the details page

// --- Enhanced Dummy Data Model ---
class PurchaseItem {
  final String id;
  final String date;
  final String customerName;
  final String customerEmail;
  final String phone;
  final String aadhar;
  final String pan;
  final String productTitle;
  final String category;
  final String weight;
  final String paymentMethod;
  final String paymentTid;
  final double totalPrice; // Inclusive of GST
  final double exGst;      // Product Subtotal
  final double gst;        // GST Amount
  String status; // PENDING, ACTIVE, REJECTED

  PurchaseItem({
    required this.id,
    required this.date,
    required this.customerName,
    required this.customerEmail,
    this.phone = '9788086424',
    this.aadhar = 'N/A',
    this.pan = 'N/A',
    required this.productTitle,
    this.category = 'GOLD',
    required this.weight,
    required this.paymentMethod,
    required this.paymentTid,
    required this.totalPrice,
    required this.exGst,
    required this.gst,
    required this.status,
  });
}

class PurchaseVerificationPage extends StatefulWidget {
  const PurchaseVerificationPage({super.key});

  @override
  State<PurchaseVerificationPage> createState() => _PurchaseVerificationPageState();
}

class _PurchaseVerificationPageState extends State<PurchaseVerificationPage> {
  String _selectedTab = 'ALL PURCHASES';
  final List<String> _tabs = ['ALL PURCHASES', 'PENDING VERIFICATION', 'ACTIVE', 'COMPLETED', 'REJECTED'];

  // Dummy Data
  final List<PurchaseItem> _purchases = [
    PurchaseItem(id: '#CC-26', date: '15/8/2026', customerName: 'ANJI.G', customerEmail: 'VEERAANJI4777@GMAIL.COM', productTitle: '22K GOLD ASSET', weight: '8.000 GRAMS', paymentMethod: 'BANK TRANSFER', paymentTid: 'TID: 12345', totalPrice: 160000.20, exGst: 155340.00, gst: 4660.20, status: 'PENDING'),
    PurchaseItem(id: '#CC-25', date: '15/8/2026', customerName: 'ASHOK KUMAR.S', customerEmail: 'ASHOKVETRI143129@GMAIL.COM', productTitle: '22K GOLD ASSET', weight: '40.000 GRAMS', paymentMethod: 'BANK TRANSFER', paymentTid: 'TID: 12345', totalPrice: 800001.00, exGst: 776700.00, gst: 23301.00, status: 'PENDING'),
    PurchaseItem(id: '#CC-21', date: '12/8/2026', customerName: 'TIRUPARANKUNDRAM MURUGAN', customerEmail: 'THIRUPARANKUNDRAMM@GMAIL.COM', productTitle: 'ROYAL ENFIELD', weight: '1.000 GRAMS', paymentMethod: 'BANK TRANSFER', paymentTid: 'TID: 2345678098765', totalPrice: 166400.00, exGst: 130000.00, gst: 36400.00, status: 'ACTIVE'),
    PurchaseItem(id: '#CC-19', date: '7/8/2026', customerName: 'THIRUTHANI MURUGAN', customerEmail: 'THIRUTHANIM882@GMAIL.COM', productTitle: 'APPLE IPHONE', weight: '1.000 GRAMS', paymentMethod: 'BANK TRANSFER', paymentTid: 'TID: 123456789098', totalPrice: 118000.00, exGst: 100000.00, gst: 18000.00, status: 'REJECTED'),
  ];

  // --- APPROVE CONFIRMATION LOGIC ---
  Future<void> _handleApprove(PurchaseItem item) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Approve Purchase',
      message: 'Are you sure you want to approve purchase ${item.id} for ${item.customerName}? This will verify the payment and allocate the asset.',
      confirmLabel: 'Approve',
      confirmButtonColor: AppColors.kSuccess,
    );

    if (confirmed == true) {
      setState(() => item.status = 'ACTIVE');
      ToastService.show(
        title: 'Purchase Approved',
        message: '${item.id} has been successfully verified and activated.',
        type: ToastType.success,
      );
    }
  }

  void _openDetails(PurchaseItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PurchaseVerificationDetailsPage(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return AppPage(
      title: null,
      children: [
        // Custom Header for this page
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('PURCHASE VERIFICATION HUB', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 22, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('VERIFY AND APPROVE CUSTOMER GOLD PURCHASES', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10, color: Colors.grey, letterSpacing: 1.0)),
                ],
              ),
            ),
            if (!isMobile) _buildPendingBadge(), // Top right on desktop
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 16),
          _buildPendingBadge(), // Below title on mobile to prevent overflow
        ],
        const SizedBox(height: 32),

        // 1. Requested Grid (Modified internally to prevent overflow)
        const _StatCards2x2Grid(),
        const SizedBox(height: 32),

        // 2. Tabs and Search Bar
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 16),
                  SingleChildScrollView(scrollDirection: Axis.horizontal, child: _buildTabs()),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: _buildTabs())),
                  const SizedBox(width: 16),
                  SizedBox(width: 300, child: _buildSearchField()),
                ],
              ),
        const SizedBox(height: 24),

        // 3. Main Data Table & Total Footer
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Responsive Table Wrapper
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64),
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowHeight: 56,
                    dataRowMinHeight: 85,
                    dataRowMaxHeight: 85,
                    headingTextStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10, letterSpacing: 1.0),
                    columns: const [
                      DataColumn(label: Text('PURCHASE ID')),
                      DataColumn(label: Text('CUSTOMER DETAILS')),
                      DataColumn(label: Text('PRODUCT DETAILS')),
                      DataColumn(label: Text('PAYMENT DETAILS')),
                      DataColumn(label: Text('TOTAL PRICE (₹)')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('ACTION')),
                    ],
                    rows: _purchases.map((item) => _buildDataRow(item)).toList(),
                  ),
                ),
              ),
              
              // 4. Fixed Grand Total Dark Footer (No Overflow)
              _buildGrandTotalFooter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: AppColors.goldBadgeBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.goldBorder)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.access_time, size: 14, color: AppColors.goldColor),
          SizedBox(width: 8),
          Text('31 PENDING VERIFICATION', style: TextStyle(color: AppColors.goldColor, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
        ],
      ),
    );
  }

  // --- TABS & SEARCH (Omitted unchanged code for brevity, same as previous) ---
  Widget _buildTabs() { /* ... same as before ... */ 
    return Row(
      children: _tabs.map((tab) {
        final isSelected = _selectedTab == tab;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: InkWell(
            onTap: () => setState(() => _selectedTab = tab),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? const Color(0xFF1E293B) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
              child: Text(tab, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10, letterSpacing: 0.5)),
            ),
          ),
        );
      }).toList(),
    );
  }
  Widget _buildSearchField() { /* ... same as before ... */ 
    return TextField(
      decoration: InputDecoration(
        hintText: 'SEARCH...',
        hintStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
      ),
    );
  }

  // --- TABLE ROWS ---
  DataRow _buildDataRow(PurchaseItem item) {
    return DataRow(
      cells: [
        DataCell(Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.id, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(item.date, style: const TextStyle(fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, fontSize: 9, color: Color(0xFF94A3B8))),
        ])),
        DataCell(Row(children: [
          CircleAvatar(radius: 16, backgroundColor: const Color(0xFF1E293B), child: Text(item.customerName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 14))),
          const SizedBox(width: 12),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.customerName, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text(item.customerEmail, style: const TextStyle(fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, fontSize: 9, color: Color(0xFF94A3B8))),
          ]),
        ])),
        DataCell(Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.productTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, color: Color(0xFF2563EB))),
          const SizedBox(height: 4),
          Text('${item.weight} • ${item.category}', style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 9, color: AppColors.goldColor)),
        ])),
        DataCell(Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(item.paymentTid, style: const TextStyle(fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, fontSize: 9, color: Color(0xFF94A3B8))),
        ])),
        DataCell(Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('₹${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 14, color: Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text('EX-GST: ₹${item.exGst.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, fontSize: 8, color: Color(0xFF94A3B8))),
        ])),
        DataCell(_buildStatusBadge(item.status)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.status == 'PENDING')
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton(
                  onPressed: () => _handleApprove(item),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldColor, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10, letterSpacing: 0.5)),
                ),
              ),
            Container(
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
              child: IconButton(
                icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF94A3B8)),
                onPressed: () => _openDetails(item), // Opens the Details Page!
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg, border, text;
    if (status == 'PENDING') {
      bg = const Color(0xFFFFFBEB); border = AppColors.goldBorder; text = AppColors.goldColor;
    } else if (status == 'ACTIVE') {
      bg = Colors.transparent; border = AppColors.goldBorder; text = AppColors.goldColor;
    } else if (status == 'REJECTED') {
      bg = const Color(0xFFEFF6FF); border = Colors.transparent; text = const Color(0xFF2563EB);
    } else {
      bg = const Color(0xFFF1F5F9); border = Colors.transparent; text = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: text, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10, letterSpacing: 0.5)),
    );
  }

  // --- 4. FIXED GRAND TOTAL FOOTER (Prevents Overflow) ---
  Widget _buildGrandTotalFooter() {
    final double grandTotal = _purchases.fold(0, (sum, item) => sum + item.totalPrice);
    final double totalExGst = _purchases.fold(0, (sum, item) => sum + item.exGst);
    final double totalGst = _purchases.fold(0, (sum, item) => sum + item.gst);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1B233A),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      // Wrapped in Wrap to prevent overflow on mobile devices
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          Text(
            'GRAND TOTAL • ${_purchases.length} PURCHASES',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1.0),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            children: [
              Text(
                'GST: ₹${totalGst.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.goldColor, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.goldColor, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'EX-GST: ₹${totalExGst.toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REQUESTED 2x2 GRID STRUCTURE (Fixed Pixel Overflows)
// ============================================================================
class _StatCards2x2Grid extends StatelessWidget {
  const _StatCards2x2Grid({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 380;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: isSmallMobile ? 8.0 : 12.0,
      crossAxisSpacing: isSmallMobile ? 8.0 : 12.0,
      // Increased aspect ratio slightly to give content more room on mobile
      childAspectRatio: isSmallMobile ? 0.78 : 1.15,
      children: const [
        _SafeStatCard(
          label: 'Institutional Revenue',
          value: '₹34,60,429.72',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.goldColor,
          badgeText: '+12.4%',
          backgroundColor: AppColors.goldBg,
          borderColor: AppColors.goldBorder,
          badgeBackgroundColor: AppColors.goldBadgeBg,
          badgeTextColor: AppColors.goldColor,
        ),
        _SafeStatCard(
          label: 'Total Payouts',
          value: '₹0',
          icon: Icons.payments_outlined,
          color: AppColors.kPrimary,
          badgeText: '0.0%',
          backgroundColor: Color(0xFFF8FAFC),
          borderColor: Color(0xFFE2E8F0),
          badgeBackgroundColor: Color(0xFFEDF2F7),
          badgeTextColor: AppColors.kPrimary,
        ),
        _SafeStatCard(
          label: 'Active Investors',
          value: '96',
          icon: Icons.group_outlined,
          color: Color(0xFF3B82F6),
          badgeText: 'ACTIVE NOW',
          backgroundColor: Color(0xFFF0F7FF),
          borderColor: Color(0xFFBFDBFE),
          badgeBackgroundColor: Color(0xFFDBEAFE),
          badgeTextColor: Color(0xFF1D4ED8),
        ),
        _SafeStatCard(
          label: 'Asset Inventory',
          value: '152.000g',
          icon: Icons.workspace_premium_outlined,
          color: AppColors.goldColor,
          badgeText: '24K Gold',
          backgroundColor: AppColors.goldBg,
          borderColor: AppColors.goldBorder,
          badgeBackgroundColor: AppColors.goldBadgeBg,
          badgeTextColor: AppColors.goldColor,
        ),
      ],
    );
  }
}

// Internal version using Expanded/FittedBox to absolutely guarantee no overflow
class _SafeStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String badgeText;
  final Color backgroundColor;
  final Color borderColor;
  final Color badgeBackgroundColor;
  final Color badgeTextColor;

  const _SafeStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.badgeText,
    required this.backgroundColor,
    required this.borderColor,
    required this.badgeBackgroundColor,
    required this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(color: badgeBackgroundColor, borderRadius: BorderRadius.circular(6)),
                child: Text(badgeText, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: badgeTextColor)),
              ),
            ],
          ),
          const Spacer(),
          // Fitted Box prevents the label from expanding past the card bounds
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.grey, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 2),
          // Fitted Box prevents the giant number from overflowing
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: color, letterSpacing: -0.5)),
          ),
        ],
      ),
    );
  }
}