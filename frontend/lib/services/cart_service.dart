import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/core/services/session_service.dart';
import '../models/auditor_buy_model.dart';
import 'auditor_buy_service.dart';

/// The signed-in customer's shopping cart.
///
/// There is no cart endpoint on the server, so the cart lives on the device
/// (SharedPreferences, one key per user id) and is checked out through
/// shop/purchase.php's `items` array, which re-prices every line from the DB.
/// [syncWithServer] refreshes price, GST, stock and availability from
/// admin/products.php so what the cart shows matches what will be billed.
class CartService extends ChangeNotifier {
  CartService._() {
    SessionService.instance.addListener(_onSessionChanged);
    _onSessionChanged();
  }
  static final CartService instance = CartService._();

  static const String _keyPrefix = 'cart_v1_';

  /// Only customers get a cart (the header icon and "Add to cart").
  static bool isAvailableFor(UserRole? role) => role == UserRole.customer;

  String? _userId;
  List<CartItem> _items = const [];
  bool _isSyncing = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  bool get isSyncing => _isSyncing;

  /// Distinct products — what the "N ITEMS" label and header badge show.
  int get itemCount => _items.length;
  double get subtotal => _items.fold(0, (sum, i) => sum + i.lineSubtotal);
  double get gst => _items.fold(0, (sum, i) => sum + i.lineGst);
  double get total => subtotal + gst;

  int quantityOf(int productId) =>
      _items.where((i) => i.productId == productId).fold(0, (s, i) => s + i.quantity);

  /// Lines whose quantity is more than the stock last seen on the server.
  List<CartItem> get overStockItems =>
      _items.where((i) => i.quantity > i.stockQuantity).toList();

  // ---------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------

  /// Adds [quantity] of [product]. Throws [CartException] if the cart would
  /// hold more than is in stock.
  Future<void> add(ProductItem product,
      {required int quantity, required double gstRate}) async {
    _requireUser();
    if (!product.inStock) {
      throw CartException('${product.name} is out of stock.');
    }
    final existing = quantityOf(product.id);
    final wanted = existing + quantity;
    if (wanted > product.stockQuantity) {
      throw CartException(existing > 0
          ? 'Only ${product.stockQuantity} of ${product.name} in stock — $existing already in your cart.'
          : 'Only ${product.stockQuantity} of ${product.name} in stock.');
    }
    final fresh = CartItem.fromProduct(product, quantity: wanted, gstRate: gstRate);
    final index = _items.indexWhere((i) => i.productId == product.id);
    _items = [..._items];
    if (index == -1) {
      _items.add(fresh);
    } else {
      _items[index] = fresh; // also picks up the latest price/stock snapshot
    }
    await _persistAndNotify();
  }

  /// Sets a line's quantity; 0 or less removes it. Throws [CartException]
  /// above the stock last seen for that product.
  Future<void> setQuantity(int productId, int quantity) async {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index == -1) return;
    if (quantity <= 0) return remove(productId);
    final item = _items[index];
    if (quantity > item.stockQuantity) {
      throw CartException('Only ${item.stockQuantity} of ${item.name} in stock.');
    }
    _items = [..._items]..[index] = item.copyWith(quantity: quantity);
    await _persistAndNotify();
  }

  Future<void> remove(int productId) async {
    _items = _items.where((i) => i.productId != productId).toList();
    await _persistAndNotify();
  }

  Future<void> clear() async {
    _items = const [];
    await _persistAndNotify();
  }

  /// Re-reads every cart product from the server: refreshes price, GST and
  /// stock, and drops products that were deleted or deactivated. Returns the
  /// names of the dropped products so the UI can say what happened.
  ///
  /// Uses the recently cached catalogue unless [force] is set (checkout).
  Future<List<String>> syncWithServer({bool force = false}) async {
    if (_items.isEmpty) return const [];
    _isSyncing = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        AuditorBuyService.fetchProducts(forceRefresh: force),
        AuditorBuyService.fetchGstDefaults(),
      ]);
      final products = {
        for (final p in results[0] as List<ProductItem>) p.id: p,
      };
      final gstDefaults = results[1] as GstDefaults;

      final removed = <String>[];
      final synced = <CartItem>[];
      for (final item in _items) {
        final p = products[item.productId];
        if (p == null) {
          removed.add(item.name);
          continue;
        }
        synced.add(CartItem.fromProduct(p,
            quantity: item.quantity, gstRate: p.effectiveGstRate(gstDefaults)));
      }
      _items = synced;
      await _persist();
      return removed;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------

  void _onSessionChanged() {
    final userId = SessionService.instance.currentUser?.id;
    if (userId == _userId) return;
    _userId = (userId == null || userId.isEmpty) ? null : userId;
    _items = const [];
    notifyListeners();
    if (_userId != null) _load(_userId!);
  }

  Future<void> _load(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPrefix$userId');
      if (raw == null || userId != _userId) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _items = decoded
          .whereType<Map>()
          .map((m) => CartItem.fromJson(m.cast<String, dynamic>()))
          .where((i) => i.productId > 0 && i.quantity > 0)
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('CartService: could not restore cart ($e)');
    }
  }

  Future<void> _persistAndNotify() async {
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$userId',
          jsonEncode(_items.map((i) => i.toJson()).toList()));
    } catch (e) {
      debugPrint('CartService: could not save cart ($e)');
    }
  }

  void _requireUser() {
    if (_userId == null) {
      throw CartException('You are not signed in. Sign in again to use the cart.');
    }
  }
}

class CartException implements Exception {
  final String message;
  CartException(this.message);

  @override
  String toString() => message;
}
