import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'auditor_payment_screen.dart';

class AuditorBuyScreen extends StatefulWidget {
  const AuditorBuyScreen({super.key});

  @override
  State<AuditorBuyScreen> createState() => _AuditorBuyScreenState();
}

class _AuditorBuyScreenState extends State<AuditorBuyScreen> {
  // Theme Color Aliases
  final Color _navyBlue = AppColors.kPrimaryDark;
  final Color _slateText = AppColors.kTextMuted;
  final Color _lightBorder = const Color(0xFFF1F5F9);
  
  // State
  String _activeTab = 'GOLD 22K'; // GOLD 22K, SILVER PURE, PRODUCTS
  int _weightGrams = 1;

  // Mock Live Prices
  final double _goldPrice = 15127.00;
  final double _silverPrice = 300.00;

  void _handleRefresh() {
    ToastService.show(
      title: 'Prices Refreshed',
      message: 'Live market rates have been updated.',
      type: ToastType.success,
    );
  }

  void _incrementWeight(int delta) {
    setState(() {
      if (_weightGrams + delta > 0) {
        _weightGrams += delta;
      }
    });
  }

  void _proceedToBuy() {
    double price = _activeTab == 'GOLD 22K' ? _goldPrice : _silverPrice;
    double baseAmt = price * _weightGrams;
    double gst = baseAmt * 0.03;
    double total = baseAmt + gst;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuditorPaymentDetailsScreen(
          assetType: _activeTab,
          weight: _weightGrams,
          totalAmount: total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // Custom Header
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. HEADER
                Row(
                  children: const [
                    Icon(Icons.circle, color: AppColors.goldColor, size: 8),
                    SizedBox(width: 8),
                    Text('LIVE PRICES', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2.0)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('BUY GOLD & SILVER', style: TextStyle(color: _navyBlue, fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0)),
                const SizedBox(height: 4),
                Text('BUY GOLD, SILVER OR PRODUCTS AND EARN DAILY REWARDS', style: TextStyle(color: _slateText, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                const SizedBox(height: 24),
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('REFRESH', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1.0)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kTextDark,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: _lightBorder, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 2. TABS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabBtn('GOLD 22K', Icons.bolt),
                      const SizedBox(width: 12),
                      _buildTabBtn('SILVER PURE', Icons.toll_outlined),
                      const SizedBox(width: 12),
                      _buildTabBtn('PRODUCTS', Icons.inventory_2_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 3. DYNAMIC CONTENT (CALCULATOR OR EMPTY STATE)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _activeTab == 'PRODUCTS'
                      ? _buildProductsEmptyState()
                      : _buildCalculatorCard(),
                ),
                const SizedBox(height: 40),

                // 4. MY ORDERS SECTION
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.receipt_long, color: AppColors.goldColor, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MY ORDERS', style: TextStyle(color: _navyBlue, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                        const SizedBox(height: 4),
                        Text('YOUR PURCHASE HISTORY', style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildOrdersEmptyState(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBtn(String title, IconData icon) {
    final isActive = _activeTab == title;
    return InkWell(
      onTap: () => setState(() => _activeTab = title),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? _navyBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? _navyBlue : _lightBorder, width: 2),
          boxShadow: isActive ? [BoxShadow(color: _navyBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? AppColors.goldColor : const Color(0xFFCBD5E1), size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorCard() {
    double currentPrice = _activeTab == 'GOLD 22K' ? _goldPrice : _silverPrice;
    String trendText = _activeTab == 'GOLD 22K' ? '+2.3% TODAY' : '+1.8% TODAY';
    
    double baseAmt = currentPrice * _weightGrams;
    double gst = baseAmt * 0.03;
    double total = baseAmt + gst;

    return Column(
      key: ValueKey(_activeTab),
      children: [
        // Live Price Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: _lightBorder, width: 2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CURRENT ${_activeTab.split(' ')[0]} PRICE', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('₹${currentPrice.toStringAsFixed(0)}', style: TextStyle(color: _navyBlue, fontSize: 40, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0)),
                  const SizedBox(width: 4),
                  const Text('/gram', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.goldBadgeBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.goldBorder)),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up, color: AppColors.goldColor, size: 14),
                        const SizedBox(width: 4),
                        Text(trendText, style: const TextStyle(color: AppColors.goldColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('LIVE PRICE', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                ],
              ),
              const SizedBox(height: 24),
              Icon(Icons.bolt_outlined, color: AppColors.goldColor.withOpacity(0.2), size: 64),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Calculator Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: _lightBorder, width: 2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.bolt, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 16),
                  Text('ENTER AMOUNT', style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
              const SizedBox(height: 32),

              // Weight Input
              const Text('WEIGHT (GRAMS)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: _lightBorder, width: 2)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('$_weightGrams', style: TextStyle(color: _navyBlue, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                    ),
                    Column(
                      children: [
                        InkWell(onTap: () => _incrementWeight(1), child: const Icon(Icons.keyboard_arrow_up, color: Color(0xFF94A3B8))),
                        InkWell(onTap: () => _incrementWeight(-1), child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8))),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Calculations
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('BASE AMOUNT', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
                  Text('₹${baseAmt.toStringAsFixed(2)}', style: TextStyle(color: _navyBlue, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('GST (3%)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
                  Text('+₹${gst.toStringAsFixed(2)}', style: TextStyle(color: _navyBlue, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
              const SizedBox(height: 24),

              const Text('TOTAL AMOUNT', style: TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.goldColor, fontSize: 36, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0)),
              const SizedBox(height: 32),

              // Buy Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToBuy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: _navyBlue.withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('BUY ${_activeTab.split(' ')[0]} NOW', style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 1.5)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_user_outlined, color: AppColors.goldColor, size: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'PRICES ARE BASED ON THE LIVE PURE MARKET RATE. YOUR DAILY REWARDS START THE NEXT DAY.',
                        style: TextStyle(color: const Color(0xFF94A3B8).withOpacity(0.8), fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductsEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: _lightBorder, width: 2)),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: const Color(0xFFE2E8F0)),
          const SizedBox(height: 24),
          const Text('NO PRODUCTS AVAILABLE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          const Text('ADMIN HAS NOT LISTED ANY PRODUCTS YET', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _buildOrdersEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: _lightBorder, width: 2)),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: const Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          const Text('NO ORDERS YET', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          const Text('YOUR PURCHASE HISTORY WILL APPEAR HERE', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
        ],
      ),
    );
  }
}