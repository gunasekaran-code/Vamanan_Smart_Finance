import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class MarketRatesScreen extends StatefulWidget {
  const MarketRatesScreen({super.key});

  @override
  State<MarketRatesScreen> createState() => _MarketRatesScreenState();
}

class _MarketRatesScreenState extends State<MarketRatesScreen> {
  final TextEditingController _goldRateCtrl = TextEditingController(text: '15313.68');
  final TextEditingController _silverRateCtrl = TextEditingController(text: '300');

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
      ToastService.show(title: 'Success', message: 'Monthly yield processed successfully.', type: ToastType.success);
    }
  }

  Future<void> _handleFinalizeSynchronization() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'FINALIZE RATE SYNCHRONIZATION',
      message: 'Are you sure you want to update the global market rates? This will immediately impact all active purchase simulations.',
      confirmLabel: 'SYNCHRONIZE',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );

    if (confirmed == true) {
      ToastService.show(title: 'Rates Synchronized', message: 'Global market spot prices have been updated.', type: ToastType.success);
    }
  }

  @override
  void dispose() {
    _goldRateCtrl.dispose();
    _silverRateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive breakpoints for narrow screens
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 380;
    final isMobile = screenWidth < 600;

    final double pagePadding = isSmallMobile ? 12 : (isMobile ? 16 : 24);
    final double cardPadding = isSmallMobile ? 16 : (isMobile ? 20 : 32);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light crisp background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(pagePadding),
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
              SizedBox(
                width: isMobile ? double.infinity : null,
                child: Align(
                  alignment: isMobile ? Alignment.center : Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _handleProcessYield,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: isSmallMobile ? 16 : 24, vertical: isSmallMobile ? 14 : 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: isMobile ? const Size(double.infinity, 0) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'PROCESS MONTHLY YIELD',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: isSmallMobile ? 11 : 12, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. Main Protocol Card ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.kBorder),
                ),
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A), // Navy Blue
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.show_chart, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('MARKET RATE CONTROL', style: TextStyle(fontSize: isSmallMobile ? 18 : 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF1E3A8A))),
                              const SizedBox(height: 4),
                              Text('REAL-TIME ASSET VALUATION ADJUSTMENTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Gold Protocol Input
                    _buildRateCard(
                      title: 'GOLD PROTOCOL (24K)',
                      icon: Icons.bolt,
                      iconColor: const Color(0xFFD97706), // Gold
                      controller: _goldRateCtrl,
                      isSmallMobile: isSmallMobile,
                    ),
                    const SizedBox(height: 24),

                    // Silver Protocol Input
                    _buildRateCard(
                      title: 'SILVER PROTOCOL (PURE)',
                      icon: Icons.link,
                      iconColor: const Color(0xFF94A3B8), // Silver/Grey
                      controller: _silverRateCtrl,
                      isSmallMobile: isSmallMobile,
                    ),
                    const SizedBox(height: 40),

                    // Finalize Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleFinalizeSynchronization,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'FINALIZE RATE SYNCHRONIZATION',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: isSmallMobile ? 12 : 14, letterSpacing: isSmallMobile ? 0.8 : 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- 4. Critical Warning Banner ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB), // Light amber tint
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'CRITICAL WARNING: MODIFYING MARKET RATES WILL IMMEDIATELY IMPACT ALL CUSTOMER PURCHASE SIMULATIONS. ENSURE CROSS-VALIDATION WITH GLOBAL SPOT PRICE NODES BEFORE EXECUTION.',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFFD97706).withOpacity(0.9), // Amber text
                          height: 1.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widget for Rate Inputs ---
  Widget _buildRateCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required bool isSmallMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'ASSET BASE VALUE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF94A3B8),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: isSmallMobile ? 20 : 28,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF1E3A8A), // Navy text
            ),
            decoration: InputDecoration(
              isDense: isSmallMobile,
              prefixText: isSmallMobile ? '₹ ' : '₹   ',
              prefixStyle: TextStyle(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: isSmallMobile ? 16 : 24,
              ),
              suffixIcon: null,
              suffix: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.unfold_more, color: const Color(0xFF1E3A8A), size: isSmallMobile ? 18 : 24),
                  SizedBox(width: isSmallMobile ? 6 : 12),
                  Text(
                    '/ GRAM',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 10 : 12,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF94A3B8).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              fillColor: Colors.white,
              filled: true,
              contentPadding: EdgeInsets.symmetric(horizontal: isSmallMobile ? 14 : 24, vertical: isSmallMobile ? 18 : 24),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
            ),
          ),
        ],
      ),
    );
  }
}
