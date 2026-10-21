import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/routing/app_routes.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/core/utils/inr_format.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'auditor_payment_screen.dart';
import '../../models/auditor_buy_model.dart';
import '../../services/cart_service.dart';

/// "YOUR CART" — the [AppRoutes.cart] page inside the app shell (header back
/// button + bottom nav). Re-syncs price, GST and stock from the server on
/// open; CHECKOUT continues to Payment Details, which places the order and
/// empties the cart.
class AuditorCartScreen extends StatefulWidget {
  const AuditorCartScreen({super.key});

  @override
  State<AuditorCartScreen> createState() => _AuditorCartScreenState();
}

class _AuditorCartScreenState extends State<AuditorCartScreen> {
  static const double _wideBreakpoint = 900;

  final CartService _cart = CartService.instance;
  final Color _navyBlue = AppColors.kPrimaryDark;
  final Color _lightBorder = const Color(0xFFF1F5F9);

  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  Future<void> _sync({bool force = false}) async {
    try {
      final removed = await _cart.syncWithServer(force: force);
      if (removed.isNotEmpty) {
        ToastService.show(
            title: 'Cart Updated',
            message: '${removed.join(', ')} ${removed.length == 1 ? 'is' : 'are'} no longer available and was removed.',
            type: ToastType.warning);
      }
    } catch (e) {
      ToastService.show(
          title: 'Could Not Refresh Cart',
          message: 'Showing saved prices. $e',
          type: ToastType.warning);
    }
  }

  Future<void> _setQty(CartItem item, int qty) async {
    try {
      await _cart.setQuantity(item.productId, qty);
    } catch (e) {
      ToastService.show(title: 'Stock Limit', message: e.toString(), type: ToastType.warning);
    }
  }

  Future<void> _remove(CartItem item) async {
    await _cart.remove(item.productId);
    ToastService.show(
        title: 'Removed', message: '${item.name} removed from your cart.', type: ToastType.info);
  }

  Future<void> _clear() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Clear Cart',
      message: 'Remove all items from your cart?',
      confirmLabel: 'Clear Cart',
    );
    if (confirmed != true) return;
    await _cart.clear();
  }

  void _continueShopping() => context.go(AppRoutes.auditorBuy);

  Future<void> _checkout() async {
    if (_isCheckingOut) return;
    setState(() => _isCheckingOut = true);
    try {
      // Re-check against the server right before paying, so the amount on
      // Payment Details is the amount purchase.php will bill.
      await _sync(force: true);
      if (!mounted || _cart.isEmpty) return;

      final overStock = _cart.overStockItems;
      if (overStock.isNotEmpty) {
        ToastService.show(
            title: 'Not Enough Stock',
            message: overStock
                .map((i) => i.stockQuantity > 0
                    ? 'Only ${i.stockQuantity} of ${i.name} left'
                    : '${i.name} is out of stock')
                .join('. '),
            type: ToastType.warning);
        return;
      }

      final placed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AuditorPaymentDetailsScreen(
            assetType: 'PRODUCTS',
            weight: 1,
            totalAmount: _cart.total,
            items: _cart.items.map((i) => i.toPurchaseLine()).toList(),
            fromCart: true,
          ),
        ),
      );
      // Land on the Buy page, where the new order shows under MY ORDERS.
      if (placed == true && mounted) context.go(AppRoutes.auditorBuy);
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  // ---------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.kBackground,
      child: ListenableBuilder(
        listenable: _cart,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _wideBreakpoint;
            final hPad = constraints.maxWidth < 400 ? 16.0 : 24.0;
            if (_cart.isEmpty) return _buildEmpty(hPad);
            return isWide ? _buildWide(hPad) : _buildNarrow(hPad);
          },
        ),
      ),
    );
  }

  /// Phones/tablets: one scrolling column, checkout bar pinned at the bottom.
  Widget _buildNarrow(double hPad) {
    final items = _cart.items;
    return Column(
      children: [
        if (_cart.isSyncing) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _sync(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 24),
              children: [
                _buildPageHeader(),
                const SizedBox(height: 20),
                for (final item in items) ...[
                  _CartItemCard(
                    key: ValueKey('cart-${item.productId}'),
                    item: item,
                    onQuantity: (q) => _setQty(item, q),
                    onRemove: () => _remove(item),
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 6),
                _buildSummaryCard(showCheckout: false),
              ],
            ),
          ),
        ),
        _buildCheckoutBar(hPad),
      ],
    );
  }

  /// Desktop/web: items on the left, sticky summary on the right.
  Widget _buildWide(double hPad) {
    final items = _cart.items;
    return Column(
      children: [
        if (_cart.isSyncing) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(hPad, 28, 12, 32),
                      children: [
                        _buildPageHeader(),
                        const SizedBox(height: 24),
                        for (final item in items) ...[
                          _CartItemCard(
                            key: ValueKey('cart-${item.productId}'),
                            item: item,
                            onQuantity: (q) => _setQty(item, q),
                            onRemove: () => _remove(item),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 380,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(12, 28, hPad, 32),
                      child: _buildSummaryCard(showCheckout: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Pieces
  // ---------------------------------------------------------------------

  Widget _buildPageHeader() {
    final count = _cart.itemCount;
    final pcs = _cart.items.fold<int>(0, (s, i) => s + i.quantity);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.circle, color: AppColors.goldColor, size: 8),
                  SizedBox(width: 8),
                  Text('SHOPPING CART',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2.0)),
                ],
              ),
              const SizedBox(height: 6),
              Text('YOUR CART',
                  style: TextStyle(color: _navyBlue, fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0)),
              const SizedBox(height: 2),
              Text('$count ${count == 1 ? 'ITEM' : 'ITEMS'} · $pcs ${pcs == 1 ? 'PC' : 'PCS'}',
                  style: const TextStyle(color: AppColors.kTextMuted, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.2)),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: _continueShopping,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('ADD MORE',
              style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10.5, letterSpacing: 1.0)),
          style: TextButton.styleFrom(foregroundColor: _navyBlue),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({required bool showCheckout}) {
    const rowLabel = TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.4);
    final rowValue = TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic);

    Widget row(String label, String value, TextStyle valueStyle) => Row(
          children: [
            Text(label, style: rowLabel),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: valueStyle)),
              ),
            ),
          ],
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _lightBorder, width: 2),
        boxShadow: [BoxShadow(color: _navyBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: _navyBlue,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: const Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: AppColors.goldColor, size: 16),
                SizedBox(width: 8),
                Text('ORDER SUMMARY',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.6)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                row('SUBTOTAL', formatInr(_cart.subtotal), rowValue),
                const SizedBox(height: 12),
                row('GST', '+${formatInr(_cart.gst)}', rowValue.copyWith(color: const Color(0xFF64748B))),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 28),
                row('TOTAL', formatInr(_cart.total),
                    const TextStyle(color: AppColors.goldColor, fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
                  child: const Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, color: AppColors.kInfo, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('DELIVERED WITHIN 7 WORKING DAYS OF APPROVAL',
                            style: TextStyle(color: AppColors.kInfo, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.8, height: 1.4)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (showCheckout) ...[
                  _checkoutButton(),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('CLEAR CART',
                      style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1.6)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kDanger,
                    side: BorderSide(color: AppColors.kDanger.withOpacity(0.2), width: 1.5),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Slim bar above the bottom nav on narrow layouts: total + CHECKOUT.
  Widget _buildCheckoutBar(double hPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _lightBorder, width: 1.5)),
        boxShadow: [BoxShadow(color: _navyBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -6))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL · INCL. GST',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.2)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(formatInr(_cart.total),
                      style: const TextStyle(color: AppColors.goldColor, fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 6, child: _checkoutButton()),
        ],
      ),
    );
  }

  Widget _checkoutButton() {
    final busy = _isCheckingOut || _cart.isSyncing;
    return ElevatedButton(
      onPressed: busy ? null : _checkout,
      style: ElevatedButton.styleFrom(
        backgroundColor: _navyBlue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _navyBlue.withOpacity(0.6),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: _navyBlue.withOpacity(0.3),
      ),
      child: busy
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('CHECKOUT',
                      style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12.5, letterSpacing: 2.5)),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
    );
  }

  Widget _buildEmpty(double hPad) {
    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 24),
      children: [
        _buildPageHeader(),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _lightBorder, width: 2),
          ),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(26)),
                child: const Icon(Icons.shopping_cart_outlined, size: 40, color: Color(0xFFCBD5E1)),
              ),
              const SizedBox(height: 20),
              const Text('YOUR CART IS EMPTY',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              const Text('ADD PRODUCTS FROM THE BUY PAGE',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _continueShopping,
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: const Text('START SHOPPING',
                    style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1.4)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navyBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One cart line, styled like the product card: thumbnail, name, variant
/// badge and unit price on top; stepper and line total on a tinted footer.
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;

  const _CartItemCard({
    super.key,
    required this.item,
    required this.onQuantity,
    required this.onRemove,
  });

  static const Color _navy = AppColors.kPrimaryDark;
  static const Color _lightBorder = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    final overStock = item.quantity > item.stockQuantity;
    final purity = item.purity.trim();
    final rate = item.gstRate == item.gstRate.roundToDouble()
        ? item.gstRate.toStringAsFixed(0)
        : item.gstRate.toString();

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
              color: overStock ? AppColors.kDanger.withOpacity(0.35) : _lightBorder, width: 2),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 6, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumb(url: item.imageUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _navy, fontSize: 15, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.3, height: 1.2)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (purity.isNotEmpty)
                              _chip(purity.toUpperCase(), fg: Colors.white, bg: const Color(0xFF2B3DB0)),
                            if (item.category.trim().isNotEmpty)
                              _chip(item.category.toUpperCase(),
                                  fg: const Color(0xFF94A3B8), bg: const Color(0xFFF8FAFC), border: _lightBorder),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${formatInrCompact(item.price)} EA. · GST $rate%',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.6)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFCBD5E1), size: 22),
                  ),
                ],
              ),
            ),
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.fromLTRB(12, 10, 18, 10),
              child: Row(
                children: [
                  _Stepper(
                    quantity: item.quantity,
                    onDecrease: item.quantity > 1 ? () => onQuantity(item.quantity - 1) : null,
                    onIncrease: item.quantity < item.stockQuantity ? () => onQuantity(item.quantity + 1) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(formatInr(item.lineTotal),
                              style: const TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.3)),
                        ),
                        const Text('INCL. GST',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (overStock)
              Container(
                color: AppColors.kDanger,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.stockQuantity > 0
                            ? 'ONLY ${item.stockQuantity} IN STOCK — REDUCE QUANTITY'
                            : 'OUT OF STOCK — REMOVE TO CHECK OUT',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
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

  Widget _chip(String text, {required Color fg, required Color bg, Color? border}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: fg, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _Stepper({required this.quantity, this.onDecrease, this.onIncrease});

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, VoidCallback? onTap, String tooltip) => IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 17),
          color: AppColors.kPrimaryDark,
          disabledColor: const Color(0xFFCBD5E1),
        );

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove, onDecrease, 'Decrease'),
          SizedBox(
            width: 30,
            child: Text('$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.kPrimaryDark, fontSize: 15, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
          ),
          btn(Icons.add, onIncrease, 'Increase'),
        ],
      ),
    );
  }
}

/// Small product photo, decoded at thumbnail size.
class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb({required this.url});

  static const double _size = 76;

  @override
  Widget build(BuildContext context) {
    const placeholder = Center(
      child: Icon(Icons.inventory_2_outlined, color: Color(0xFFCBD5E1), size: 28),
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final int? targetCacheWidth =
        (!kIsWeb && _size > 0 && (_size * dpr).round() > 0)
            ? (_size * dpr).round()
            : null;
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: (url == null || url!.isEmpty)
          ? placeholder
          : Image.network(
              url!,
              width: _size,
              height: _size,
              fit: BoxFit.cover,
              cacheWidth: targetCacheWidth,
              // Upload files are served without CORS headers, so on web load
              // them through an <img> element, which the browser doesn't block.
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}
