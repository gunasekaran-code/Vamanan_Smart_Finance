// models/auditor_buy_models.dart
//
// Three models, each tied to a confirmed (or best-effort) backend shape:
//
// 1. ProductItem      <- GET admin/products.php            (confirmed: SELECT * FROM products)
// 2. MarketRates      <- GET admin/sync_market_rate.php     (confirmed: returns spot_price/market_price for gold only)
// 3. OrderHistoryItem <- GET auditor/summary.php  [ASSUMED]  (mapped to the known `cashback_cycles` row shape
//                         used elsewhere in this API — see purchase.php / advocate/stats.php — but I don't have
//                         auditor/summary.php's actual source, so confirm the wrapping key ("orders"/"purchases"/
//                         "cycles") once you can share it.)

import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/services/session_service.dart';

class ProductItem {
  final int id;
  final String? productCode;
  final String name;
  final String category;
  final String? slug;
  final double weight;
  final String purity;
  final double price;
  final double? gstRate;
  final int stockQuantity;
  final String? image;
  final String? description;
  final bool isActive;

  ProductItem({
    required this.id,
    this.productCode,
    required this.name,
    required this.category,
    this.slug,
    required this.weight,
    required this.purity,
    required this.price,
    this.gstRate,
    required this.stockQuantity,
    this.image,
    this.description,
    required this.isActive,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: _asInt(json['id']) ?? 0,
      productCode: json['product_code']?.toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? 'Gold').toString(),
      slug: json['slug']?.toString(),
      weight: _asDouble(json['weight']) ?? 0,
      purity: (json['purity'] ?? '24K').toString(),
      price: _asDouble(json['price']) ?? 0,
      gstRate: _asDouble(json['gst_rate']),
      stockQuantity: _asInt(json['stock_quantity']) ?? 0,
      image: _resolveImage(json),
      description: json['description']?.toString(),
      isActive: (_asInt(json['is_active']) ?? 1) == 1,
    );
  }

  static String? _resolveImage(Map<String, dynamic> json) {
    for (final key in [
      'image',
      'image_url',
      'imageUrl',
      'product_image',
      'photo',
      'img'
    ]) {
      final v = json[key]?.toString().trim();
      if (v != null && v.isNotEmpty && v.toLowerCase() != 'null') {
        return v;
      }
    }
    return null;
  }

  /// Absolute URL of the product photo, or fallback to backend-hosted image.
  String? get imageUrl {
    final raw = image?.trim() ?? '';
    if (raw.isNotEmpty && raw.toLowerCase() != 'null') {
      final url = ApiConfig.fileUrl(_cleanImagePath(raw));
      if (url.isNotEmpty) return url;
    }
    return defaultBackendImageUrl;
  }

  /// Candidate URLs in priority order for resilient network loading.
  List<String> get candidateImageUrls {
    final urls = <String>[];
    final primary = imageUrl;
    if (primary != null && primary.isNotEmpty) {
      urls.add(primary);
      // If primary is api/uploads/..., also provide uploads/... as alternate candidate
      if (primary.contains('/api/uploads/')) {
        final alt = primary.replaceFirst('/api/uploads/', '/uploads/');
        if (!urls.contains(alt)) urls.add(alt);
      } else if (primary.contains('/uploads/') && !primary.contains('/api/uploads/')) {
        final alt = primary.replaceFirst('/uploads/', '/api/uploads/');
        if (!urls.contains(alt)) urls.add(alt);
      }
    }
    final fallback = defaultBackendImageUrl;
    if (!urls.contains(fallback)) {
      urls.add(fallback);
    }
    return urls;
  }

  /// Default backend image URL tailored to category and product name keywords.
  String get defaultBackendImageUrl {
    final c = category.toLowerCase();
    final n = name.toLowerCase();
    if (c.contains('gold') || n.contains('gold')) {
      return ApiConfig.fileUrl('api/uploads/products/1778586023_6a0311a7de7d4.png');
    } else if (c.contains('construction') ||
        n.contains('house') ||
        n.contains('cement') ||
        n.contains('steel') ||
        n.contains('brick') ||
        n.contains('sand')) {
      return ApiConfig.fileUrl('api/uploads/products/1778586318_6a0312cec6e0b.png');
    } else if (c.contains('vehicle') ||
        n.contains('car') ||
        n.contains('harrier') ||
        n.contains('nexon') ||
        n.contains('enfield') ||
        n.contains('alto')) {
      if (n.contains('harrier') || n.contains('nexon')) {
        return ApiConfig.fileUrl('api/uploads/products/1785131002_6a66effaba441.png');
      }
      return ApiConfig.fileUrl('api/uploads/products/1784009392_6a55d2b04b2e5.png');
    } else if (c.contains('electronic') ||
        n.contains('phone') ||
        n.contains('watch') ||
        n.contains('tv') ||
        n.contains('samsung') ||
        n.contains('apple')) {
      if (n.contains('iphone') || n.contains('apple') || n.contains('watch') || n.contains('ipad')) {
        return ApiConfig.fileUrl('api/uploads/products/1785129934_6a66ebce25612.png');
      }
      return ApiConfig.fileUrl('api/uploads/products/1785130832_6a66ef509a1cc.png');
    } else if (c.contains('grocer') ||
        n.contains('rice') ||
        n.contains('oil') ||
        n.contains('sugar') ||
        n.contains('dal') ||
        n.contains('atta')) {
      return ApiConfig.fileUrl('api/uploads/products/1778586023_6a0311a7de7d4.png');
    }
    return ApiConfig.fileUrl('api/uploads/products/1778586023_6a0311a7de7d4.png');
  }

  static String _cleanImagePath(String path) {
    var p = path.replaceAll('\\', '/').trim();
    if (p.startsWith('"') && p.endsWith('"')) p = p.substring(1, p.length - 1);
    if (p.startsWith("'") && p.endsWith("'")) p = p.substring(1, p.length - 1);
    return p;
  }

  bool get inStock => stockQuantity > 0;

  /// The GST % shop/purchase.php will bill for this product: the product's own
  /// `gst_rate` wins, else the platform default for its category.
  double effectiveGstRate(GstDefaults defaults) =>
      gstRate ?? defaults.rateForCategory(category);

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

/// Category-default GST rates from `platform_settings` (`gold_gst` /
/// `general_gst`), applied exactly as shop/purchase.php does: gold and silver
/// categories use the precious-metal rate, everything else the general rate.
class GstDefaults {
  final double goldGst;
  final double generalGst;

  const GstDefaults({this.goldGst = 3, this.generalGst = 18});

  double rateForCategory(String category) {
    final c = category.toLowerCase();
    return (c.contains('gold') || c.contains('silver')) ? goldGst : generalGst;
  }
}

/// One line of a product checkout, sent to shop/purchase.php as the `items`
/// JSON array. The server re-prices every line from `products`.
class PurchaseLine {
  final int productId;
  final int quantity;
  final String name;

  const PurchaseLine({
    required this.productId,
    required this.quantity,
    required this.name,
  });

  Map<String, dynamic> toJson() =>
      {'product_id': productId, 'quantity': quantity};
}

/// A product in the cart, with the price/stock/GST snapshot needed to render
/// and total it. The snapshot is re-synced from the server whenever the cart
/// page opens, so it never drives what is actually billed.
class CartItem {
  final int productId;
  final String name;
  final String category;
  final String purity;
  final String? image;
  final double price;
  final double gstRate;
  final int stockQuantity;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.name,
    required this.category,
    required this.purity,
    this.image,
    required this.price,
    required this.gstRate,
    required this.stockQuantity,
    required this.quantity,
  });

  factory CartItem.fromProduct(ProductItem p,
      {required int quantity, required double gstRate}) {
    return CartItem(
      productId: p.id,
      name: p.name,
      category: p.category,
      purity: p.purity,
      image: p.image,
      price: p.price,
      gstRate: gstRate,
      stockQuantity: p.stockQuantity,
      quantity: quantity,
    );
  }

  String? get imageUrl {
    final raw = image?.trim() ?? '';
    if (raw.isNotEmpty && raw.toLowerCase() != 'null') {
      final url = ApiConfig.fileUrl(ProductItem._cleanImagePath(raw));
      if (url.isNotEmpty) return url;
    }
    return defaultBackendImageUrl;
  }

  String get defaultBackendImageUrl {
    final c = category.toLowerCase();
    final n = name.toLowerCase();
    if (c.contains('gold') || n.contains('gold')) {
      return ApiConfig.fileUrl('api/uploads/products/1778586023_6a0311a7de7d4.png');
    } else if (c.contains('construction') || n.contains('house') || n.contains('cement') || n.contains('steel')) {
      return ApiConfig.fileUrl('api/uploads/products/1778586318_6a0312cec6e0b.png');
    } else if (c.contains('vehicle') || n.contains('car')) {
      return ApiConfig.fileUrl('api/uploads/products/1784009392_6a55d2b04b2e5.png');
    } else if (c.contains('electronic') || n.contains('phone')) {
      return ApiConfig.fileUrl('api/uploads/products/1785130832_6a66ef509a1cc.png');
    }
    return ApiConfig.fileUrl('api/uploads/products/1778586023_6a0311a7de7d4.png');
  }

  double get lineSubtotal => price * quantity;
  double get lineGst => lineSubtotal * gstRate / 100;
  double get lineTotal => lineSubtotal + lineGst;

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        name: name,
        category: category,
        purity: purity,
        image: image,
        price: price,
        gstRate: gstRate,
        stockQuantity: stockQuantity,
        quantity: quantity ?? this.quantity,
      );

  PurchaseLine toPurchaseLine() =>
      PurchaseLine(productId: productId, quantity: quantity, name: name);

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name': name,
        'category': category,
        'purity': purity,
        'image': image,
        'price': price,
        'gst_rate': gstRate,
        'stock_quantity': stockQuantity,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: ProductItem._asInt(json['product_id']) ?? 0,
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      purity: (json['purity'] ?? '').toString(),
      image: ProductItem._resolveImage(json),
      price: ProductItem._asDouble(json['price']) ?? 0,
      gstRate: ProductItem._asDouble(json['gst_rate']) ?? 0,
      stockQuantity: ProductItem._asInt(json['stock_quantity']) ?? 0,
      quantity: ProductItem._asInt(json['quantity']) ?? 1,
    );
  }
}

class MarketRates {
  final double goldSpotPricePerGram;
  final double goldMarketPricePerGram; // spot + local premium — the one to charge customers
  final DateTime? updatedAt;

  MarketRates({
    required this.goldSpotPricePerGram,
    required this.goldMarketPricePerGram,
    this.updatedAt,
  });

  factory MarketRates.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return MarketRates(
      goldSpotPricePerGram: _asDouble(data['spot_price']) ?? 0,
      goldMarketPricePerGram: _asDouble(data['market_price']) ?? 0,
      updatedAt: DateTime.tryParse((data['updated_at'] ?? '').toString()),
    );
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class OrderHistoryItem {
  final int id;
  final String? productName;
  final String assetType; // gold | silver | product
  final double weight;
  final double totalValue;
  final double productAmount;
  final double gstAmount;
  final double totalAmount;
  final String status; // pending | approved | rejected (mirrors cashback_cycles.status)
  final String? transactionId;
  final String? paymentScreenshot;
  final String? paymentMethod;

  /// `cashback_cycles.daily_payout` — despite the column name, purchase.php
  /// stores the gross *monthly* installment here (ex-GST base / plan months).
  final double installment;
  final String createdAt;

  OrderHistoryItem({
    required this.id,
    this.productName,
    required this.assetType,
    required this.weight,
    required this.totalValue,
    required this.productAmount,
    required this.gstAmount,
    required this.totalAmount,
    required this.status,
    this.transactionId,
    this.paymentScreenshot,
    this.paymentMethod,
    required this.installment,
    required this.createdAt,
  });

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    return OrderHistoryItem(
      id: _asInt(json['id'] ?? json['cycle_id']) ?? 0,
      // The name stored on the cycle row is this order's own. orders.php's
      // `product_name` is joined through the user's *latest* agreement, so it
      // names the most recent purchase on every row — only a fallback.
      productName: _firstNonEmpty(
          [json['cycle_product_name'], json['product_name']]),
      assetType: (json['asset_type'] ?? 'gold').toString(),
      weight: _asDouble(json['weight']) ?? 0,
      totalValue: _asDouble(json['total_value']) ?? 0,
      productAmount: _asDouble(json['product_amount']) ?? 0,
      gstAmount: _asDouble(json['gst_amount']) ?? 0,
      totalAmount: _asDouble(json['total_amount']) ?? _asDouble(json['total_value']) ?? 0,
      status: (json['status'] ?? 'pending').toString(),
      transactionId: json['transaction_id']?.toString(),
      paymentScreenshot: json['payment_screenshot']?.toString(),
      paymentMethod: _firstNonEmpty([json['payment_method']]),
      installment: _asDouble(json['daily_payout']) ?? 0,
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }

  DateTime? get createdDate => DateTime.tryParse(createdAt);

  /// Orders are delivered within 7 working days (Mon–Fri) of being placed.
  DateTime? get estimatedDelivery {
    final start = createdDate;
    if (start == null) return null;
    var d = DateTime(start.year, start.month, start.day);
    var added = 0;
    while (added < 7) {
      d = d.add(const Duration(days: 1));
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
        added++;
      }
    }
    return d;
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      final s = v?.toString().trim() ?? '';
      if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
    }
    return null;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

/// Holds the id of the currently logged-in customer/auditor for this session.
///
/// TODO: set this once, right after a successful login
class AuditorSession {
  AuditorSession._();

  /// The signed-in user's id, as the `user_id` query/body parameter every
  /// `api/customer/*` endpoint expects.
  ///
  /// This used to be a mutable static that nothing ever assigned, so it was
  /// always null and every screen reading it failed with "No logged-in user
  /// id set". It now reads the real session, the same way
  /// `AuditorPaymentScreen` already did.
  static int? get currentUserId {
    final raw = SessionService.instance.currentUser?.id;
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }
}