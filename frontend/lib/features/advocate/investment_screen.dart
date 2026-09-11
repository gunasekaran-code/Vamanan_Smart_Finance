import 'package:flutter/material.dart';
import 'investment_model.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  // Sample Data
  final List<InvestmentRequest> _requests = const [
    InvestmentRequest(
      id: 'INV-1001',
      userName: 'VIGNESH',
      userEmail: 'vignesh2026@gmail.com',
      assetType: '24K GOLD ASSET',
      weightGrams: '0.000 GRAMS',
      amount: '₹1,26,000.93',
      yieldRate: 'YIELD: 12.5% ANNUAL',
      paymentMode: 'BANK TRANSFER',
      utrNumber: '9283746501',
      submittedTime: '24 AUG AT 02:15 PM',
      receiptImageUrl: 'https://picsum.photos/seed/vignesh_receipt/600/800',
    ),
    InvestmentRequest(
      id: 'INV-1002',
      userName: 'PASUBATHI.M',
      userEmail: 'pasubathi.m@gmail.com',
      assetType: '24K GOLD ASSET',
      weightGrams: '17.000 GRAMS',
      amount: '₹3,57,002.84',
      yieldRate: 'YIELD: 12.5% ANNUAL',
      paymentMode: 'BANK TRANSFER',
      utrNumber: '2134098752',
      submittedTime: '23 AUG AT 06:40 PM',
      receiptImageUrl: 'https://picsum.photos/seed/pasubathi_receipt/600/800',
    ),
    InvestmentRequest(
      id: 'INV-1003',
      userName: 'SUGANYA NATARAJAN',
      userEmail: 'suganya.nat@gmail.com',
      assetType: '24K GOLD ASSET',
      weightGrams: '0.000 GRAMS',
      amount: '₹1,68,001.24',
      yieldRate: 'YIELD: 12.5% ANNUAL',
      paymentMode: 'BANK TRANSFER',
      utrNumber: '8743659120',
      submittedTime: '22 AUG AT 09:10 AM',
      receiptImageUrl: 'https://picsum.photos/seed/suganya_receipt/600/800',
    ),
  ];

  // --------------------------------------------------------------------------
  // RECEIPT VIEWER MODAL
  // --------------------------------------------------------------------------
  void _openReceiptViewer(BuildContext context, InvestmentRequest request) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Image Container
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    request.receiptImageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.kPrimary),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'Unable to load receipt image.',
                          style: TextStyle(color: AppColors.kTextMuted),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Top Right Close Button Icon
              Positioned(
                top: -12,
                right: -12,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // CONFIRMATION DIALOG & TOAST HANDLERS
  // --------------------------------------------------------------------------
  Future<void> _handleAuthorize(InvestmentRequest request) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'AUTHORIZE ACTIVATION',
      message: 'Are you sure you want to APPROVE this investment request?',
      cancelLabel: 'Cancel',
      confirmLabel: 'Okay',
      confirmButtonColor: AppColors.kPrimary,
    );

    if (confirmed == true && mounted) {
      ToastService.show(
        title: 'Investment Approved',
        message: 'Activated gold request for ${request.userName}',
        type: ToastType.success,
      );
    }
  }

  Future<void> _handleReject(InvestmentRequest request) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'REJECT ASSET REQUEST',
      message: 'Are you sure you want to REJECT this investment request?',
      cancelLabel: 'Cancel',
      confirmLabel: 'Okay',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true && mounted) {
      ToastService.show(
        title: 'Request Rejected',
        message: 'Rejected asset submission for ${request.userName}',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F6FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search users, orders, assets...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
                  prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Processor Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF8BA2CE),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_outlined, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'PROCESSOR ONLINE • 24/7 AUTO VERIFY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Header Title Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PENDING GOLD REQUESTS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.kPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'REVIEW AND APPROVE CUSTOMER INVESTMENT SUBMISSIONS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12), // Added safe spacing
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '32',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFC59B27),
                        ),
                      ),
                      Text(
                        'PENDING',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC59B27),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Request Cards List
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _requests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final request = _requests[index];
                return _InvestmentCard(
                  request: request,
                  onVerifyReceipt: () => _openReceiptViewer(context, request),
                  onAuthorize: () => _handleAuthorize(request),
                  onReject: () => _handleReject(request),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// INVESTMENT CARD COMPONENT (Refactored for Responsiveness & Cleanliness)
// ============================================================================
class _InvestmentCard extends StatelessWidget {
  final InvestmentRequest request;
  final VoidCallback onVerifyReceipt;
  final VoidCallback onAuthorize;
  final VoidCallback onReject;

  const _InvestmentCard({
    required this.request,
    required this.onVerifyReceipt,
    required this.onAuthorize,
    required this.onReject,
  });

  static const Color _goldColor = Color(0xFFC59B27);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIdentitySection(),
          const SizedBox(height: 20),
          
          // Row with Expanded keeps Asset & Financial side-by-side cleanly
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAssetSection()),
              const SizedBox(width: 16),
              Expanded(child: _buildFinancialSection()),
            ],
          ),
          
          const SizedBox(height: 20),
          _buildPaymentSection(),
          
          const SizedBox(height: 24),
          _buildActionButtons(),
          
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          
          _buildFooterTags(),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION BUILDERS
  // ===========================================================================

  Widget _buildIdentitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('INVESTOR IDENTITY'),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.kPrimary,
              child: Text(
                request.userName.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.userName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.userEmail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.kTextMuted,
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
      ],
    );
  }

  Widget _buildAssetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('ENTITLED ASSET'),
        const SizedBox(height: 8),
        Text(
          request.assetType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.kPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.workspace_premium_outlined, size: 14, color: _goldColor),
            const SizedBox(width: 4),
            Text(
              request.weightGrams,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _goldColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('FINANCIAL MATRIX'),
        const SizedBox(height: 8),
        // FittedBox prevents text overflow if the amount string is very long
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            request.amount,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.kPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          request.yieldRate,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _goldColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('PAYMENT MODE'),
                const SizedBox(height: 6),
                Text(
                  request.paymentMode,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _goldColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'UTR: ${request.utrNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kPrimary,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onVerifyReceipt,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _goldColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.crop_free_rounded, size: 14, color: _goldColor),
                  SizedBox(width: 6),
                  Text(
                    'RECEIPT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _goldColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onAuthorize,
            child: const Text(
              'AUTHORIZE ACTIVATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.kTextMuted,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: _borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onReject,
            child: const Text(
              'REJECT ASSET REQUEST',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 14, color: AppColors.kTextMuted),
            const SizedBox(width: 6),
            Text(
              'SUBMITTED: ${request.submittedTime}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Wrap prevents right-overflow on small devices
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatusBadge(
              'AWAITING VERIFICATION',
              const Color(0xFFFFFDF5),
              _goldColor,
              Icons.hourglass_top_rounded,
            ),
            _buildStatusBadge(
              'ID VERIFIED',
              const Color(0xFFF0F7FF),
              const Color(0xFF1D4ED8),
              Icons.verified_user_outlined,
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // HELPER COMPONENTS
  // ===========================================================================

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.kTextMuted,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color bgColor, Color textColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}