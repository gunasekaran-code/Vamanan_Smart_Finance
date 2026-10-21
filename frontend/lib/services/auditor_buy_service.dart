import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/network/json_envelope.dart';
import 'package:frontend/services/settings_service.dart';
import '../../models/auditor_buy_model.dart';

class AuditorBuyService {
  static const String _productsPath = 'admin/products.php';
  static const String _categoriesPath = 'admin/categories.php';
  static const String _purchasePath = 'shop/purchase.php';

  /// Bumped after every successful order, from wherever it was placed (the
  /// Buy screen, a product card, or the cart), so the "My Orders" list can
  /// reload without the screens knowing about each other.
  static final ValueNotifier<int> orderPlaced = ValueNotifier<int>(0);

  // In-memory caches so switching tabs or opening the cart renders instantly
  // instead of re-fetching. Pass `forceRefresh` to bypass (the REFRESH button,
  // and the final check before checkout).
  static final _Memo<List<ProductItem>> _productsMemo =
      _Memo(const Duration(minutes: 2));
  static final _Memo<List<String>> _categoriesMemo =
      _Memo(const Duration(minutes: 15));
  static final _Memo<GstDefaults> _gstMemo = _Memo(const Duration(minutes: 15));
  static final _Memo<MarketRates> _goldRateMemo =
      _Memo(const Duration(minutes: 1));

  /// The last product list fetched this session (possibly stale), for an
  /// instant first paint while a refresh runs.
  static List<ProductItem>? get cachedProducts => _productsMemo.last;
  static List<String>? get cachedCategories => _categoriesMemo.last;
  static GstDefaults? get cachedGstDefaults => _gstMemo.last;

  // ---------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------
  static Future<List<ProductItem>> fetchProducts({bool forceRefresh = false}) =>
      _productsMemo.get(_loadProducts, force: forceRefresh);

  static Future<List<ProductItem>> _loadProducts() async {
    final uri = ApiConfig.endpoint(_productsPath);
    final response = await _get(uri);
    final List<dynamic> data = (response['data'] as List<dynamic>?) ?? [];
    return data
        .map((p) => ProductItem.fromJson(p as Map<String, dynamic>))
        .where((p) => p.isActive)
        .toList();
  }

  /// GET admin/categories.php — category names in the admin-configured order.
  static Future<List<String>> fetchCategories({bool forceRefresh = false}) =>
      _categoriesMemo.get(_loadCategories, force: forceRefresh);

  static Future<List<String>> _loadCategories() async {
    final uri = ApiConfig.endpoint(_categoriesPath);
    final response = await _get(uri);
    final List<dynamic> data = (response['data'] as List<dynamic>?) ?? [];
    return data
        .whereType<Map>()
        .map((c) => (c['name'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  /// Category-default GST rates (`gold_gst` / `general_gst`) for products that
  /// carry no `gst_rate` of their own. Falls back to purchase.php's own
  /// defaults (3% / 18%) if settings can't be read, since those are what the
  /// server bills with in that case too.
  static Future<GstDefaults> fetchGstDefaults({bool forceRefresh = false}) async {
    try {
      return await _gstMemo.get(() async {
        final settings = await SettingsService.instance.fetchSettings();
        return GstDefaults(
          goldGst: double.tryParse(settings.value('gold_gst')) ?? 3,
          generalGst: double.tryParse(settings.value('general_gst')) ?? 18,
        );
      }, force: forceRefresh);
    } catch (_) {
      return const GstDefaults(); // not cached, so the next call retries
    }
  }

  // ---------------------------------------------------------------------
  // Live gold rate (this endpoint both refreshes AND returns the rate)
  // ---------------------------------------------------------------------
  static Future<MarketRates> refreshGoldRate({bool forceRefresh = false}) =>
      _goldRateMemo.get(() async {
        final uri = ApiConfig.endpoint(TallyEndpoints.syncMarketRate);
        final response = await _get(uri);
        return MarketRates.fromJson(response);
      }, force: forceRefresh);

  // ---------------------------------------------------------------------
  // My orders
  // ---------------------------------------------------------------------

  /// GET customer/orders.php?user_id=N — this user's `cashback_cycles` rows,
  /// newest first.
  ///
  /// This used to call `auditor/summary.php`, which reports platform-wide
  /// revenue and GST and carries no order rows, so the list was always empty.
  /// orders.php is scoped to the one `user_id` in the query string, so no
  /// client-side filtering is needed — or possible to get wrong.
  static Future<List<OrderHistoryItem>> fetchMyOrders(int userId) async {
    final uri = ApiConfig.endpoint(CustomerEndpoints.orders)
        .replace(queryParameters: {'user_id': '$userId'});
    final response = await _get(uri);
    return _parseOrders(response);
  }

  static List<OrderHistoryItem> _parseOrders(Map<String, dynamic> response) {
    final data = response['data'];
    List<dynamic>? rawList;

    if (data is Map<String, dynamic>) {
      rawList = (data['orders'] ?? data['purchases'] ?? data['cycles'])
          as List<dynamic>?;
    } else if (data is List<dynamic>) {
      rawList = data;
    }

    if (rawList == null) return [];

    return rawList
        .whereType<Map>()
        .map((o) => OrderHistoryItem.fromJson(o.cast<String, dynamic>()))
        .toList();
  }

  // ---------------------------------------------------------------------
  // Submit a purchase (gold/silver by weight, or product lines)
  // ---------------------------------------------------------------------

  /// For products, pass [items]: purchase.php's `items` branch prices each
  /// line from the DB *with its quantity* (its single-`product_id` branch
  /// ignores quantity), so both Buy Now and cart checkout go through it.
  static Future<PurchaseResult> submitPurchase({
    required int userId,
    required String assetType, // 'gold' | 'silver' | 'product'
    double? weight,
    int? productId,
    List<PurchaseLine>? items,
    String? paymentMode, // 'upi' -> 'UPI Scan', else 'Bank Transfer'
    String? transactionId,
    String? phone,
    XFile? screenshot,
  }) async {
    final uri = ApiConfig.endpoint(_purchasePath);

    final request = http.MultipartRequest('POST', uri);
    request.fields.addAll(<String, String>{
      'user_id': userId.toString(),
      'asset_type': assetType,
      if (weight != null) 'weight': weight.toString(),
      if (productId != null) 'product_id': productId.toString(),
      if (items != null && items.isNotEmpty)
        'items': jsonEncode(items.map((i) => i.toJson()).toList()),
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (transactionId != null) 'transaction_id': transactionId,
      if (phone != null) 'phone': phone,
    });
    if (screenshot != null) {
      // fromBytes, not fromPath: on web an XFile path is a blob URL that
      // fromPath cannot open.
      request.files.add(http.MultipartFile.fromBytes(
        'screenshot',
        await screenshot.readAsBytes(),
        filename: screenshot.name,
      ));
    }

    late final http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send().timeout(ApiConfig.timeout);
    } catch (e) {
      throw AuditorBuyException('Could not reach the server: $e');
    }

    final response = await http.Response.fromStream(streamedResponse);

    final Map<String, dynamic> decoded;
    try {
      decoded = decodeJsonEnvelope(response);
    } on ServerEnvelopeException catch (e) {
      throw AuditorBuyException(e.toString());
    }

    if (decoded['status'] != 'success') {
      throw AuditorBuyException(
          (decoded['message'] ?? 'Purchase failed').toString());
    }

    orderPlaced.value++;
    return PurchaseResult(
      message: (decoded['message'] ?? '').toString(),
      productName: decoded['product']?.toString(),
      cycleId: decoded['cycle_id']?.toString(),
      invoiceNo: decoded['invoice_no']?.toString(),
    );
  }

  static Future<Map<String, dynamic>> _get(Uri uri) async {
    late final http.Response response;
    try {
      response = await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw AuditorBuyException('Could not reach the server: $e');
    }

    // The status is checked after decoding: these endpoints answer 400/500
    // with a real `{"status":"error","message":...}` body, and that message
    // beats "Server returned HTTP 500".
    final Map<String, dynamic> decoded;
    try {
      decoded = decodeJsonEnvelope(response);
    } on ServerEnvelopeException catch (e) {
      throw AuditorBuyException(e.toString());
    }

    if (decoded['status'] != 'success') {
      throw AuditorBuyException(
          (decoded['message'] ?? 'Request failed (HTTP ${response.statusCode})')
              .toString());
    }

    return decoded;
  }
}

/// A single cached value with a time-to-live. Concurrent callers share one
/// in-flight request; failures are not cached.
class _Memo<T> {
  final Duration ttl;
  _Memo(this.ttl);

  T? _value;
  DateTime? _fetchedAt;
  Future<T>? _inFlight;

  T? get last => _value;

  bool get _isFresh =>
      _value != null &&
      _fetchedAt != null &&
      DateTime.now().difference(_fetchedAt!) < ttl;

  Future<T> get(Future<T> Function() load, {bool force = false}) {
    if (!force && _isFresh) return Future.value(_value as T);
    return _inFlight ??= load().then((value) {
      _value = value;
      _fetchedAt = DateTime.now();
      return value;
    }).whenComplete(() => _inFlight = null);
  }
}

class PurchaseResult {
  final String message;
  final String? productName;
  final String? cycleId;
  final String? invoiceNo;

  PurchaseResult({
    required this.message,
    this.productName,
    this.cycleId,
    this.invoiceNo,
  });
}

class AuditorBuyException implements Exception {
  final String message;
  AuditorBuyException(this.message);

  @override
  String toString() => message;
}
