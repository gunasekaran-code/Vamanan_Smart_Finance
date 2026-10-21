import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/inr_format.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'auditor_payment_screen.dart';
import '../../models/auditor_buy_model.dart';
import '../../services/auditor_buy_service.dart';
import '../../services/cart_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

/// The PRODUCTS tab of the Buy screen: category filter chips and a grid of
/// active products (admin/products.php), each with a quantity stepper,
/// "Add to cart" (customers only) and "Buy now".
///
/// Change [refreshToken] to force a reload from the server.
class AuditorProductsScreen extends StatefulWidget {
  final int refreshToken;

  const AuditorProductsScreen({super.key, this.refreshToken = 0});

  @override
  State<AuditorProductsScreen> createState() => _AuditorProductsScreenState();
}

class _AuditorProductsScreenState extends State<AuditorProductsScreen> {
  static const String _allCategory = 'ALL PRODUCTS';

  /// Cards rendered per "page" — keeps first paint and image traffic small.
  static const int _pageSize = 12;

  final Color _navyBlue = AppColors.kPrimaryDark;
  final Color _slateText = AppColors.kTextMuted;
  final Color _lightBorder = const Color(0xFFF1F5F9);
  static const Color _badgeBlue = Color(0xFF2B3DB0);
  static const Color _stockGold = Color(0xFFD4B96A);

  List<ProductItem> _products = [];
  List<String> _categories = [];
  GstDefaults _gstDefaults = const GstDefaults();
  bool _isLoading = true;
  String? _error;

  String _selectedCategory = _allCategory;
  int _visibleCount = _pageSize;
  final Map<int, int> _quantities = {};

  bool get _cartEnabled =>
      CartService.isAvailableFor(SessionService.instance.currentUser?.role);

  @override
  void initState() {
    super.initState();
    // Paint whatever this session already fetched, then revalidate.
    final cached = AuditorBuyService.cachedProducts;
    if (cached != null) {
      _apply(
        cached,
        AuditorBuyService.cachedCategories ?? const [],
        AuditorBuyService.cachedGstDefaults ?? const GstDefaults(),
      );
      _isLoading = false;
    }
    _load();
    CartService.instance.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartService.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  /// Keeps the "N IN CART" badges current when the cart changes elsewhere.
  void _onCartChanged() {
    if (mounted && _cartEnabled) setState(() {});
  }

  @override
  void didUpdateWidget(covariant AuditorProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) _load(force: true);
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AuditorBuyService.fetchProducts(forceRefresh: force),
        // Chips are a nicety: if categories fail, derive them from products.
        AuditorBuyService.fetchCategories(forceRefresh: force)
            .catchError((_) => <String>[]),
        AuditorBuyService.fetchGstDefaults(forceRefresh: force),
      ]);
      if (!mounted) return;
      setState(() => _apply(
            results[0] as List<ProductItem>,
            results[1] as List<String>,
            results[2] as GstDefaults,
          ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      if (_products.isNotEmpty) {
        ToastService.show(
            title: 'Could Not Refresh Products', message: e.toString(), type: ToastType.warning);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _apply(List<ProductItem> products, List<String> adminCategories, GstDefaults gst) {
    final categories = [...adminCategories];
    // Surface any product category the admin list doesn't carry, so no
    // product becomes unreachable through the filter.
    for (final p in products) {
      if (p.category.isNotEmpty &&
          !categories.any((c) => c.toLowerCase() == p.category.toLowerCase())) {
        categories.add(p.category);
      }
    }
    _products = products;
    _categories = categories;
    _gstDefaults = gst;
    if (_selectedCategory != _allCategory && !categories.contains(_selectedCategory)) {
      _selectedCategory = _allCategory;
    }
    // Keep chosen quantities within the (possibly changed) stock.
    final byId = {for (final p in products) p.id: p};
    _quantities.removeWhere((id, qty) => (byId[id]?.stockQuantity ?? 0) < qty);
  }

  List<ProductItem> get _filteredProducts {
    if (_selectedCategory == _allCategory) return _products;
    final wanted = _selectedCategory.toLowerCase();
    return _products.where((p) => p.category.toLowerCase() == wanted).toList();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _visibleCount = _pageSize;
    });
  }

  int _qtyFor(ProductItem p) => _quantities[p.id] ?? 1;

  void _changeQty(ProductItem p, int delta) {
    final next = _qtyFor(p) + delta;
    if (next < 1) return;
    if (next > p.stockQuantity) {
      ToastService.show(
          title: 'Stock Limit',
          message: 'Only ${p.stockQuantity} of ${p.name} in stock.',
          type: ToastType.warning);
      return;
    }
    setState(() => _quantities[p.id] = next);
  }

  Future<void> _addToCart(ProductItem p) async {
    final qty = _qtyFor(p);
    try {
      await CartService.instance.add(p,
          quantity: qty, gstRate: p.effectiveGstRate(_gstDefaults));
      if (!mounted) return;
      setState(() => _quantities.remove(p.id));
      ToastService.show(
          title: 'Added to Cart',
          message: '$qty × ${p.name} added. Tap the cart icon to check out.',
          type: ToastType.success);
    } catch (e) {
      ToastService.show(
          title: 'Could Not Add', message: e.toString(), type: ToastType.warning);
    }
  }

  Future<void> _buyNow(ProductItem p) async {
    final qty = _qtyFor(p);
    final base = p.price * qty;
    final total = base + base * p.effectiveGstRate(_gstDefaults) / 100;
    final placed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AuditorPaymentDetailsScreen(
          assetType: 'PRODUCTS',
          weight: qty,
          totalAmount: total,
          items: [PurchaseLine(productId: p.id, quantity: qty, name: p.name)],
        ),
      ),
    );
    if (placed == true && mounted) setState(() => _quantities.remove(p.id));
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _products.isEmpty) {
      return Column(
        key: const ValueKey('PRODUCTS_LOADING'),
        children: [
          _buildCategoryChips(),
          const SizedBox(height: 24),
          const _ProductSkeleton(),
        ],
      );
    }

    if (_error != null && _products.isEmpty) {
      return _stateBox(
        key: 'PRODUCTS_ERROR',
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            Text('COULD NOT LOAD PRODUCTS', style: _label(_slateText, 11, spacing: 1.5)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: _label(const Color(0xFFCBD5E1), 9, spacing: 0)),
            const SizedBox(height: 16),
            TextButton(onPressed: () => _load(force: true), child: const Text('RETRY')),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return _stateBox(
        key: 'PRODUCTS_EMPTY',
        child: Column(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 24),
            Text('NO PRODUCTS AVAILABLE',
                textAlign: TextAlign.center,
                style: _label(const Color(0xFF94A3B8), 12, spacing: 1.5)),
            const SizedBox(height: 8),
            Text('ADMIN HAS NOT LISTED ANY PRODUCTS YET',
                textAlign: TextAlign.center,
                style: _label(const Color(0xFFCBD5E1), 10)),
          ],
        ),
      );
    }

    final filtered = _filteredProducts;
    final visible = filtered.take(_visibleCount).toList();
    final remaining = filtered.length - visible.length;

    return Column(
      key: const ValueKey('PRODUCTS_LIST'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCategoryChips(),
        const SizedBox(height: 24),
        // Reserve the space so the grid doesn't jump when a refresh starts.
        SizedBox(
          height: 2,
          child: _isLoading ? const LinearProgressIndicator(minHeight: 2) : null,
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          _stateBox(
            key: 'CATEGORY_EMPTY',
            child: Column(
              children: [
                const Icon(Icons.search_off, size: 48, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 16),
                Text('NO PRODUCTS IN ${_selectedCategory.toUpperCase()}',
                    textAlign: TextAlign.center,
                    style: _label(const Color(0xFF94A3B8), 11, spacing: 1.5)),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final spacing = width < 560 ? 16.0 : 24.0;
              final columns = width >= 900 ? 3 : (width >= 560 ? 2 : 1);
              final cardWidth = (width - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final p in visible)
                    SizedBox(
                      key: ValueKey('product-${p.id}'),
                      width: cardWidth,
                      child: RepaintBoundary(child: _buildProductCard(p, cardWidth)),
                    ),
                ],
              );
            },
          ),
        if (remaining > 0) ...[
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _visibleCount += _pageSize),
              icon: const Icon(Icons.expand_more, size: 18),
              label: Text('LOAD MORE ($remaining)',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1.2)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _navyBlue,
                backgroundColor: Colors.white,
                side: BorderSide(color: _lightBorder, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryChips() {
    final chips = [_allCategory, ..._categories];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final c in chips) ...[
            _buildChip(c),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String category) {
    final isActive = _selectedCategory == category;
    return InkWell(
      onTap: () => _selectCategory(category),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: isActive ? _navyBlue : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isActive ? _navyBlue : _lightBorder, width: 2),
          boxShadow: isActive
              ? [BoxShadow(color: _navyBlue.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 5))]
              : const [],
        ),
        child: Text(
          category.toUpperCase(),
          style: _label(isActive ? AppColors.goldColor : const Color(0xFF94A3B8), 10.5,
              spacing: 1.1),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductItem p, double cardWidth) {
    final compact = cardWidth < 400;
    final pad = compact ? 20.0 : 28.0;
    final qty = _qtyFor(p);
    final gstRate = p.effectiveGstRate(_gstDefaults);
    final base = p.price * qty;
    final gst = base * gstRate / 100;
    final total = base + gst;
    final description = (p.description ?? '').trim();
    final purity = p.purity.trim();
    final inCart = _cartEnabled ? CartService.instance.quantityOf(p.id) : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 28 : 32),
        border: Border.all(color: _lightBorder, width: 2),
        boxShadow: [
          BoxShadow(color: _navyBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image + variant badge
          SizedBox(
            height: compact ? 190 : 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _ProductImage(
                  key: ValueKey('product-img-${p.id}-${p.imageUrl}'),
                  candidateUrls: p.candidateImageUrls,
                  width: cardWidth,
                ),
                if (purity.isNotEmpty)
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 14,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _pill(purity.toUpperCase(), _badgeBlue),
                    ),
                  ),
                if (inCart > 0)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: _pill('$inCart IN CART', AppColors.goldColor, icon: Icons.shopping_cart_outlined),
                  ),
              ],
            ),
          ),

          // Stock bar
          Container(
            color: p.inStock ? _stockGold : const Color(0xFFCBD5E1),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(p.inStock ? Icons.check_circle_outline : Icons.remove_circle_outline,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  p.inStock ? '${p.stockQuantity} IN STOCK' : 'OUT OF STOCK',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(p.name.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: _navyBlue,
                        fontSize: compact ? 16 : 17,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.5)),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: _categoryChip(p.category)),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(description.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _label(const Color(0xFF94A3B8), 11, spacing: 0.3, height: 1.5)),
                ],
                SizedBox(height: compact ? 20 : 24),

                // Price breakdown
                Container(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 24, vertical: compact ? 18 : 22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _lightBorder, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      _priceRow('UNIT PRICE', formatInrCompact(p.price),
                          TextStyle(color: _navyBlue, fontSize: compact ? 20 : 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
                      const SizedBox(height: 10),
                      _priceRow('GST (${_formatRate(gstRate)}%)', '+${formatInr(gst)}',
                          const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                      const Divider(color: Color(0xFFE2E8F0), thickness: 1.5, height: 26),
                      _priceRow('TOTAL · $qty PCS\nINCL. GST', formatInr(total),
                          TextStyle(color: AppColors.kTextDark, fontSize: compact ? 17 : 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 20 : 24),

                // Quantity
                Row(
                  children: [
                    Text('QTY', style: _label(const Color(0xFF94A3B8), 10, spacing: 1.5)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _QtyStepper(
                        quantity: qty,
                        height: compact ? 48 : 52,
                        onDecrease: p.inStock && qty > 1 ? () => _changeQty(p, -1) : null,
                        onIncrease: p.inStock ? () => _changeQty(p, 1) : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 16 : 24),

                // Actions — side by side, stacked on very narrow cards.
                LayoutBuilder(builder: (context, c) {
                  final stack = c.maxWidth < 280;
                  final buy = _buyButton(p);
                  if (!_cartEnabled) return buy;
                  final cart = _addToCartButton(p);
                  if (stack) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [buy, const SizedBox(height: 10), cart],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: cart),
                      const SizedBox(width: 12),
                      Expanded(child: buy),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addToCartButton(ProductItem p) {
    return OutlinedButton.icon(
      onPressed: p.inStock ? () => _addToCart(p) : null,
      icon: const Icon(Icons.add_shopping_cart_outlined, size: 17),
      label: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('ADD TO CART',
            style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1.1)),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _navyBlue,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buyButton(ProductItem p) {
    return ElevatedButton(
      onPressed: p.inStock ? () => _buyNow(p) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _navyBlue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE2E8F0),
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        shadowColor: _navyBlue.withOpacity(0.3),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.inStock ? 'BUY NOW' : 'SOLD OUT',
                style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11.5, letterSpacing: 1.2)),
            if (p.inStock) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lightBorder),
      ),
      child: Text(category.toUpperCase(),
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
    );
  }

  /// Label on the left, value pinned to the right edge (shrinks rather than
  /// overflowing on narrow cards).
  Widget _priceRow(String label, String value, TextStyle valueStyle) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(label, style: _label(const Color(0xFF94A3B8), 10, spacing: 1.1, height: 1.4)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: valueStyle),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stateBox({required String key, required Widget child}) {
    return Container(
      key: ValueKey(key),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: _lightBorder, width: 2)),
      child: child,
    );
  }

  static String _formatRate(double rate) =>
      rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : rate.toString();

  static TextStyle _label(Color color, double size,
          {double spacing = 1.0, double? height}) =>
      TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: spacing,
          height: height);
}

/// Pill-shaped − qty + control shared by the product card.
class _QtyStepper extends StatelessWidget {
  final int quantity;
  final double height;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _QtyStepper({
    required this.quantity,
    required this.height,
    this.onDecrease,
    this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    const navy = AppColors.kPrimaryDark;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Decrease',
            onPressed: onDecrease,
            icon: const Icon(Icons.remove, size: 18),
            color: navy,
          ),
          Expanded(
            child: Text('$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
          ),
          IconButton(
            tooltip: 'Increase',
            onPressed: onIncrease,
            icon: const Icon(Icons.add, size: 18),
            color: navy,
          ),
        ],
      ),
    );
  }
}

/// Network product photo decoded at display size, with fallback candidate URLs,
/// a placeholder while loading and on error, safe cacheWidth, and a smooth fade-in.
class _ProductImage extends StatefulWidget {
  final List<String> candidateUrls;
  final double width;

  _ProductImage({
    super.key,
    String? url,
    List<String>? candidateUrls,
    required this.width,
  }) : candidateUrls = candidateUrls ??
            (url != null && url.isNotEmpty ? [url] : const []);

  @override
  State<_ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<_ProductImage> {
  int _candidateIndex = 0;

  @override
  void didUpdateWidget(covariant _ProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.candidateUrls, widget.candidateUrls)) {
      _candidateIndex = 0;
    }
  }

  void _onImageError() {
    if (_candidateIndex + 1 < widget.candidateUrls.length) {
      if (mounted) {
        setState(() {
          _candidateIndex++;
        });
      }
    }
  }

  static const Widget _placeholder = ColoredBox(
    color: Color(0xFFF8FAFC),
    child: Center(
      child: Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFE2E8F0)),
    ),
  );

  static const Widget _loadingBox = ColoredBox(
    color: Color(0xFFF8FAFC),
    child: Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFCBD5E1),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.candidateUrls.isEmpty) return _placeholder;
    final currentUrl = widget.candidateUrls[_candidateIndex];
    if (currentUrl.isEmpty) return _placeholder;

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final int? targetCacheWidth =
        (!kIsWeb && widget.width > 0 && (widget.width * dpr).round() > 0)
            ? (widget.width * dpr).round()
            : null;

    return Image.network(
      currentUrl,
      fit: BoxFit.cover,
      cacheWidth: targetCacheWidth,
      filterQuality: FilterQuality.medium,
      // Upload files are served without CORS headers, so on web load them
      // through an <img> element, which the browser doesn't block.
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onImageError();
        });
        return _placeholder;
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (frame == null) _loadingBox,
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: child,
            ),
          ],
        );
      },
    );
  }
}

/// Grey placeholder card shown on the very first load (nothing cached yet).
class _ProductSkeleton extends StatelessWidget {
  const _ProductSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 190, color: const Color(0xFFF8FAFC)),
          Container(height: 38, color: const Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(200, 18),
                const SizedBox(height: 12),
                bar(90, 22),
                const SizedBox(height: 16),
                bar(double.infinity, 12),
                const SizedBox(height: 8),
                bar(160, 12),
                const SizedBox(height: 20),
                bar(double.infinity, 120),
                const SizedBox(height: 20),
                const Center(child: AppLoader()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
 