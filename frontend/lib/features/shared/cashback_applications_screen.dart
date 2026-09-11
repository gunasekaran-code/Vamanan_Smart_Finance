import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

// --- Data Model ---
class CashbackApplication {
  final String id;
  final String appNumber;
  final String customerName;
  final String customerId;
  final String email;
  final String phone;
  final String purchaseValue;
  final String purchasedProduct;
  final String productDetails;
  final String purchaseNote; // Optional auto-generated note
  final String dateOfPurchase;
  final String bankName;
  final String accountHolder;
  final String accountNo;
  final String ifscCode;
  final String bankBranch;
  final String status;
  
  // Extra details for the modal
  final String referralId;
  final String address;
  final String aadhaarNo;
  final String panNo;
  final String agentName;
  final String agentId;
  final String place;

  const CashbackApplication({
    required this.id,
    required this.appNumber,
    required this.customerName,
    required this.customerId,
    required this.email,
    required this.phone,
    required this.purchaseValue,
    required this.purchasedProduct,
    required this.productDetails,
    this.purchaseNote = '',
    required this.dateOfPurchase,
    required this.bankName,
    required this.accountHolder,
    required this.accountNo,
    required this.ifscCode,
    required this.bankBranch,
    required this.status,
    required this.referralId,
    required this.address,
    required this.aadhaarNo,
    required this.panNo,
    required this.agentName,
    required this.agentId,
    required this.place,
  });
}

// --- Main Screen ---
class CashbackApplicationsScreen extends StatefulWidget {
  const CashbackApplicationsScreen({super.key});

  @override
  State<CashbackApplicationsScreen> createState() => _CashbackApplicationsScreenState();
}

class _CashbackApplicationsScreenState extends State<CashbackApplicationsScreen> {
  // Mock data representing the varied row states in the image
  final List<CashbackApplication> _applications = [
    const CashbackApplication(
      id: '1',
      appNumber: '90',
      customerName: 'NANDHA KUMAR.M',
      customerId: 'VEVO65',
      email: 'n2348979@gmail.com',
      phone: '9788086424',
      purchaseValue: '₹8,40,000',
      purchasedProduct: 'GOLD',
      productDetails: 'Gold 40 gram',
      dateOfPurchase: '2026-05-05',
      bankName: 'UNION BANK OF INDIA',
      accountHolder: 'Nandha Kumar.M',
      accountNo: '520101250199757',
      ifscCode: 'UBIN0911658',
      bankBranch: 'KRISHNAGIRI BRANCH',
      status: 'PENDING REVIEW',
      referralId: 'VEVY1S6A',
      address: 'D.No.2/15A, PEDDATHALAPALLI, KRISHNAKIRI(POST), KRISHNAGIRI - 635001.',
      aadhaarNo: '[Aadhaar Redacted]', // Redacted for compliance
      panNo: 'CHZPN7192J',
      agentName: 'HARIHARAN.M',
      agentId: '—',
      place: 'Krishnagiri',
    ),
    const CashbackApplication(
      id: '2',
      appNumber: '91',
      customerName: 'NANDHA KUMAR.M',
      customerId: 'VEVO65',
      email: 'n2348979@gmail.com',
      phone: '9788086424',
      purchaseValue: '₹8,15,540',
      purchasedProduct: '40 GRAM(S) 24K GOLD',
      productDetails: '',
      purchaseNote: 'Auto-generated from order #61. Total paid ₹840,006.20 incl. GST ₹24,466.20. Cashback eligible ₹815,540.00 (GST excluded).',
      dateOfPurchase: '2026-08-26',
      bankName: '—',
      accountHolder: '—',
      accountNo: '—',
      ifscCode: '—',
      bankBranch: '—',
      status: 'PENDING REVIEW',
      referralId: 'VEVY1S6A',
      address: 'D.No.2/15A, PEDDATHALAPALLI, KRISHNAKIRI',
      aadhaarNo: '[Aadhaar Redacted]',
      panNo: 'CHZPN7192J',
      agentName: 'HARIHARAN.M',
      agentId: '—',
      place: 'Krishnagiri',
    ),
  ];

  Future<void> _handleProcessYield() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'PROCESS MONTHLY YIELD',
      message: "Process this month's cashback? This credits one monthly installment (10%) to every cycle that is due, and can only run ONCE per calendar month.",
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );

    if (confirmed == true) {
      ToastService.show(title: 'Success', message: 'Monthly yield processed.', type: ToastType.success);
    }
  }

  Future<void> _handleApprove(CashbackApplication app) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'APPROVE APPLICATION',
      message: 'Mark this cashback application as Approved?',
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );

    if (confirmed == true) {
      ToastService.show(title: 'Approved', message: 'Application has been approved.', type: ToastType.success);
    }
  }

  Future<void> _handleReject(CashbackApplication app) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'REJECT APPLICATION',
      message: 'Mark this cashback application as Rejected?',
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true) {
      ToastService.show(title: 'Rejected', message: 'Application has been rejected.', type: ToastType.info);
    }
  }

  void _showApplicationDetails(CashbackApplication app) {
    showDialog(
      context: context,
      builder: (context) => ApplicationDetailsModal(
        app: app,
        onApprove: () {
          Navigator.pop(context);
          _handleApprove(app);
        },
        onReject: () {
          Navigator.pop(context);
          _handleReject(app);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, outerConstraints) {
            final isMobile = outerConstraints.maxWidth < 600;
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.kBorder),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search users, orders, assets...',
                        hintStyle: const TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppColors.kTextMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Process Monthly Yield Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _handleProcessYield,
                      icon: const Icon(Icons.bolt, size: 18),
                      label: Text(
                        'PROCESS MONTHLY YIELD',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Card Table
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppColors.kBorder),
                    ),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;

                        final titleSection = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CASHBACK APPLICATIONS',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'CUSTOMER-SUBMITTED CASHBACK CLAIM APPLICATIONS',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5),
                            ),
                          ],
                        );

                        final badgeSection = Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), border: Border.all(color: const Color(0xFFFDE68A)), borderRadius: BorderRadius.circular(24)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 8, color: Color(0xFFD97706)),
                              SizedBox(width: 8),
                              Text('86 PENDING REVIEW', style: TextStyle(color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        );

                        return Padding(
                          padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                          child: isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    titleSection,
                                    const SizedBox(height: 16),
                                    badgeSection,
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: titleSection),
                                    badgeSection,
                                  ],
                                ),
                        );
                      },
                    ),
                    Container(height: 1, color: AppColors.kBorder),

                    // Scrollable Table Data
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 32,
                        headingRowHeight: 56,
                        dataRowMinHeight: 180, // Taller rows for multi-line boxes
                        dataRowMaxHeight: 180,
                        dividerThickness: 1,
                        headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 12, letterSpacing: 2),
                        columns: const [
                          DataColumn(label: Text('CUSTOMER')),
                          DataColumn(label: Text('PURCHASE')),
                          DataColumn(label: Text('BANK / PAYMENT')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: _applications.map((app) {
                          return DataRow(
                            cells: [
                              DataCell(_buildCustomerCell(app)),
                              DataCell(_buildPurchaseCell(app)),
                              DataCell(_buildBankCell(app)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: const Color(0xFFFFFBEB), border: Border.all(color: const Color(0xFFFDE68A)), borderRadius: BorderRadius.circular(8)),
                                  child: Text(app.status, style: const TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                                ),
                              ),
                              DataCell(_buildActionsCell(app)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Cell Builders for cleaner layout
  Widget _buildCustomerCell(CashbackApplication app) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Text(app.customerName.substring(0, 1).toUpperCase(), style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.customerName, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 14)),
            Text(app.customerId, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706), fontSize: 11)),
            const SizedBox(height: 4),
            Text(app.email, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            Text(app.phone, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildPurchaseCell(CashbackApplication app) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(app.purchaseValue, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 15)),
          const SizedBox(height: 2),
          Text(app.purchasedProduct, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13)),
          const SizedBox(height: 8),
          if (app.purchaseNote.isNotEmpty)
             Container(
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.kBorder)),
               child: Text(app.purchaseNote, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.4), maxLines: 4, overflow: TextOverflow.ellipsis),
             )
          else if (app.productDetails.isNotEmpty)
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.kBorder)),
               child: Text(app.productDetails, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
             ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Color(0xFFcbd5e1)),
              const SizedBox(width: 4),
              Text(app.dateOfPurchase, style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBankCell(CashbackApplication app) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(app.bankName, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 12)),
          const SizedBox(height: 8),
          Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.kBorder)),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('A/C ${app.accountNo}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                 Text('IFSC ${app.ifscCode}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                 if (app.bankBranch != '—') Text(app.bankBranch, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
               ],
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCell(CashbackApplication app) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showApplicationDetails(app),
          icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
          label: const Text('VIEW', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            side: const BorderSide(color: AppColors.kBorder),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _handleApprove(app),
          icon: const Icon(Icons.check_circle_outline, size: 14),
          label: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _handleReject(app),
          icon: const Icon(Icons.cancel_outlined, size: 14),
          label: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF94A3B8),
            side: const BorderSide(color: AppColors.kBorder),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// --- Detail View Modal ---
class ApplicationDetailsModal extends StatelessWidget {
  final CashbackApplication app;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const ApplicationDetailsModal({
    super.key,
    required this.app,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 800), // Cap width on wide screens, shrink on mobile
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF1E3A8A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text('APPLICATION #${app.appNumber} · ${app.customerId}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFFBBF24))),
                    ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Modal Content (Scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('APPLICANT DETAILS'),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDetailField('CUSTOMER NAME', app.customerName)),
                        Expanded(child: _buildDetailField('CUSTOMER ID', app.customerId)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDetailField('REFERRAL ID', app.referralId)),
                        Expanded(child: _buildDetailField('EMAIL', app.email)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDetailField('PHONE', app.phone)),
                        Expanded(child: _buildDetailField('ADDRESS', app.address)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDetailField('AADHAAR NO', app.aadhaarNo)),
                        Expanded(child: _buildDetailField('PAN NO', app.panNo)),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('PURCHASE DETAILS'),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDetailField('TOTAL PURCHASE VALUE', app.purchaseValue)),
                        Expanded(child: _buildDetailField('PURCHASED PRODUCT', app.purchasedProduct)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDetailField('DATE OF PURCHASE', app.dateOfPurchase)),
                        Expanded(child: _buildDetailField('PRODUCT DETAILS', app.productDetails.isNotEmpty ? app.productDetails : '—')),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('PAYMENT DETAILS'),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDetailField('ACCOUNT HOLDER', app.accountHolder)),
                        Expanded(child: _buildDetailField('ACCOUNT NO', app.accountNo)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDetailField('IFSC CODE', app.ifscCode)),
                        Expanded(child: _buildDetailField('BANK NAME', app.bankName)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDetailField('BANK BRANCH', app.bankBranch)),
                        Expanded(child: const SizedBox()),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('AGENT / DECLARATION'),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDetailField('AGENT NAME', app.agentName)),
                        Expanded(child: _buildDetailField('AGENT ID', app.agentId)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDetailField('PLACE', app.place)),
                        Expanded(child: _buildDetailField('DATE', app.dateOfPurchase)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Modal Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.kBorder))),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.kBorder), padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {}, // Print Logic
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('PRINT', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB48A28), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), foregroundColor: const Color(0xFF64748B), padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0),
                      child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: const Color(0xFFD97706)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706), letterSpacing: 2)),
      ],
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
        ],
      ),
    );
  }
}