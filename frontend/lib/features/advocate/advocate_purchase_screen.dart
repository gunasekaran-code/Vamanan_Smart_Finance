import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/advocate_purchase_model.dart';
import '../../services/advocate_purchase_service.dart';
import 'purchase_verification_details_page.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

// NOTE: `PurchaseVerificationDetailsPage` currently expects a `PurchaseItem`.
// Update its constructor to accept `PurchaseModel` (from
// advocate_purchase_model.dart) instead — the field names are the same,
// so the body of that page shouldn't need further changes.

class PurchaseVerificationPage extends StatefulWidget {
  const PurchaseVerificationPage({super.key});

  @override
  State<PurchaseVerificationPage> createState() =>
      _PurchaseVerificationPageState();
}

class _PurchaseVerificationPageState extends State<PurchaseVerificationPage> {
  final AdvocatePurchaseService _service = AdvocatePurchaseService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedTab = 'ALL PURCHASES';
  final List<String> _tabs = [
    'ALL PURCHASES',
    'PENDING VERIFICATION',
    'ACTIVE',
    'COMPLETED',
    'REJECTED'
  ];

  bool _isLoading = true;
  String? _error;
  List<PurchaseModel> _purchases = [];

  @override
  void initState() {
    super.initState();
    _loadPurchases();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final purchases = await _service.fetchPurchases();
      setState(() {
        _purchases = purchases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<PurchaseModel> get _filteredPurchases {
    Iterable<PurchaseModel> list = _purchases;

    if (_selectedTab != 'ALL PURCHASES') {
      final statusFilter =
          _selectedTab == 'PENDING VERIFICATION' ? 'PENDING' : _selectedTab;
      list = list.where((p) => p.status == statusFilter);
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) =>
          p.customerName.toLowerCase().contains(query) ||
          p.customerEmail.toLowerCase().contains(query) ||
          p.id.toString().contains(query));
    }

    return list.toList();
  }

  // --- APPROVE / REJECT ---
  Future<void> _handleApprove(PurchaseModel item) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Approve Purchase',
      message:
          'Are you sure you want to approve purchase #CC-${item.id} for ${item.customerName}? This will verify the payment and allocate the asset.',
      confirmLabel: 'Approve',
      confirmButtonColor: AppColors.kSuccess,
    );
    if (confirmed != true) return;

    try {
      await _service.approvePurchase(item.id);
      setState(() => item.status = 'ACTIVE');
      ToastService.show(
        title: 'Purchase Approved',
        message: '#CC-${item.id} has been successfully verified and activated.',
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
        title: 'Approval Failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _handleReject(PurchaseModel item) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Reject Purchase',
      message:
          'Are you sure you want to reject purchase #CC-${item.id} for ${item.customerName}?',
      confirmLabel: 'Reject',
      confirmButtonColor: AppColors.kDanger,
    );
    if (confirmed != true) return;

    try {
      await _service.rejectPurchase(item.id);
      setState(() => item.status = 'REJECTED');
      ToastService.show(
        title: 'Purchase Rejected',
        message: '#CC-${item.id} has been rejected.',
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
        title: 'Rejection Failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  void _openDetails(PurchaseModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PurchaseVerificationDetailsPage(item: item)),
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PURCHASE VERIFICATION HUB',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 22,
                          letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('VERIFY AND APPROVE CUSTOMER GOLD PURCHASES',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 10,
                          color: Colors.grey,
                          letterSpacing: 1.0)),
                ],
              ),
            ),
            if (!isMobile) _buildPendingBadge(),
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 16),
          _buildPendingBadge(),
        ],
        const SizedBox(height: 32),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60.0),
            child: Center(child: AppLoader()),
          )
        else if (_error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load purchases:\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _loadPurchases, child: const Text('Retry')),
                ],
              ),
            ),
          )
        else ...[
          // 1. Stat Grid (derived from the loaded purchases)
          _StatCards2x2Grid(purchases: _purchases),
          const SizedBox(height: 32),

          // 2. Tabs and Search Bar
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                        scrollDirection: Axis.horizontal, child: _buildTabs()),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildTabs())),
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
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_filteredPurchases.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'NO PURCHASES FOUND',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFFCBD5E1),
                            letterSpacing: 0.8),
                      ),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width - 64),
                      child: DataTable(
                        columnSpacing: 24,
                        headingRowHeight: 56,
                        dataRowMinHeight: 85,
                        dataRowMaxHeight: 85,
                        headingTextStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            fontSize: 10,
                            letterSpacing: 1.0),
                        columns: const [
                          DataColumn(label: Text('PURCHASE ID')),
                          DataColumn(label: Text('CUSTOMER DETAILS')),
                          DataColumn(label: Text('PRODUCT DETAILS')),
                          DataColumn(label: Text('PAYMENT DETAILS')),
                          DataColumn(label: Text('TOTAL PRICE (₹)')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('ACTION')),
                        ],
                        rows: _filteredPurchases
                            .map((item) => _buildDataRow(item))
                            .toList(),
                      ),
                    ),
                  ),

                // 4. Grand Total Footer
                _buildGrandTotalFooter(_filteredPurchases),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPendingBadge() {
    final pendingCount = _purchases.where((p) => p.status == 'PENDING').length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.goldBadgeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.goldBorder)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 14, color: AppColors.goldColor),
          const SizedBox(width: 8),
          Text('$pendingCount PENDING VERIFICATION',
              style: const TextStyle(
                  color: AppColors.goldColor,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
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
              decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF1E293B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(tab,
                  style: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 10,
                      letterSpacing: 0.5)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'SEARCH...',
        hintStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            fontSize: 10,
            color: Color(0xFF94A3B8)),
        prefixIcon:
            const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  // --- TABLE ROWS ---
  DataRow _buildDataRow(PurchaseModel item) {
    return DataRow(
      cells: [
        DataCell(Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('#CC-${item.id}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(_formatDate(item.date),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      fontSize: 9,
                      color: Color(0xFF94A3B8))),
            ])),
        DataCell(Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF1E293B),
            child: Text(
              item.customerName.isNotEmpty ? item.customerName[0] : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.customerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(item.customerEmail,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        fontSize: 9,
                        color: Color(0xFF94A3B8))),
              ]),
        ])),
        DataCell(Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                      color: Color(0xFF2563EB))),
              const SizedBox(height: 4),
              Text('${item.weight} • ${item.category}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 9,
                      color: AppColors.goldColor)),
            ])),
        DataCell(Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.paymentMethod,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text('TID: ${item.paymentTid}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      fontSize: 9,
                      color: Color(0xFF94A3B8))),
            ])),
        DataCell(Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('₹${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text('EX-GST: ₹${item.exGst.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      fontSize: 8,
                      color: Color(0xFF94A3B8))),
            ])),
        DataCell(_buildStatusBadge(item.status)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.status == 'PENDING') ...[
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton(
                  onPressed: () => _handleApprove(item),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20))),
                  child: const Text('APPROVE',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 10,
                          letterSpacing: 0.5)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: OutlinedButton(
                  onPressed: () => _handleReject(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kDanger,
                    side:
                        const BorderSide(color: AppColors.kDanger, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('REJECT',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 10,
                          letterSpacing: 0.5)),
                ),
              ),
            ],
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8)),
              child: IconButton(
                icon: const Icon(Icons.remove_red_eye_outlined,
                    size: 16, color: Color(0xFF94A3B8)),
                onPressed: () => _openDetails(item),
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
      bg = const Color(0xFFFFFBEB);
      border = AppColors.goldBorder;
      text = AppColors.goldColor;
    } else if (status == 'ACTIVE') {
      bg = Colors.transparent;
      border = AppColors.goldBorder;
      text = AppColors.goldColor;
    } else if (status == 'REJECTED') {
      bg = const Color(0xFFEFF6FF);
      border = Colors.transparent;
      text = const Color(0xFF2563EB);
    } else {
      bg = const Color(0xFFF1F5F9);
      border = Colors.transparent;
      text = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              color: text,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              fontSize: 10,
              letterSpacing: 0.5)),
    );
  }

  // --- GRAND TOTAL FOOTER (for the currently filtered rows) ---
  Widget _buildGrandTotalFooter(List<PurchaseModel> purchases) {
    final double grandTotal =
        purchases.fold(0, (sum, item) => sum + item.totalPrice);
    final double totalExGst =
        purchases.fold(0, (sum, item) => sum + item.exGst);
    final double totalGst = purchases.fold(0, (sum, item) => sum + item.gst);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1B233A),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          Text(
            'GRAND TOTAL • ${purchases.length} PURCHASES',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: 11,
                letterSpacing: 1.0),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            children: [
              Text('GST: ₹${totalGst.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.goldColor,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 11)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.goldColor,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('EX-GST: ₹${totalExGst.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          fontSize: 8)),
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
// 2x2 STAT GRID — derived live from the loaded purchase list
// ============================================================================
class _StatCards2x2Grid extends StatelessWidget {
  final List<PurchaseModel> purchases;

  const _StatCards2x2Grid({required this.purchases});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 380;

    // Institutional Revenue: sum of all purchase totals.
    final revenue = purchases.fold(0.0, (sum, p) => sum + p.totalPrice);

    // Active Investors: distinct customers with an ACTIVE purchase.
    final activeInvestors = purchases
        .where((p) => p.status == 'ACTIVE')
        .map((p) => p.customerEmail)
        .toSet()
        .length;

    // Asset Inventory: sum of numeric weight values for gold/silver purchases.
    double assetGrams = 0;
    for (final p in purchases) {
      if (p.category == 'GOLD' || p.category == 'SILVER') {
        final match = RegExp(r'[\d.]+').firstMatch(p.weight);
        if (match != null) assetGrams += double.tryParse(match.group(0)!) ?? 0;
      }
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: isSmallMobile ? 8.0 : 12.0,
      crossAxisSpacing: isSmallMobile ? 8.0 : 12.0,
      childAspectRatio: isSmallMobile ? 0.78 : 1.15,
      children: [
        _SafeStatCard(
          label: 'Institutional Revenue',
          value: '₹${revenue.toStringAsFixed(2)}',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.goldColor,
          badgeText: '${purchases.length} TOTAL',
          backgroundColor: AppColors.goldBg,
          borderColor: AppColors.goldBorder,
          badgeBackgroundColor: AppColors.goldBadgeBg,
          badgeTextColor: AppColors.goldColor,
        ),
        _SafeStatCard(
          label: 'Pending Review',
          value:
              purchases.where((p) => p.status == 'PENDING').length.toString(),
          icon: Icons.payments_outlined,
          color: AppColors.kPrimary,
          badgeText: 'QUEUE',
          backgroundColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
          badgeBackgroundColor: const Color(0xFFEDF2F7),
          badgeTextColor: AppColors.kPrimary,
        ),
        _SafeStatCard(
          label: 'Active Investors',
          value: activeInvestors.toString(),
          icon: Icons.group_outlined,
          color: const Color(0xFF3B82F6),
          badgeText: 'ACTIVE NOW',
          backgroundColor: const Color(0xFFF0F7FF),
          borderColor: const Color(0xFFBFDBFE),
          badgeBackgroundColor: const Color(0xFFDBEAFE),
          badgeTextColor: const Color(0xFF1D4ED8),
        ),
        _SafeStatCard(
          label: 'Asset Inventory',
          value: '${assetGrams.toStringAsFixed(3)}g',
          icon: Icons.workspace_premium_outlined,
          color: AppColors.goldColor,
          badgeText: 'GOLD + SILVER',
          backgroundColor: AppColors.goldBg,
          borderColor: AppColors.goldBorder,
          badgeBackgroundColor: AppColors.goldBadgeBg,
          badgeTextColor: AppColors.goldColor,
        ),
      ],
    );
  }
}

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
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                    color: badgeBackgroundColor,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(badgeText,
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: badgeTextColor)),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: color,
                    letterSpacing: -0.5)),
          ),
        ],
      ),
    );
  }
}
