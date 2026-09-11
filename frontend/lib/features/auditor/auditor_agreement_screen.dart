import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class AuditorAgreementScreen extends StatelessWidget {
  const AuditorAgreementScreen({super.key});

  final Color _navyBlue = const Color(0xFF1B233A);
  final Color _slateText = const Color(0xFF94A3B8);

  void _handleDownload() {
    ToastService.show(
      title: 'Download Started',
      message: 'Your digital agreement is being saved as a PDF.',
      type: ToastType.success,
    );
  }

  void _handleShare() {
    ToastService.show(
      title: 'Share Document',
      message: 'Opening sharing options for Agreement VAM_01.',
      type: ToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // Custom Header constructed below
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700), // Document constraint for desktop/tablet
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Area
                const Text(
                  'LEGAL DOCUMENT',
                  style: TextStyle(color: AppColors.goldColor, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2.0),
                ),
                const SizedBox(height: 4),
                Text(
                  'AGREEMENT',
                  style: TextStyle(color: _navyBlue, fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0),
                ),
                const SizedBox(height: 4),
                Text(
                  'YOUR DIGITAL GOLD PURCHASE CERTIFICATE',
                  style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
                ),
                const SizedBox(height: 24),

                // 2. Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _handleShare,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _navyBlue,
                          side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Icon(Icons.share_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _handleDownload,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('DOWNLOAD', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 1.0)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navyBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 3. The Certificate Card (using Stack for the overlapping logo)
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Main White Card Background
                    Container(
                      margin: const EdgeInsets.only(top: 28), // Space for overlapping logo
                      padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 30, offset: const Offset(0, 10))
                        ],
                      ),
                      child: _buildDocumentContent(context),
                    ),

                    // Overlapping Top Logo
                    Positioned(
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _navyBlue,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: _navyBlue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))
                          ],
                        ),
                        child: const Icon(Icons.verified, color: AppColors.goldColor, size: 32), // Substitute for the Vamanan crown logo
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // DOCUMENT BODY
  // ==========================================================================
  Widget _buildDocumentContent(BuildContext context) {
    return Stack(
      children: [
        // Faint Watermark in the background
        Positioned.fill(
          child: Center(
            child: Transform.rotate(
              angle: -0.5,
              child: Text(
                'SECURE',
                style: TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFF8FAFC).withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
        
        // Actual Content
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'GOLD PURCHASE AGREEMENT',
              textAlign: TextAlign.center,
              style: TextStyle(color: _navyBlue, fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            const Text(
              'AGREEMENT ID: VAM_01',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.goldColor, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5),
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFF1E293B), thickness: 2), // Dark Navy Divider
            const SizedBox(height: 24),

            // Intro Statement with Gold Left Border
            Container(
              padding: const EdgeInsets.only(left: 16),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.goldColor, width: 4)),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: _navyBlue, fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5, height: 1.5),
                  children: const [
                    TextSpan(text: 'THIS AGREEMENT IS MADE ON THIS '),
                    TextSpan(text: '6 DAY OF SEPTEMBER, 2026', style: TextStyle(color: AppColors.goldColor)),
                    TextSpan(text: ' AT THE KRISHNAGIRI HUB.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Information Cards (Issuer & Buyer)
            _buildEntityCard(
              label: 'COMPANY (ISSUER)',
              title: 'VAMANAN GOLD (VAMANAN ENTERPRISES)',
              subtitle: 'SHOP NO. 2/229- G, NEAR KEDDATHALAPALLI BUS STOP, RAYAKOTTAI ROAD, KRISHNAGIRI, TAMIL NADU - 635 001.',
              watermark: Icons.account_balance,
            ),
            const SizedBox(height: 16),
            _buildEntityCard(
              label: 'CUSTOMER (BUYER)',
              title: 'TEST AUDITOR',
              subtitle: 'ID: VAM_01',
              watermark: Icons.shield_outlined,
            ),
            const SizedBox(height: 40),

            // Section 1: Purchase Details
            _buildSectionHeader('1', 'PURCHASE DETAILS'),
            const SizedBox(height: 16),
            _buildTermsText('1.1 Purchase: The customer buys gold and starts earning daily cashback right away.'),
            _buildTermsText('1.2 Duration: Cashback is paid for up to 100 days.'),
            _buildTermsText('1.3 Cashback: The customer receives 1% daily cashback on the total purchase value.'),
            const SizedBox(height: 24),

            // Product Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
              child: Row(
                children: [
                  Expanded(flex: 3, child: _buildProductStat('PRODUCT', 'APPLE IPHONE 16 PRO MAX')),
                  Container(height: 40, width: 1, color: const Color(0xFFE2E8F0)),
                  Expanded(flex: 2, child: _buildProductStat('TOTAL VALUE', '₹1,49,999', isGold: true)),
                  Container(height: 40, width: 1, color: const Color(0xFFE2E8F0)),
                  Expanded(flex: 2, child: _buildProductStat('WEIGHT', '0 Grams')),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Section 2: Terms & Conditions
            _buildSectionHeader('2', 'TERMS & CONDITIONS'),
            const SizedBox(height: 16),
            _buildTermsText('2.1 THE MINIMUM PURCHASE IS 1 GRAM OF GOLD.', isUppercase: true),
            _buildTermsText('2.2 REFERRAL COMMISSIONS UNLOCK AFTER YOU REFER 10 QUALIFIED MEMBERS.', isUppercase: true),
            _buildTermsText('2.3 YOU RECEIVE 2% CASHBACK DAILY DURING THE CASHBACK PERIOD.', isUppercase: true),
            _buildTermsText('2.4 CASHBACK ENDS AFTER 100 DAYS OR ONCE YOU REACH 100% OF YOUR PURCHASE VALUE.', isUppercase: true),
            const SizedBox(height: 48),

            // Signatures Section
            _buildSignatureBlock('AUTHORIZED CONTROL', 'VAMANAN ENTERPRISES V', watermark: Icons.apartment),
            _buildSignatureBlock('VERIFIED BY', 'LEGAL TEAM', watermark: Icons.gavel),
            _buildSignatureBlock('AUDITOR SIGNATURE', '', watermark: Icons.access_time), // Empty for pending sign
            _buildSignatureBlock('YOUR SIGNATURE', 'TEST AUDITOR', watermark: Icons.draw_outlined),
          ],
        ),
      ],
    );
  }

  // ==========================================================================
  // HELPER COMPONENTS
  // ==========================================================================

  Widget _buildEntityCard({required String label, required String title, required String subtitle, required IconData watermark}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Icon(watermark, size: 64, color: const Color(0xFFE2E8F0).withOpacity(0.5)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(color: _navyBlue, fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, height: 1.4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String number, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(8)),
          child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildTermsText(String text, {bool isUppercase = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: TextStyle(
          color: _navyBlue.withOpacity(0.8),
          fontSize: 10,
          fontWeight: isUppercase ? FontWeight.w900 : FontWeight.w600,
          fontStyle: isUppercase ? FontStyle.italic : FontStyle.normal,
          letterSpacing: isUppercase ? 0.5 : 0.0,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildProductStat(String label, String value, {bool isGold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          Text(value, textAlign: TextAlign.center, style: TextStyle(color: isGold ? AppColors.goldColor : _navyBlue, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildSignatureBlock(String label, String name, {required IconData watermark}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(watermark, size: 40, color: const Color(0xFFE2E8F0).withOpacity(0.5)),
          Column(
            children: [
              Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Text(
                name.isEmpty ? '..........................................................' : name,
                style: TextStyle(color: _navyBlue, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }
}