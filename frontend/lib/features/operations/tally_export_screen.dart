import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/stat_card.dart'; 

class TallyVoucher {
  final String voucherId;
  final String customerName;
  final String customerEmail;
  final String product;
  final String date;
  final String amount;
  final String status;

  TallyVoucher({
    required this.voucherId,
    required this.customerName,
    required this.customerEmail,
    required this.product,
    required this.date,
    required this.amount,
    required this.status,
  });
}

class TallyExportScreen extends StatefulWidget {
  const TallyExportScreen({super.key});

  @override
  State<TallyExportScreen> createState() => _TallyExportScreenState();
}

class _TallyExportScreenState extends State<TallyExportScreen> {
  // Form Controllers
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _salesLedgerController = TextEditingController(text: 'Sales Account');
  final TextEditingController _gatewayController = TextEditingController(text: 'http://localhost:9000');
  
  String _selectedVoucherType = 'Sales';
  String _selectedStatusFilter = 'All Applications';

  final List<String> _voucherTypes = ['Sales', 'Receipt', 'Journal'];
  final List<String> _statusFilters = ['All Applications', 'Pending', 'Processed'];

  // Mock Data
  final List<TallyVoucher> _vouchers = [
    TallyVoucher(voucherId: 'CBA-90', customerName: 'Nandha Kumar.M', customerEmail: 'n2348979@gmail.com', product: 'Gold', date: '2026-05-05', amount: '₹8,40,000.00', status: 'PENDING'),
    TallyVoucher(voucherId: 'CBA-89', customerName: 'Nandha Kumar.M', customerEmail: 'n2348979@gmail.com', product: '40 Gram(s) 24K Gold', date: '2026-08-26', amount: '₹8,15,540.00', status: 'PENDING'),
    TallyVoucher(voucherId: 'CBA-88', customerName: 'Prakash.A', customerEmail: 'prakashaugust19@gmail.com', product: 'Gold', date: '2026-05-26', amount: '₹1,68,000.00', status: 'PENDING'),
    TallyVoucher(voucherId: 'CBA-87', customerName: 'Prakash.A', customerEmail: 'prakashaugust19@gmail.com', product: '8 Gram(s) 24K Gold', date: '2026-08-26', amount: '₹1,63,108.00', status: 'PENDING'),
    TallyVoucher(voucherId: 'CBA-86', customerName: 'Somasundaram.S', customerEmail: 'somaskm0504@gmail.com', product: '8 Gram(s) 24K Gold', date: '2026-08-25', amount: '₹1,63,108.00', status: 'PENDING'),
    TallyVoucher(voucherId: 'CBA-85', customerName: 'Kanagaraj K', customerEmail: 'kanagu2024k@gmail.com', product: 'Gold', date: '2026-07-22', amount: '₹6,72,000.00', status: 'PENDING'),
  ];

  @override
  void dispose() {
    _companyNameController.dispose();
    _salesLedgerController.dispose();
    _gatewayController.dispose();
    super.dispose();
  }

  Future<void> _handlePushToTally() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'PUSH TO TALLY',
      message: 'Push these vouchers directly into Tally? Make sure TallyPrime is open with the gateway enabled (port 9000).',
      confirmLabel: 'OK',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFFD97706), // Gold/Amber to match button
    );

    if (confirmed == true) {
      ToastService.show(
        title: 'Sync Initiated', 
        message: 'Vouchers are being pushed to TallyPrime.', 
        type: ToastType.success
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.kTextDark),
          onPressed: () {},
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TALLY EXPORT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
            Text('CASHBACK APPLICATIONS ⸰ TALLY VOUCHERS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.kTextMuted),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.kBorder, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Page Header ---
              const Text(
                'TALLY VOUCHER EXPORT',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 4),
              Text(
                'POST CUSTOMER PURCHASES TO TALLY AS SALES VOUCHERS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1.5),
              ),
              const SizedBox(height: 24),

              // --- 2. Responsive Layout for Stats, Form, and Table ---
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 900;
                  final isSmallMobile = constraints.maxWidth < 380;

                  Widget statsAndForm = Column(
                    children: [
                      // Stat Cards Grid
                      GridView.count(
                        crossAxisCount: isMobile ? 2 : 3,
                        crossAxisSpacing: isSmallMobile ? 8.0 : 16.0,
                        mainAxisSpacing: isSmallMobile ? 8.0 : 16.0,
                        childAspectRatio:
                            isMobile ? (isSmallMobile ? 0.82 : 1.4) : 1.8,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: const [
                          StatCard(
                            label: 'APPLICATIONS',
                            value: '86',
                            icon: Icons.description,
                            color: Color(0xFF3B82F6),
                            badgeText: 'TOTAL',
                            backgroundColor: Color(0xFFF0F7FF),
                            borderColor: Color(0xFFBFDBFE),
                            badgeBackgroundColor: Color(0xFFDBEAFE),
                            badgeTextColor: Color(0xFF1D4ED8),
                          ),
                          StatCard(
                            label: 'TOTAL VOUCHER VALUE',
                            value: '₹4,11,44,183.14',
                            icon: Icons.monetization_on,
                            color: AppColors.goldColor,
                            badgeText: 'VALUE',
                            backgroundColor: AppColors.goldBg,
                            borderColor: AppColors.goldBorder,
                            badgeBackgroundColor: AppColors.goldBadgeBg,
                            badgeTextColor: AppColors.goldColor,
                          ),
                          StatCard(
                            label: 'VOUCHER TYPE',
                            value: 'Sales',
                            icon: Icons.receipt_long,
                            color: Color(0xFF1E3A8A),
                            badgeText: 'SALES',
                            backgroundColor: Color(0xFFF8FAFC),
                            borderColor: Color(0xFFE2E8F0),
                            badgeBackgroundColor: Color(0xFFEDF2F7),
                            badgeTextColor: Color(0xFF1E3A8A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Tally Settings Form Container
                      _buildTallySettingsForm(),
                    ],
                  );

                  Widget dataTable = _buildDataTable();

                  // Stack vertically on mobile, side-by-side on large screens
                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        statsAndForm,
                        const SizedBox(height: 32),
                        dataTable,
                      ],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: statsAndForm),
                        const SizedBox(width: 32),
                        Expanded(flex: 7, child: dataTable),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Tally Settings Form Component ---
  Widget _buildTallySettingsForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.account_balance, color: Color(0xFFFBBF24), size: 20),
              ),
              const SizedBox(width: 16),
              const Text('TALLY SETTINGS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 32),

          // Inputs
          _buildInputField(label: 'TALLY COMPANY NAME', controller: _companyNameController, hintText: 'Blank = currently open company', prefixIcon: Icons.domain),
          const SizedBox(height: 16),
          _buildInputField(label: 'SALES LEDGER', controller: _salesLedgerController, prefixIcon: Icons.menu_book),
          const SizedBox(height: 16),
          _buildDropdownField('VOUCHER TYPE', _selectedVoucherType, _voucherTypes, (val) => setState(() => _selectedVoucherType = val!)),
          const SizedBox(height: 16),
          _buildDropdownField('STATUS FILTER', _selectedStatusFilter, _statusFilters, (val) => setState(() => _selectedStatusFilter = val!)),
          const SizedBox(height: 16),
          _buildInputField(label: 'TALLY GATEWAY (PORT)', controller: _gatewayController, isBold: true),
          const SizedBox(height: 32),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download, size: 16),
              label: const Text('DOWNLOAD TALLY XML', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handlePushToTally,
              icon: const Icon(Icons.share, size: 16),
              label: const Text('PUSH TO TALLY', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706), // Gold/Amber
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.preview, size: 16),
              label: const Text('PREVIEW XML', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A8A),
                side: const BorderSide(color: AppColors.kBorder),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Data Table Component ---
  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CASHBACK APPLICATIONS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), letterSpacing: 1)),
                Text('86 RECORD(S)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.kBorder),

          // Scrollable Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
              child: DataTable(
                columnSpacing: 32,
                headingRowHeight: 56,
                dataRowMinHeight: 72,
                dataRowMaxHeight: 72,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                dividerThickness: 1,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 10, letterSpacing: 1.5),
                columns: const [
                  DataColumn(label: Text('VOUCHER')),
                  DataColumn(label: Text('CUSTOMER')),
                  DataColumn(label: Text('PRODUCT')),
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('AMOUNT')),
                  DataColumn(label: Text('STATUS')),
                ],
                rows: _vouchers.map((voucher) {
                  return DataRow(
                    cells: [
                      DataCell(Text(voucher.voucherId, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13))),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(voucher.customerName, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13)),
                            Text(voucher.customerEmail, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                          ],
                        ),
                      ),
                      DataCell(Text(voucher.product, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 12))),
                      DataCell(Text(voucher.date, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                      DataCell(Text(voucher.amount, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 14))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFDE68A))),
                          child: Text(voucher.status, style: const TextStyle(color: Color(0xFFD97706), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Utility Input Builders ---

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    IconData? prefixIcon,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, fontStyle: isBold ? FontStyle.italic : FontStyle.normal, color: const Color(0xFF1E3A8A)),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.kTextMuted, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic, fontSize: 13),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFFCBD5E1), size: 20) : null,
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          icon: const Icon(Icons.unfold_more, color: Color(0xFF1E3A8A), size: 18),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
          decoration: InputDecoration(
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
          ),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
        ),
      ],
    );
  }
}