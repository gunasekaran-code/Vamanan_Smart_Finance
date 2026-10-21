import 'package:frontend/core/config/api_config.dart';

double numOf(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int intOf(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

class Asset {
  final int id;
  final String name;
  final String category;
  final String? image;
  final double valuation;
  final String weight; // grams for gold/silver; '0' for general products
  final String purity; // karat for gold/silver; specification for general products
  final String? description;
  final double? gstRate; // null = platform default
  final int stock;
  final int lowStockThreshold;
  final bool isActive;
  final String stockStatus; // in_stock | low_stock | out_of_stock
  final double stockValue;
  final int activeAlerts;
  final DateTime? lastMovementAt;

  const Asset({
    required this.id,
    required this.name,
    required this.category,
    this.image,
    required this.valuation,
    this.weight = '0',
    this.purity = '',
    this.description,
    this.gstRate,
    required this.stock,
    required this.lowStockThreshold,
    required this.isActive,
    required this.stockStatus,
    required this.stockValue,
    required this.activeAlerts,
    this.lastMovementAt,
  });

  bool get isPreciousMetal =>
      category.toUpperCase().contains('GOLD') || category.toUpperCase().contains('SILVER');

  String get metric => '${isPreciousMetal ? 'PM' : 'OG'} • $name';

  /// Absolute URL of the product photo stored in `products.image`
  /// (e.g. `api/uploads/products/123_abc.png`), or null when there is none.
  String? get imageUrl {
    final raw = (image ?? '').trim().replaceAll('"', '').replaceAll("'", '');
    final url = ApiConfig.fileUrl(raw);
    return url.isEmpty ? null : url;
  }

  factory Asset.fromJson(Map<String, dynamic> j) => Asset(
        id: intOf(j['id']),
        name: j['name']?.toString() ?? '',
        category: j['category']?.toString() ?? '',
        image: _imageOf(j),
        valuation: numOf(j['price']),
        weight: j['weight']?.toString() ?? '0',
        purity: j['purity']?.toString() ?? '',
        description: j['description']?.toString(),
        gstRate: j['gst_rate'] == null ? null : double.tryParse(j['gst_rate'].toString()),
        stock: intOf(j['stock_quantity']),
        lowStockThreshold: intOf(j['low_stock_threshold']) == 0 ? 10 : intOf(j['low_stock_threshold']),
        isActive: j['is_active'] == null ? true : (j['is_active'].toString() == '1' || j['is_active'] == true),
        stockStatus: j['stock_status']?.toString() ?? 'in_stock',
        stockValue: numOf(j['stock_value']),
        activeAlerts: intOf(j['active_alerts']),
        lastMovementAt:
            j['last_movement_at'] != null ? DateTime.tryParse(j['last_movement_at'].toString()) : null,
      );

  static String? _imageOf(Map<String, dynamic> j) {
    for (final key in ['image', 'image_url']) {
      final v = j[key]?.toString().trim();
      if (v != null && v.isNotEmpty && v.toLowerCase() != 'null') return v;
    }
    return null;
  }

  Asset copyWith({int? stock, bool? isActive}) => Asset(
        id: id,
        name: name,
        category: category,
        image: image,
        valuation: valuation,
        weight: weight,
        purity: purity,
        description: description,
        gstRate: gstRate,
        stock: stock ?? this.stock,
        lowStockThreshold: lowStockThreshold,
        isActive: isActive ?? this.isActive,
        stockStatus: stockStatus,
        stockValue: stockValue,
        activeAlerts: activeAlerts,
        lastMovementAt: lastMovementAt,
      );
}

class InventorySummary {
  final int totalProducts;
  final int inStock;
  final int lowStock;
  final int outOfStock;
  final double totalStockValue;
  final int totalUnits;
  final int activeAlerts;

  const InventorySummary({
    required this.totalProducts,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.totalStockValue,
    required this.totalUnits,
    required this.activeAlerts,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> j) => InventorySummary(
        totalProducts: intOf(j['total_products']),
        inStock: intOf(j['in_stock']),
        lowStock: intOf(j['low_stock']),
        outOfStock: intOf(j['out_of_stock']),
        totalStockValue: numOf(j['total_stock_value']),
        totalUnits: intOf(j['total_units']),
        activeAlerts: intOf(j['active_alerts']),
      );

  static const empty = InventorySummary(
    totalProducts: 0,
    inStock: 0,
    lowStock: 0,
    outOfStock: 0,
    totalStockValue: 0,
    totalUnits: 0,
    activeAlerts: 0,
  );
}

class StockMovement {
  final int id;
  final int productId;
  final String productName;
  final String movementType;
  final int quantity;
  final int previousQty;
  final int newQty;
  final String? notes;
  final String? createdByName;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.movementType,
    required this.quantity,
    required this.previousQty,
    required this.newQty,
    this.notes,
    this.createdByName,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> j) => StockMovement(
        id: intOf(j['id']),
        productId: intOf(j['product_id']),
        productName: j['product_name']?.toString() ?? '',
        movementType: j['movement_type']?.toString() ?? '',
        quantity: intOf(j['quantity']),
        previousQty: intOf(j['previous_qty']),
        newQty: intOf(j['new_qty']),
        notes: j['notes']?.toString(),
        createdByName: j['created_by_name']?.toString(),
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class InventoryAlert {
  final int id;
  final int productId;
  final String productName;
  final String alertType;
  final int currentQty;
  final int threshold;
  final DateTime createdAt;

  const InventoryAlert({
    required this.id,
    required this.productId,
    required this.productName,
    required this.alertType,
    required this.currentQty,
    required this.threshold,
    required this.createdAt,
  });

  factory InventoryAlert.fromJson(Map<String, dynamic> j) => InventoryAlert(
        id: intOf(j['id']),
        productId: intOf(j['product_id']),
        productName: j['product_name']?.toString() ?? '',
        alertType: j['alert_type']?.toString() ?? '',
        currentQty: intOf(j['current_qty']),
        threshold: intOf(j['threshold']),
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}