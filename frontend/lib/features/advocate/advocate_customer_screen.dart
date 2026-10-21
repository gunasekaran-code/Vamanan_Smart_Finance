import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/advocate_customer_model.dart';
import '../../services/advocate_customer_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class CustomerDirectoryScreen extends StatefulWidget {
  const CustomerDirectoryScreen({super.key});

  @override
  State<CustomerDirectoryScreen> createState() =>
      _CustomerDirectoryScreenState();
}

class _CustomerDirectoryScreenState extends State<CustomerDirectoryScreen> {
  final CustomerDirectoryService _service = CustomerDirectoryService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<CustomerKycModel> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final customers = await _service.fetchCustomers();
      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<CustomerKycModel> get _filteredCustomers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _customers;
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.email.toLowerCase().contains(query) ||
            c.displayId.toLowerCase().contains(query))
        .toList();
  }

  void _openKycModal(CustomerKycModel customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InspectKycModal(
        customer: customer,
        service: _service,
        onStatusChanged: (newStatus) {
          setState(() {
            customer.kycStatus = newStatus;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null,
      children: [
        // 1. Header
        const Text(
          'CUSTOMER DIRECTORY',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Color(0xFF1B233A), // Dark Navy
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),

        // 2. Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'SEARCH CUSTOMERS...',
            hintStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.0),
            prefixIcon:
                const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 2)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 2)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.kPrimary, width: 2)),
          ),
        ),
        const SizedBox(height: 32),

        // 3. Customer List
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
                  Text('Failed to load customers:\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _loadCustomers, child: const Text('Retry')),
                ],
              ),
            ),
          )
        else if (_filteredCustomers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60.0),
            child: Center(
              child: Text(
                'NO CUSTOMERS FOUND',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFCBD5E1),
                    letterSpacing: 1.5),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredCustomers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final customer = _filteredCustomers[index];
              return _buildCustomerCard(customer);
            },
          ),
      ],
    );
  }

  Widget _buildCustomerCard(CustomerKycModel customer) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Avatar & Info
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B233A), // Dark Navy
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0] : '?',
                  style: const TextStyle(
                      color: AppColors.goldColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 16,
                          color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.email,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Middle Row: Status & ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('KYC STATUS',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFCBD5E1),
                          letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  _buildStatusBadge(customer.kycStatus),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('CUSTOMER ID',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFCBD5E1),
                          letterSpacing: 1.0)),
                  const SizedBox(height: 6),
                  Text(customer.displayId,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E293B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bottom Button
          InkWell(
            onTap: () => _openKycModal(customer),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.remove_red_eye_outlined,
                      size: 16, color: Color(0xFF94A3B8)),
                  SizedBox(width: 8),
                  Text(
                    'INSPECT CUSTOMER KYC',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.goldBadgeBg;
    Color text = AppColors.goldColor;

    if (status == 'KYC APPROVED') {
      bg = const Color(0xFFF0FDF4);
      text = const Color(0xFF16A34A);
    } else if (status == 'KYC REJECTED') {
      bg = const Color(0xFFFFFBEB);
      text = AppColors.goldColor; // Matching the image's rejected color
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status,
        style: TextStyle(
            color: text,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            fontSize: 10,
            letterSpacing: 0.5),
      ),
    );
  }
}

// ============================================================================
// INSPECT KYC MODAL (Bottom Sheet)
// ============================================================================
class _InspectKycModal extends StatefulWidget {
  final CustomerKycModel customer;
  final CustomerDirectoryService service;
  final ValueChanged<String> onStatusChanged;

  const _InspectKycModal({
    required this.customer,
    required this.service,
    required this.onStatusChanged,
  });

  @override
  State<_InspectKycModal> createState() => _InspectKycModalState();
}

class _InspectKycModalState extends State<_InspectKycModal> {
  bool _isSubmitting = false;

  Future<void> _handleApprove(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Approve KYC',
      message:
          'Are you sure you want to approve the KYC for ${widget.customer.name}? This will grant them full platform access.',
      confirmLabel: 'Approve',
      confirmButtonColor: AppColors.kSuccess,
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.service.approveKyc(widget.customer.id);
      widget.onStatusChanged('KYC APPROVED');
      if (context.mounted) Navigator.pop(context);
      ToastService.show(
          title: 'KYC Approved',
          message: '${widget.customer.name}\'s KYC has been approved.',
          type: ToastType.success);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ToastService.show(
          title: 'Approval Failed',
          message: e.toString(),
          type: ToastType.error);
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Reject KYC',
      message:
          'Are you sure you want to reject the KYC for ${widget.customer.name}? They will be notified to re-upload documents.',
      confirmLabel: 'Reject',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.service.rejectKyc(widget.customer.id);
      widget.onStatusChanged('KYC REJECTED');
      if (context.mounted) Navigator.pop(context);
      ToastService.show(
          title: 'KYC Rejected',
          message: '${widget.customer.name}\'s KYC has been rejected.',
          type: ToastType.error);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ToastService.show(
          title: 'Rejection Failed',
          message: e.toString(),
          type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    final hasDocument = customer.kycDocument.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 60), // Space from top of screen
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Modal Header
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B233A),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0] : '?',
                  style: const TextStyle(
                      color: AppColors.goldColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            fontSize: 20,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('CUSTOMER ID: ${customer.displayId}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 1.0)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF8FAFC)),
              )
            ],
          ),
          const SizedBox(height: 32),

          // 2. Customer Details Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC), // Light blue-grey
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.fingerprint, size: 16, color: Color(0xFF94A3B8)),
                    SizedBox(width: 8),
                    Text('CUSTOMER DETAILS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 1.0)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE2E8F0), thickness: 1.5),
                const SizedBox(height: 16),
                _buildDetailField('EMAIL ADDRESS', customer.email),
                const SizedBox(height: 16),
                _buildDetailField(
                    'REGISTRATION DATE', customer.registrationDate),
                const SizedBox(height: 16),
                const Text('KYC STATUS',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFCBD5E1),
                        letterSpacing: 1.0)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(customer.kycStatus,
                          style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              fontSize: 10,
                              letterSpacing: 0.5)),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. KYC Document Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB), // Light Yellow/Gold
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.goldBorder, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.contact_page_outlined,
                        size: 16, color: AppColors.goldColor),
                    SizedBox(width: 8),
                    Text('KYC DOCUMENT',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: AppColors.goldColor,
                            letterSpacing: 1.0)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.goldBorder, thickness: 1.5),
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        hasDocument
                            ? Icons.insert_drive_file
                            : Icons.insert_drive_file_outlined,
                        size: 48,
                        color: hasDocument
                            ? AppColors.goldColor
                            : const Color(0xFFCBD5E1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        // `kyc_document` on the backend only stores a
                        // path/filename, not a viewable URL — this shows
                        // that it exists rather than rendering it. Wire in
                        // your actual document base URL / viewer here once
                        // you have one.
                        hasDocument
                            ? 'DOCUMENT UPLOADED'
                            : 'NO DOCUMENT ATTACHED',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. Action Buttons
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : () => _handleApprove(context),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.how_to_reg, size: 18),
            label: const Text('APPROVE KYC',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    letterSpacing: 1.0)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _isSubmitting ? null : () => _handleReject(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6), // Blue text
              side: const BorderSide(color: Color(0xFFEFF6FF), width: 2),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('REJECT KYC',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    letterSpacing: 1.0)),
          ),
          // Safe area padding for bottom of screen
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFFCBD5E1),
                letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1E293B))),
      ],
    );
  }
}
