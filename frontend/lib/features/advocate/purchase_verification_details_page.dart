import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'purchase_verification_page.dart'; // Ensure this imports your PurchaseItem model

class PurchaseVerificationDetailsPage extends StatelessWidget {
  final PurchaseItem item;

  const PurchaseVerificationDetailsPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // Dark Navy
                borderRadius: BorderRadius.circular(8)
              ),
              child: const Icon(Icons.receipt_long, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PURCHASE VERIFICATION DETAILS', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.0)
                ),
                Text(
                  'RECEIPT ${item.id}', 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E293B))
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Breakpoint for switching from 2 columns to 1 column
          final isMobile = constraints.maxWidth < 850;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Layout Switcher: Row for Desktop, Column for Mobile
                isMobile
                    ? Column(
                        children: [
                          _buildLeftColumn(),
                          const SizedBox(height: 24),
                          _buildRightColumn(),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: _buildLeftColumn()),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: _buildRightColumn()),
                        ],
                      ),
                const SizedBox(height: 32),
                
                // Bottom Status Bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB), // Very light gold background
                    border: Border.all(color: AppColors.goldBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.status == 'ACTIVE' ? Icons.check_circle_outline : Icons.pending_actions,
                        color: AppColors.goldColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.status == 'ACTIVE' ? 'PURCHASE RECORD APPROVED & ACTIVE' : 'PURCHASE PENDING VERIFICATION',
                        style: const TextStyle(color: AppColors.goldColor, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- LEFT COLUMN (Customer, Bank, Receipt) ---
  Widget _buildLeftColumn() {
    return Column(
      children: [
        // Card 1: Customer Details
        _DetailCard(
          title: 'CUSTOMER DETAILS',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _DataField(label: 'FULL NAME', value: item.customerName)),
                const SizedBox(width: 16),
                Expanded(child: _DataField(label: 'EMAIL ADDRESS', value: item.customerEmail)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _DataField(label: 'PHONE NUMBER', value: item.phone)),
                const SizedBox(width: 16),
                Expanded(child: _DataField(label: 'KYC VERIFICATION DETAILS', value: 'AADHAR: ${item.aadhar}\nPAN: ${item.pan}')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Card 2: Settlement Bank Details
        _DetailCard(
          title: 'SETTLEMENT BANK DETAILS',
          children: [
            Row(
              children: [
                Expanded(child: _DataField(label: 'BANK NAME', value: 'N/A')),
                const SizedBox(width: 16),
                Expanded(child: _DataField(label: 'BRANCH NAME', value: 'N/A')),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _DataField(label: 'ACCOUNT NUMBER', value: 'N/A')),
                const SizedBox(width: 16),
                Expanded(child: _DataField(label: 'IFSC CODE', value: 'N/A')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Card 3: Receipt Image
        _DetailCard(
          title: 'UPLOADED PAYMENT RECEIPT',
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                // Using a placeholder; in production use Image.network
                image: const DecorationImage(
                  image: NetworkImage('https://via.placeholder.com/600x400?text=Payment+Receipt'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {}, // Add logic to view full screen image
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('VIEW FULL RECEIPT IMAGE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B), // Dark Navy
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            )
          ],
        ),
      ],
    );
  }

  // --- RIGHT COLUMN (Purchase & Payment Info) ---
  Widget _buildRightColumn() {
    return _DetailCard(
      title: 'PURCHASE INFORMATION',
      icon: Icons.shopping_bag_outlined,
      children: [
        Row(
          children: [
            Expanded(child: _DataField(label: 'PRODUCT NAME', value: item.productTitle, isBoxed: true)),
            const SizedBox(width: 16),
            Expanded(child: _DataField(label: 'ASSET TYPE / CATEGORY', value: item.category, isBoxed: true)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _DataField(label: 'WEIGHT (GRAMS)', value: item.weight, isBoxed: true)),
            const SizedBox(width: 16),
            Expanded(child: _DataField(label: 'PAYMENT METHOD', value: item.paymentMethod, isBoxed: true)),
          ],
        ),
        const SizedBox(height: 16),
        _DataField(label: 'TRANSACTION ID (TID)', value: item.paymentTid, isBoxed: true),
        const SizedBox(height: 32),
        
        const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
        const SizedBox(height: 24),
        
        const Text('PAYMENT DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(child: _DataField(label: 'PRODUCT SUBTOTAL (EX-GST)', value: '₹${item.exGst.toStringAsFixed(2)}', isBoxed: true)),
            const SizedBox(width: 16),
            Expanded(child: _DataField(label: 'GST AMOUNT', value: '₹${item.gst.toStringAsFixed(2)}', isBoxed: true)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _DataField(label: 'TOTAL PAID (INCLUSIVE OF GST)', value: '₹${item.totalPrice.toStringAsFixed(2)}', isBoxed: true, highlight: true)),
            const SizedBox(width: 16),
            Expanded(child: _DataField(label: 'CASHBACK ELIGIBLE (EX-GST)', value: '₹${item.exGst.toStringAsFixed(2)}', isBoxed: true)),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// HELPER WIDGETS FOR DETAILS PAGE
// ============================================================================

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;

  const _DetailCard({required this.title, this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.goldColor),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _DataField extends StatelessWidget {
  final String label;
  final String value;
  final bool isBoxed;
  final bool highlight;

  const _DataField({required this.label, required this.value, this.isBoxed = false, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    Widget textWidget = Text(
      value,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: highlight ? AppColors.goldColor : const Color(0xFF1E293B),
      ),
    );

    if (isBoxed) {
      textWidget = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: highlight ? AppColors.goldBg : const Color(0xFFF8FAFC), // F8FAFC is a very light blue/grey
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: highlight ? AppColors.goldBorder : Colors.transparent),
        ),
        child: textWidget,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 0.5)
        ),
        const SizedBox(height: 6),
        textWidget,
      ],
    );
  }
}