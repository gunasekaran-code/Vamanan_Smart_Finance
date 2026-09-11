import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

// ============================================================================
// DATA MODEL
// ============================================================================
class ProductRequest {
  final String id;
  final String customerName;
  final String customerEmail;
  final String assetName;
  final String assetDetails;
  final String valuation;
  final String yieldInfo;

  const ProductRequest({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.assetName,
    required this.assetDetails,
    required this.valuation,
    required this.yieldInfo,
  });
}

// ============================================================================
// MAIN SCREEN
// ============================================================================
class ProductRequestsScreenManager extends StatefulWidget {
  const ProductRequestsScreenManager({super.key});

  @override
  State<ProductRequestsScreenManager> createState() => _ProductRequestsScreenManagerState();
}

class _ProductRequestsScreenManagerState extends State<ProductRequestsScreenManager> {
  // Mock data based strictly on the provided image
  final List<ProductRequest> _requests = [
    const ProductRequest(
      id: '1',
      customerName: 'PASUBATHI.M',
      customerEmail: 'VIJAYPASUPATHI5332@GMAIL.COM',
      assetName: 'GOLD ASSET',
      assetDetails: '17.000 GRAMS',
      valuation: '₹3,57,002.64',
      yieldInfo: '₹34660.45/DAY YIELD',
    ),
    const ProductRequest(
      id: '2',
      customerName: 'SUGANYA NATARAJAN',
      customerEmail: 'NSUGANYAJESSY@GMAIL.COM',
      assetName: 'GOLD ASSET',
      assetDetails: '8.000 GRAMS',
      valuation: '₹1,68,001.24',
      yieldInfo: '₹16310.80/DAY YIELD',
    ),
    const ProductRequest(
      id: '3',
      customerName: 'SELLADURAI ANBALAGAN',
      customerEmail: 'DRASELLADURAI@GMAIL.COM',
      assetName: 'GOLD ASSET',
      assetDetails: '8.000 GRAMS',
      valuation: '₹1,68,001.24',
      yieldInfo: '₹16310.80/DAY YIELD',
    ),
    const ProductRequest(
      id: '4',
      customerName: 'CHANDRALEKA.D',
      customerEmail: 'LEKAC6600@GMAIL.COM',
      assetName: 'GOLD ASSET',
      assetDetails: '8.000 GRAMS',
      valuation: '₹1,68,001.24',
      yieldInfo: '₹16310.80/DAY YIELD',
    ),
  ];

  // --- Action Handlers ---
  Future<void> _handleApprove(ProductRequest request) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'APPROVE PURCHASE',
      message: 'Are you sure you want to approve the purchase request for ${request.customerName}?',
      confirmLabel: 'APPROVE',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kPrimary,
    );

    if (confirmed == true && mounted) {
      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
      });
      ToastService.show(
        title: 'Purchase Approved',
        message: 'Request for ${request.customerName} has been processed.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _handleReject(ProductRequest request) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'REJECT PURCHASE',
      message: 'Are you sure you want to reject the purchase request for ${request.customerName}?',
      confirmLabel: 'REJECT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true && mounted) {
      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
      });
      ToastService.show(
        title: 'Purchase Rejected',
        message: 'Request for ${request.customerName} has been declined.',
        type: ToastType.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Global Search Bar ---
              Container(
                decoration: BoxDecoration(
                  color: AppColors.kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search customers, assets...',
                    hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- 2. Screen Title ---
              const Text(
                'PENDING PURCHASE REQUESTS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: AppColors.kPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. Responsive Card List ---
              if (_requests.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text(
                      'NO PENDING REQUESTS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.kTextMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _requests.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _RequestCard(
                      request: _requests[index],
                      onApprove: () => _handleApprove(_requests[index]),
                      onReject: () => _handleReject(_requests[index]),
                    );
                  },
                ),
                
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CLEAN ONE-BY-ONE CARD WIDGET
// ============================================================================
class _RequestCard extends StatelessWidget {
  final ProductRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorder.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimary.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- TOP SECTION: Customer Identity ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar with accent bar styling inspired by the image
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.kPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    request.customerName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.kSurface,
                      fontSize: 20,
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
                      const Text(
                        'CUSTOMER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.kTextMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.kPrimary,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.customerEmail,
                        style: const TextStyle(
                          color: AppColors.kTextMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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

          // --- MIDDLE SECTION: Asset Details & Valuation ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Asset Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ASSET DETAILS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.kTextMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.assetName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.kPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.assetDetails,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.goldColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Valuation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VALUATION',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.kTextMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          request.valuation,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: AppColors.kPrimary,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.yieldInfo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.goldColor,
                          fontSize: 10,
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

          // --- BOTTOM SECTION: Actions ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kTextMuted,
                      backgroundColor: AppColors.kSurface,
                      side: const BorderSide(color: AppColors.kBorder, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'REJECT', 
                      style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12)
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimary, // Deep Navy Blue
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'APPROVE', 
                      style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1.0)
                    ),
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