import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/kyc_registry_model.dart';
import '../../services/kyc_registry_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class KycRegistryScreen extends StatefulWidget {
  const KycRegistryScreen({super.key});

  @override
  State<KycRegistryScreen> createState() => _KycRegistryScreenState();
}

class _KycRegistryScreenState extends State<KycRegistryScreen> {
  final _service = KycRegistryService();

  List<KycCustomer> _customers = [];
  bool _isLoading = true;
  bool _isProcessingYield = false;
  String? _errorMessage;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final customers = await _service.fetchPendingKyc();
      setState(() => _customers = customers);
    } on KycRegistryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleProcessYield() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'PROCESS MONTHLY YIELD',
      message: "Process this month's cashback? This credits one monthly installment (10%) to every cycle that is due, and can only run ONCE per calendar month.",
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );
    if (confirmed != true) return;

    setState(() => _isProcessingYield = true);
    try {
      final result = await _service.processMonthlyYield();
      ToastService.show(
        title: result.success ? 'Success' : 'Failed',
        message: result.message.isNotEmpty ? result.message : 'Monthly yield processed successfully.',
        type: result.success ? ToastType.success : ToastType.error,
      );
    } on KycRegistryException catch (e) {
      ToastService.show(title: 'Failed', message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isProcessingYield = false);
    }
  }

  Future<void> _handleApprove(KycCustomer customer) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'APPROVE KYC',
      message: 'Approve the KYC verification for ${customer.name}?',
      confirmLabel: 'APPROVE',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFFD97706),
    );
    if (confirmed != true) return;

    setState(() => _busyIds.add(customer.id));
    try {
      await _service.approve(customer.id);
      if (!mounted) return;
      setState(() => _customers.removeWhere((c) => c.id == customer.id));
      ToastService.show(title: 'KYC Approved', message: '${customer.name} has been verified.', type: ToastType.success);
    } on KycRegistryException catch (e) {
      ToastService.show(title: 'Approve Failed', message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _busyIds.remove(customer.id));
    }
  }

  Future<void> _handleReject(KycCustomer customer) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'REJECT KYC',
      message: 'Reject the KYC verification for ${customer.name}?',
      confirmLabel: 'REJECT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF3B82F6),
    );
    if (confirmed != true) return;

    setState(() => _busyIds.add(customer.id));
    try {
      await _service.reject(customer.id);
      if (!mounted) return;
      setState(() => _customers.removeWhere((c) => c.id == customer.id));
      ToastService.show(title: 'KYC Rejected', message: '${customer.name} has been rejected.', type: ToastType.info);
    } on KycRegistryException catch (e) {
      ToastService.show(title: 'Reject Failed', message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _busyIds.remove(customer.id));
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search users, orders, assets...',
                      hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  _buildErrorBanner(_errorMessage!),
                  const SizedBox(height: 16),
                ],

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessingYield ? null : _handleProcessYield,
                    icon: _isProcessingYield
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.bolt, size: 16, color: Colors.white),
                    label: Text(
                      _isProcessingYield ? 'PROCESSING...' : 'PROCESS MONTHLY YIELD',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INSTITUTIONAL KYC REGISTRY',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'IDENTITY VERIFICATION PROTOCOL FOR HIGH-NET-WORTH INDIVIDUALS',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8), letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          '${_customers.length} AWAITING VERIFICATION',
                          style: const TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(child: AppLoader()),
                  )
                else if (_customers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: Text(
                        'NO PENDING KYC SUBMISSIONS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8), letterSpacing: 1.5),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _customers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final customer = _customers[index];
                      return _KycCard(
                        customer: customer,
                        isBusy: _busyIds.contains(customer.id),
                        onApprove: () => _handleApprove(customer),
                        onReject: () => _handleReject(customer),
                        formatDate: _formatDate,
                      );
                    },
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13))),
          IconButton(icon: const Icon(Icons.close, size: 18, color: Color(0xFFB91C1C)), onPressed: () => setState(() => _errorMessage = null)),
        ],
      ),
    );
  }
}

class _KycCard extends StatelessWidget {
  final KycCustomer customer;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final String Function(DateTime?) formatDate;

  const _KycCard({
    required this.customer,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: Text(
                    customer.name.isNotEmpty ? customer.name.substring(0, 1).toUpperCase() : '?',
                    style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 16, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(customer.email, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.kBorder),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SUBMISSION NODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      Text(formatDate(customer.submissionDate), style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 14)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(6)),
                        child: Text(customer.statusLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706), fontSize: 10)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DIGITAL CREDENTIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      Text(customer.credentialLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.kBorder),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy ? null : onApprove,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      backgroundColor: const Color(0xFFFFFBEB),
                      side: const BorderSide(color: Color(0xFFFDE68A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isBusy
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      backgroundColor: const Color(0xFFEFF6FF),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isBusy
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('REJECT', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}