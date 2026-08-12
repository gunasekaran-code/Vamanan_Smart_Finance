import 'package:flutter/material.dart';
import '../../widgets/app_toast.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';

class VerificationItem {
  final String id;
  final String customerName;
  final String phone;
  final String planName;
  final String installment;
  final String amount;
  final String transactionId;
  final String dateTime;
  final String status; // 'APPROVED', 'REJECTED', 'PENDING'
  final String? proofImageUrl;

  const VerificationItem({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.planName,
    required this.installment,
    required this.amount,
    required this.transactionId,
    required this.dateTime,
    required this.status,
    this.proofImageUrl,
  });
}

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  // TODO: Connect to backend API GET /verifications/pending
  final List<VerificationItem> _verifications = const [
    VerificationItem(
      id: '1',
      customerName: 'Jessica',
      phone: '9512364870',
      planName: 'Gold',
      installment: 'Inst #1',
      amount: '₹1000.00',
      transactionId: '409823126785',
      dateTime: '10 Apr, 10:52 AM',
      status: 'REJECTED',
    ),
    VerificationItem(
      id: '2',
      customerName: 'Roki',
      phone: '9786204074',
      planName: 'Gold',
      installment: 'Inst #3',
      amount: '₹1000.00',
      transactionId: '409823126781',
      dateTime: '09 Apr, 05:41 PM',
      status: 'APPROVED',
    ),
    VerificationItem(
      id: '3',
      customerName: 'VEERASAMY.K',
      phone: '9876543210',
      planName: 'Loan LN-2026-0005',
      installment: 'EMI #4',
      amount: '₹1,250.00',
      transactionId: '409823126790',
      dateTime: '11 Apr, 02:15 PM',
      status: 'PENDING',
    ),
  ];

  void _showProofModal(BuildContext context, VerificationItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.kSurface,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Payment Screenshot - ${item.customerName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kTextDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Screenshot Preview Container
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.kBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Center(
                  child: item.proofImageUrl != null
                      ? Image.network(item.proofImageUrl!, fit: BoxFit.cover)
                      : Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.help_outline,
                            size: 28,
                            color: Colors.blue,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Transaction Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.kBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transaction ID',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.kTextMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.transactionId,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kTextDark,
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
                            'Submitted At',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.kTextMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.dateTime,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kTextDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C757D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final (bg, fg) = switch (status.toUpperCase()) {
      'APPROVED' => (AppColors.kPrimaryLight, AppColors.kPrimary),
      'REJECTED' => (const Color(0xFFFEE2E2), AppColors.kDanger),
      _ => (const Color(0xFFFEF3C7), AppColors.kWarning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Payment Verifications',
      subtitle:
          'Review and approve digital payment proofs submitted by customers.',
      children: [
        // Top Refresh Bar
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: OutlinedButton.icon(

              //----- WITHOUT TOAST SERVICE -----
            // onPressed: () {},
            //   icon: const Icon(Icons.refresh, size: 16),
            //   label: const Text('Refresh'),
            //   style: OutlinedButton.styleFrom(
            //     foregroundColor: AppColors.kTextDark,
            //     side: const BorderSide(color: AppColors.kBorder),
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            //     backgroundColor: AppColors.kSurface,
            //   ),
            // ),
            //----- WITH TOAST SERVICE ----
            onPressed: () {
                ToastService.show(
                  title: 'Data Refreshed',
                  message: 'Payment verifications have been updated.',
                  type: ToastType.info,
                  duration: const Duration(seconds: 3),
                );
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.kTextDark,
                side: const BorderSide(color: AppColors.kBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: AppColors.kSurface,
              ),
            ),



          ),
        ),
        for (final item in _verifications)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.kBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: User details & Status chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.kPrimaryLight,
                      child: Icon(
                        Icons.person_add_alt_1_outlined,
                        color: AppColors.kPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.customerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kTextDark,
                            ),
                          ),
                          Text(
                            item.phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.kTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(item.status),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Payment Details & Transaction Info Grid
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PAYMENT DETAILS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kTextMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.kTextDark,
                              ),
                              children: [
                                TextSpan(
                                  text: '${item.planName}\n',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: '${item.installment} | Amount: ',
                                  style: const TextStyle(
                                      color: AppColors.kTextMuted),
                                ),
                                TextSpan(
                                  text: item.amount,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
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
                            'TRANSACTION INFO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kTextMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.kBackground,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.transactionId,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.dateTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.kTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Actions: View Proof Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showProofModal(context, item),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View Proof'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                        side: BorderSide(color: Colors.blue.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                    ),
                    Text(
                      item.dateTime.split(',').first,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.kTextDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
