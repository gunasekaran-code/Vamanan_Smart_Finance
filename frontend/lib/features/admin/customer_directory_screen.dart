import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

// --- Dummy Data Model ---
class CustomerKyc {
  final String id;
  final String name;
  final String email;
  String kycStatus; // KYC PENDING, KYC REJECTED, KYC APPROVED
  final String registrationDate;

  CustomerKyc({
    required this.id,
    required this.name,
    required this.email,
    required this.kycStatus,
    required this.registrationDate,
  });
}

class CustomerDirectoryScreen extends StatefulWidget {
  const CustomerDirectoryScreen({super.key});

  @override
  State<CustomerDirectoryScreen> createState() => _CustomerDirectoryScreenState();
}

class _CustomerDirectoryScreenState extends State<CustomerDirectoryScreen> {
  // Dummy Data matching the screenshot exactly
  final List<CustomerKyc> _customers = [
    CustomerKyc(id: 'VEV099', name: 'SARANYA VENKAT', email: 'DSARANGANGA@GMAIL.COM', kycStatus: 'KYC REJECTED', registrationDate: '15/8/2026'),
    CustomerKyc(id: 'VEV098', name: 'ARUMUGAM PONNUSAMY', email: 'ARUMUGAMMONISH123@GMAIL.COM', kycStatus: 'KYC REJECTED', registrationDate: '14/8/2026'),
    CustomerKyc(id: 'VEV097', name: 'VASUNDHARA', email: 'SUNDARENTERPRISES17@GMAIL.COM', kycStatus: 'KYC PENDING', registrationDate: '12/8/2026'),
    CustomerKyc(id: 'VEV096', name: 'VIGNESH', email: 'VIKY009426@GMAIL.COM', kycStatus: 'KYC PENDING', registrationDate: '10/8/2026'),
  ];

  void _openKycModal(CustomerKyc customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InspectKycModal(
        customer: customer,
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
          decoration: InputDecoration(
            hintText: 'SEARCH CUSTOMERS...',
            hintStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, color: Color(0xFF94A3B8), letterSpacing: 1.0),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kPrimary, width: 2)),
          ),
        ),
        const SizedBox(height: 32),

        // 3. Customer List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _customers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            final customer = _customers[index];
            return _buildCustomerCard(customer);
          },
        ),
      ],
    );
  }

  Widget _buildCustomerCard(CustomerKyc customer) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                alignment: Alignment.center,
                child: Text(
                  customer.name[0],
                  style: const TextStyle(color: AppColors.goldColor, fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.email,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10, color: Color(0xFF94A3B8), letterSpacing: 0.5),
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
                  const Text('KYC STATUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1), letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  _buildStatusBadge(customer.kycStatus),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('CUSTOMER ID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1), letterSpacing: 1.0)),
                  const SizedBox(height: 6),
                  Text(customer.id, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E293B))),
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
                  Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF94A3B8)),
                  SizedBox(width: 8),
                  Text(
                    'INSPECT CUSTOMER KYC',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.0),
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
      bg = const Color(0xFFF0FDF4); text = const Color(0xFF16A34A);
    } else if (status == 'KYC REJECTED') {
      bg = const Color(0xFFFFFBEB); text = AppColors.goldColor; // Matching the image's rejected color
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status,
        style: TextStyle(color: text, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }
}


// ============================================================================
// INSPECT KYC MODAL (Bottom Sheet)
// ============================================================================
class _InspectKycModal extends StatelessWidget {
  final CustomerKyc customer;
  final ValueChanged<String> onStatusChanged;

  const _InspectKycModal({required this.customer, required this.onStatusChanged});

  void _handleApprove(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Approve KYC',
      message: 'Are you sure you want to approve the KYC for ${customer.name}? This will grant them full platform access.',
      confirmLabel: 'Approve',
      confirmButtonColor: AppColors.kSuccess,
    );

    if (confirmed == true) {
      onStatusChanged('KYC APPROVED');
      Navigator.pop(context);
      ToastService.show(title: 'KYC Approved', message: '${customer.name}\'s KYC has been approved.', type: ToastType.success);
    }
  }

  void _handleReject(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Reject KYC',
      message: 'Are you sure you want to reject the KYC for ${customer.name}? They will be notified to re-upload documents.',
      confirmLabel: 'Reject',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true) {
      onStatusChanged('KYC REJECTED');
      Navigator.pop(context);
      ToastService.show(title: 'KYC Rejected', message: '${customer.name}\'s KYC has been rejected.', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                alignment: Alignment.center,
                child: Text(
                  customer.name[0],
                  style: const TextStyle(color: AppColors.goldColor, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 20, color: Color(0xFF1E293B), letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('CUSTOMER ID: ${customer.id}', style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFFF8FAFC)),
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
                    Text('CUSTOMER DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE2E8F0), thickness: 1.5),
                const SizedBox(height: 16),
                
                _buildDetailField('EMAIL ADDRESS', customer.email),
                const SizedBox(height: 16),
                _buildDetailField('REGISTRATION DATE', customer.registrationDate),
                const SizedBox(height: 16),
                
                const Text('KYC STATUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1), letterSpacing: 1.0)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
                      child: Text(customer.kycStatus, style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10, letterSpacing: 0.5)),
                    ),
                    const SizedBox(width: 8),
                    if (customer.kycStatus == 'KYC REJECTED')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: const [
                            Icon(Icons.cancel_outlined, size: 12, color: Color(0xFF3B82F6)),
                            SizedBox(width: 4),
                            Text('REJECTED', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 9, letterSpacing: 0.5)),
                          ],
                        ),
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
                    Icon(Icons.contact_page_outlined, size: 16, color: AppColors.goldColor),
                    SizedBox(width: 8),
                    Text('KYC DOCUMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.goldColor, letterSpacing: 1.0)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.goldBorder, thickness: 1.5),
                const SizedBox(height: 32),
                
                Center(
                  child: Column(
                    children: const [
                      Icon(Icons.insert_drive_file_outlined, size: 48, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 16),
                      Text('NO DOCUMENT ATTACHED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          
          const Spacer(), // Pushes buttons to the bottom

          // 4. Action Buttons
          ElevatedButton.icon(
            onPressed: () => _handleApprove(context),
            icon: const Icon(Icons.how_to_reg, size: 18),
            label: const Text('APPROVE KYC', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 1.0)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _handleReject(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6), // Blue text
              side: const BorderSide(color: Color(0xFFEFF6FF), width: 2),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('REJECT KYC', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 1.0)),
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
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1), letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E293B))),
      ],
    );
  }
}