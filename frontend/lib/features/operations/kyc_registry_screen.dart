import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

// --- Data Model ---
class KycCustomer {
  final String id;
  final String name;
  final String email;
  final String submissionDate;
  final String status;
  final String credential;

  const KycCustomer({
    required this.id,
    required this.name,
    required this.email,
    required this.submissionDate,
    required this.status,
    required this.credential,
  });
}

class KycRegistryScreen extends StatefulWidget {
  const KycRegistryScreen({super.key});

  @override
  State<KycRegistryScreen> createState() => _KycRegistryScreenState();
}

class _KycRegistryScreenState extends State<KycRegistryScreen> {
  // Mock data matching the design image
  final List<KycCustomer> _customers = [
    const KycCustomer(
      id: '1',
      name: 'SARANYA VENKAT',
      email: 'dsaranganga@gmail.com',
      submissionDate: '15 Aug 2026',
      status: 'PENDING REVIEW',
      credential: 'NODE: NO DATA',
    ),
    const KycCustomer(
      id: '2',
      name: 'ARUMUGAM PONNUSAMY',
      email: 'arumugammonish12@gmail.com',
      submissionDate: '11 Aug 2026',
      status: 'PENDING REVIEW',
      credential: 'NODE: NO DATA',
    ),
    const KycCustomer(
      id: '3',
      name: 'VASUNDHARA',
      email: 'sundarenterprises17@gmail.com',
      submissionDate: '11 Aug 2026',
      status: 'PENDING REVIEW',
      credential: 'NODE: NO DATA',
    ),
    const KycCustomer(
      id: '4',
      name: 'VIGNESH',
      email: 'viky009426@gmail.com',
      submissionDate: '11 Aug 2026',
      status: 'PENDING REVIEW',
      credential: 'NODE: NO DATA',
    ),
    const KycCustomer(
      id: '5',
      name: 'JEEVITHA',
      email: 'narasimmanjeevi@gmail.com',
      submissionDate: '11 Aug 2026',
      status: 'PENDING REVIEW',
      credential: 'NODE: NO DATA',
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

    if (confirmed == true && mounted) {
      ToastService.show(title: 'Success', message: 'Monthly yield processed successfully.', type: ToastType.success);
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

    if (confirmed == true && mounted) {
      ToastService.show(title: 'KYC Approved', message: '${customer.name} has been verified.', type: ToastType.success);
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

    if (confirmed == true && mounted) {
      ToastService.show(title: 'KYC Rejected', message: '${customer.name} has been rejected.', type: ToastType.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Global Search Bar ---
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

              // --- 2. Process Monthly Yield Button ---
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _handleProcessYield,
                  icon: const Icon(Icons.bolt, size: 16, color: Colors.white),
                  label: const Text('PROCESS MONTHLY YIELD', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. Header Title Area ---
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
                        color: const Color(0xFFFFFBEB), // Light amber background
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Text(
                        '97 AWAITING VERIFICATION',
                        style: TextStyle(
                          color: Color(0xFFD97706), // Amber text
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- 4. Card List ---
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _customers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _KycCard(
                    customer: _customers[index],
                    onApprove: () => _handleApprove(_customers[index]),
                    onReject: () => _handleReject(_customers[index]),
                  );
                },
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CLEAN KYC CARD WIDGET
// ============================================================================
class _KycCard extends StatelessWidget {
  final KycCustomer customer;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _KycCard({
    required this.customer,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER: Avatar & Name ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A), // Deep Navy
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    customer.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFFBBF24), // Gold Text
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
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
                          color: Color(0xFF1E3A8A),
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer.email,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8), // Slate Gray
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: AppColors.kBorder),

          // --- BODY: Details ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SUBMISSION NODE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        customer.submissionDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E3A8A),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          customer.status,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFFD97706),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DIGITAL CREDENTIAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        customer.credential,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFCBD5E1), // Light muted color from your original design
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.kBorder),

          // --- FOOTER: Action Buttons ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onApprove,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      backgroundColor: const Color(0xFFFFFBEB),
                      side: const BorderSide(color: Color(0xFFFDE68A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      backgroundColor: const Color(0xFFEFF6FF),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
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