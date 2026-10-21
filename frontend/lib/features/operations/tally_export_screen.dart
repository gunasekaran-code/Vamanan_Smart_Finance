import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/stat_card.dart';
import '../../models/tally_export_model.dart';
import '../../services/tally_export_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class TallyExportScreen extends StatefulWidget {
  const TallyExportScreen({super.key});

  @override
  State<TallyExportScreen> createState() => _TallyExportScreenState();
}

class _TallyExportScreenState extends State<TallyExportScreen> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _salesLedgerController = TextEditingController(text: 'Sales Account');
  final TextEditingController _gatewayController = TextEditingController(text: 'http://localhost:9000');

  String _selectedVoucherType = 'Sales';
  String _selectedStatusFilter = 'All Applications';

  final List<String> _voucherTypes = ['Sales', 'Receipt', 'Journal'];
  final List<String> _statusFilters = ['All Applications', 'Pending', 'Processed'];

  final _service = TallyExportService();

  List<CashbackApplication> _applications = [];
  bool _isLoading = true;
  bool _isPushing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _salesLedgerController.dispose();
    _gatewayController.dispose();
    super.dispose();
  }

  String? get _statusQueryValue {
    switch (_selectedStatusFilter) {
      case 'Pending':
        return 'pending';
      case 'Processed':
        return 'approved';
      default:
        return null;
    }
  }

  TallyExportSettings get _settings => TallyExportSettings(
        company: _companyNameController.text,
        salesLedger: _salesLedgerController.text,
        voucherType: _selectedVoucherType,
        gateway: _gatewayController.text,
        statusFilter: _statusQueryValue,
      );

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final apps = await _service.fetchApplications(statusFilter: _statusQueryValue);
      if (!mounted) return;
      setState(() => _applications = apps);
    } on TallyExportException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDownloadXml() async {
    final uri = _service.buildDownloadUri(_settings);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ToastService.show(
        title: 'Could not start download',
        message: 'Try opening the link manually: $uri',
        type: ToastType.error,
      );
    }
  }

  Future<void> _handlePreviewXml() async {
    setState(() => _isLoading = true);
    try {
      final xml = await _service.previewXml(_settings);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('TALLY XML PREVIEW', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(xml, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
            ),
          ],
        ),
      );
    } on TallyExportException catch (e) {
      if (!mounted) return;
      ToastService.show(title: 'Preview failed', message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePushToTally() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'PUSH TO TALLY',
      message: 'Push these vouchers directly into Tally? Make sure TallyPrime is open with the gateway enabled (port 9000).',
      confirmLabel: 'OK',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFFD97706),
    );
    if (confirmed != true) return;

    setState(() => _isPushing = true);
    try {
      final result = await _service.pushToTally(_settings);
      if (!mounted) return;
      if (result.isSuccess) {
        ToastService.show(
          title: 'Sync Complete',
          message: result.message.isNotEmpty ? result.message : 'Vouchers pushed to TallyPrime.',
          type: ToastType.success,
        );
      } else if (result.isOffline) {
        ToastService.show(
          title: 'Tally Not Reachable',
          message: result.message,
          type: ToastType.error,
        );
        await _handleDownloadXml();
      } else {
        ToastService.show(title: 'Push Failed', message: result.message, type: ToastType.error);
      }
    } on TallyExportException catch (e) {
      if (!mounted) return;
      ToastService.show(title: 'Push Failed', message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isPushing = false);
    }
  }

  String _formatCurrency(double value) {
    final rounded = value.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromEnd = str.length - i;
      buffer.write(str[i]);
      if (posFromEnd > 1 && posFromEnd <= 3) continue;
      if (posFromEnd > 3 && (posFromEnd - 3) % 2 == 0) buffer.write(',');
    }
    return '₹$buffer';
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  double get _totalVoucherValue =>
      _applications.fold(0.0, (sum, a) => sum + a.invoiceAmount);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 14.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 1. Top Inline Header (No Redundant AppBar) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TALLY VOUCHER EXPORT',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 24,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF1E3A8A),
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'POST CUSTOMER PURCHASES TO TALLY AS SALES VOUCHERS',
                            style: TextStyle(
                              fontSize: isMobile ? 8.5 : 10,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF94A3B8).withOpacity(0.9),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _isLoading ? null : _load,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.kBorder),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3A8A)))
                            : const Icon(Icons.refresh, color: AppColors.kTextMuted, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // --- 2. Error Banner ---
                if (_errorMessage != null) ...[
                  _buildErrorBanner(_errorMessage!),
                  const SizedBox(height: 16),
                ],

                // --- 3. Responsive Main Layout ---
                LayoutBuilder(
                  builder: (context, constraints) {
                    Widget statsAndForm = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStatSection(isMobile: isMobile, isTablet: isTablet),
                        const SizedBox(height: 20),
                        _buildTallySettingsForm(isMobile: isMobile),
                      ],
                    );

                    Widget dataTable = _buildDataTable(isMobile: isMobile);

                    if (isMobile || isTablet) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          statsAndForm,
                          const SizedBox(height: 24),
                          dataTable,
                        ],
                      );
                    }

                    // Desktop view (2-Column split)
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: statsAndForm),
                        const SizedBox(width: 24),
                        Expanded(flex: 7, child: dataTable),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SECTION BUILDERS
  // --------------------------------------------------------------------------

Widget _buildStatSection({required bool isMobile, required bool isTablet}) {
    final appsCard = StatCard(
      label: 'APPLICATIONS',
      value: '${_applications.length}',
      icon: Icons.description,
      color: const Color(0xFF3B82F6),
      badgeText: 'TOTAL',
      backgroundColor: const Color(0xFFF0F7FF),
      borderColor: const Color(0xFFBFDBFE),
      badgeBackgroundColor: const Color(0xFFDBEAFE),
      badgeTextColor: const Color(0xFF1D4ED8),
    );

    final totalValCard = StatCard(
      label: 'TOTAL VOUCHER VALUE',
      value: _formatCurrency(_totalVoucherValue),
      icon: Icons.monetization_on,
      color: AppColors.goldColor,
      badgeText: 'VALUE',
      backgroundColor: AppColors.goldBg,
      borderColor: AppColors.goldBorder,
      badgeBackgroundColor: AppColors.goldBadgeBg,
      badgeTextColor: AppColors.goldColor,
    );

    final voucherTypeCard = StatCard(
      label: 'VOUCHER TYPE',
      value: _selectedVoucherType,
      icon: Icons.receipt_long,
      color: const Color(0xFF1E3A8A),
      badgeText: _selectedVoucherType.toUpperCase(),
      backgroundColor: const Color(0xFFF8FAFC),
      borderColor: const Color(0xFFE2E8F0),
      badgeBackgroundColor: const Color(0xFFEDF2F7),
      badgeTextColor: const Color(0xFF1E3A8A),
    );

    // Mobile View: 2 cards in Row 1 (Applications & Voucher Type), 1 full-width card in Row 2 (Total Voucher Value)
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: appsCard),
              const SizedBox(width: 12),
              Expanded(child: voucherTypeCard),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: totalValCard,
          ),
        ],
      );
    }

    // Tablet & Desktop View: All 3 cards side-by-side
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: appsCard,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: totalValCard,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: voucherTypeCard,
          ),
        ),
      ],
    );
  }

  Widget _buildTallySettingsForm({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 20 : 32),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.account_balance, color: Color(0xFFFBBF24), size: 18),
              ),
              const SizedBox(width: 14),
              const Text(
                'TALLY SETTINGS',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInputField(label: 'TALLY COMPANY NAME', controller: _companyNameController, hintText: 'Blank = currently open company', prefixIcon: Icons.domain),
          const SizedBox(height: 14),
          _buildInputField(label: 'SALES LEDGER', controller: _salesLedgerController, prefixIcon: Icons.menu_book),
          const SizedBox(height: 14),
          _buildDropdownField('VOUCHER TYPE', _selectedVoucherType, _voucherTypes, (val) => setState(() => _selectedVoucherType = val!)),
          const SizedBox(height: 14),
          _buildDropdownField('STATUS FILTER', _selectedStatusFilter, _statusFilters, (val) {
            setState(() => _selectedStatusFilter = val!);
            _load();
          }),
          const SizedBox(height: 14),
          _buildInputField(label: 'TALLY GATEWAY (PORT)', controller: _gatewayController, isBold: true),
          const SizedBox(height: 24),
          
          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applications.isEmpty ? null : _handleDownloadXml,
              icon: const Icon(Icons.download, size: 16),
              label: const Text('DOWNLOAD TALLY XML', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_applications.isEmpty || _isPushing) ? null : _handlePushToTally,
              icon: _isPushing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.share, size: 16),
              label: Text(_isPushing ? 'PUSHING...' : 'PUSH TO TALLY', style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _applications.isEmpty ? null : _handlePreviewXml,
              icon: const Icon(Icons.preview, size: 16),
              label: const Text('PREVIEW XML', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A8A),
                side: const BorderSide(color: AppColors.kBorder),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable({required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 20 : 32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CASHBACK APPLICATIONS',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), letterSpacing: 0.8),
                ),
                Text(
                  '${_applications.length} RECORD(S)',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.9), letterSpacing: 0.8),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.kBorder),
          if (_isLoading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: AppLoader()))
          else if (_applications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text('NO APPLICATIONS FOUND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1), letterSpacing: 2)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: isMobile ? 650 : MediaQuery.of(context).size.width * 0.5),
                child: DataTable(
                  columnSpacing: isMobile ? 18 : 28,
                  headingRowHeight: 48,
                  dataRowMinHeight: 64,
                  dataRowMaxHeight: 64,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  dividerThickness: 1,
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 9.5, letterSpacing: 1.2),
                  columns: const [
                    DataColumn(label: Text('VOUCHER')),
                    DataColumn(label: Text('CUSTOMER')),
                    DataColumn(label: Text('PRODUCT')),
                    DataColumn(label: Text('DATE')),
                    DataColumn(label: Text('AMOUNT')),
                    DataColumn(label: Text('STATUS')),
                  ],
                  rows: _applications.map((a) {
                    return DataRow(cells: [
                      DataCell(Text(a.voucherId, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 12))),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.customerName, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 12.5)),
                            Text(a.customerEmail ?? '—', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
                          ],
                        ),
                      ),
                      DataCell(Text(a.purchasedProduct ?? '—', style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 11.5))),
                      DataCell(Text(_formatDate(a.applicationDate ?? a.purchaseDate), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
                      DataCell(Text(_formatCurrency(a.invoiceAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFFDE68A))),
                          child: Text(a.status.toUpperCase(), style: const TextStyle(color: Color(0xFFD97706), fontSize: 8.5, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // INPUT FORM COMPONENTS
  // --------------------------------------------------------------------------

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.w600))),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFFB91C1C)),
            onPressed: () => setState(() => _errorMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

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
        Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            fontStyle: isBold ? FontStyle.italic : FontStyle.normal,
            color: const Color(0xFF1E3A8A),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.kTextMuted, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic, fontSize: 12),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFFCBD5E1), size: 18) : null,
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          icon: const Icon(Icons.unfold_more, color: Color(0xFF1E3A8A), size: 18),
          isExpanded: true,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
          decoration: InputDecoration(
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(),
        ),
      ],
    );
  }
}