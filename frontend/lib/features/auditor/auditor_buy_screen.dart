import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/inr_format.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'auditor_payment_screen.dart';
import 'auditor_products_screen.dart';
import '../../models/auditor_buy_model.dart';
import '../../services/auditor_buy_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

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

  // Live gold rate (fetched). Silver has no backend endpoint yet, so it
  // stays a local fallback like in the original screen — flagged clearly.
  double _goldPrice = 0;
  static const double _silverPriceFallback = 100.00;
  bool _isLoadingRate = true;
  bool _isRefreshing = false;

  // Bumped to make the PRODUCTS tab reload from the server.
  int _productsRefreshToken = 0;

  // My Orders
  List<OrderHistoryItem> _orders = [];
  bool _isLoadingOrders = true;
  String? _ordersError;

  @override
  void initState() {
    super.initState();
    _loadGoldRate(showToast: false);
    _loadOrders();
    AuditorBuyService.orderPlaced.addListener(_loadOrders);
  }

  @override
  void dispose() {
    AuditorBuyService.orderPlaced.removeListener(_loadOrders);
    super.dispose();
  }

  Future<void> _loadGoldRate({bool showToast = true}) async {
    setState(() {
      if (showToast) _isRefreshing = true;
      _isLoadingRate = _goldPrice == 0;
    });
    try {
      // The REFRESH button (showToast) always re-syncs; otherwise a rate
      // fetched in the last minute is reused.
      final rates =
          await AuditorBuyService.refreshGoldRate(forceRefresh: showToast);
      if (!mounted) return;
      setState(() {
        _goldPrice = rates.goldMarketPricePerGram;
      });
      if (showToast) {
        ToastService.show(
          title: 'Prices Refreshed',
          message: 'Live market rates have been updated.',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (showToast) {
        ToastService.show(title: 'Refresh Failed', message: e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRate = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadOrders() async {
    final userId = AuditorSession.currentUserId;
    if (userId == null) {
      setState(() {
        _isLoadingOrders = false;
        _ordersError = 'You are not signed in. Sign in again to see your orders.';
      });
      return;
    }
    setState(() {
      _isLoadingOrders = true;
      _ordersError = null;
    });
    try {
      final orders = await AuditorBuyService.fetchMyOrders(userId);
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (e) {
      if (!mounted) return;
      setState(() => _ordersError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  void _handleRefresh() {
    if (_activeTab == 'PRODUCTS') {
      setState(() => _productsRefreshToken++);
      _loadOrders();
    } else {
      _loadGoldRate(showToast: true);
    }
  }

  void _incrementWeight(int delta) {
    setState(() {
      if (_weightGrams + delta > 0) {
        _weightGrams += delta;
      }
    });
  }

  void _proceedToBuy() {
    double price = _activeTab == 'GOLD 22K' ? _goldPrice : _silverPriceFallback;
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
            constraints: const BoxConstraints(maxWidth: 1200),
            // AppPage already pads 20px; don't add more on phones.
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width < 600 ? 0 : 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. HEADER
                Row(
                  children: const [
                    Icon(Icons.star, color: AppColors.goldColor, size: 8),
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
                    onPressed: _isRefreshing ? null : _handleRefresh,
                    icon: _isRefreshing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync, size: 16),
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

                // 3. DYNAMIC CONTENT (CALCULATOR, PRODUCTS LIST, OR EMPTY STATE)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _activeTab == 'PRODUCTS'
                      ? AuditorProductsScreen(
                          key: const ValueKey('PRODUCTS'),
                          refreshToken: _productsRefreshToken,
                        )
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
                _buildOrdersSection(),
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
    final bool isGold = _activeTab == 'GOLD 22K';
    double currentPrice = isGold ? _goldPrice : _silverPriceFallback;
    String trendText = isGold ? 'LIVE MARKET RATE' : 'REFERENCE RATE';

    double baseAmt = currentPrice * _weightGrams;
    double gst = baseAmt * 0.03;
    double total = baseAmt + gst;

    if (isGold && _isLoadingRate) {
      return Container(
        key: ValueKey(_activeTab),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 80),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: _lightBorder, width: 2)),
        child: const Center(child: AppLoader()),
      );
    }

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
                        Icon(isGold ? Icons.trending_up : Icons.info_outline, color: AppColors.goldColor, size: 14),
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
                        isGold
                            ? 'GOLD PRICE IS THE LIVE MARKET RATE. YOUR DAILY REWARDS START THE NEXT DAY.'
                            : 'SILVER PRICE IS A REFERENCE RATE (NO LIVE FEED CONFIGURED YET). YOUR DAILY REWARDS START THE NEXT DAY.',
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

  Widget _buildOrdersSection() {
    if (_isLoadingOrders) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: _lightBorder, width: 2)),
        child: const Center(child: AppLoader()),
      );
    }

    if (_ordersError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: _lightBorder, width: 2)),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 40, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),
            Text(_ordersError!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadOrders, child: const Text('RETRY')),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return _buildOrdersEmptyState();
    }

    return Column(
      children: _orders.map((o) => _buildOrderTile(o)).toList(),
    );
  }

  Widget _buildOrderTile(OrderHistoryItem o) {
    final status = o.status.toLowerCase();
    final Color statusColor;
    final IconData statusIcon;
    switch (status) {
      case 'active':
      case 'completed':
        statusColor = AppColors.kSuccess;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'rejected':
      case 'cancelled':
        statusColor = AppColors.kDanger;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppColors.goldColor;
        statusIcon = Icons.access_time;
    }

    final IconData assetIcon;
    switch (o.assetType.toLowerCase()) {
      case 'silver':
        assetIcon = Icons.toll_outlined;
        break;
      case 'product':
        assetIcon = Icons.inventory_2_outlined;
        break;
      default:
        assetIcon = Icons.bolt_outlined;
    }

    final created = o.createdDate;
    final delivery = o.estimatedDelivery;
    final showDelivery = delivery != null && (status == 'pending' || status == 'active');
    final utr = o.transactionId?.trim() ?? '';
    const metaStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.8);

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text((o.productName ?? o.assetType).toUpperCase(),
                style: TextStyle(color: _navyBlue, fontSize: 15, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.3)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 12),
                  const SizedBox(width: 4),
                  Text(o.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: formatInr(o.totalAmount), style: metaStyle.copyWith(color: AppColors.kTextDark)),
              TextSpan(text: ' INVESTED', style: metaStyle.copyWith(color: const Color(0xFF94A3B8))),
            ])),
            if (o.installment > 0)
              Text('+${formatInr(o.installment)}/MONTH', style: metaStyle.copyWith(color: AppColors.goldColor)),
            if ((o.paymentMethod ?? '').isNotEmpty)
              Text(o.paymentMethod!.toUpperCase(), style: metaStyle.copyWith(color: const Color(0xFFCBD5E1))),
          ],
        ),
        if (showDelivery) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, color: AppColors.kInfo, size: 13),
              const SizedBox(width: 6),
              Flexible(
                child: Text('EST. DELIVERY: ${DateFormat('dd MMM').format(delivery).toUpperCase()} (7 WORKING DAYS)',
                    style: metaStyle.copyWith(color: AppColors.kInfo)),
              ),
            ],
          ),
        ],
      ],
    );

    final meta = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(created != null ? DateFormat('dd MMM yyyy').format(created).toUpperCase() : o.createdAt,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
        if (utr.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('UTR: ${utr.toUpperCase()}',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
        ],
      ],
    );

    final icon = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lightBorder, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Icon(assetIcon, color: AppColors.goldColor, size: 28),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: _lightBorder, width: 2)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Narrow screens stack the date/UTR under the details.
          if (constraints.maxWidth < 520) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      details,
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.centerLeft, child: meta),
                    ],
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              icon,
              const SizedBox(width: 20),
              Expanded(child: details),
              const SizedBox(width: 16),
              meta,
            ],
          );
        },
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