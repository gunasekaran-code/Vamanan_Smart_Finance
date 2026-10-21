/// Data model for a row in the `product_requests` table, as returned by
/// GET /admin/product_requests.php
class ProductRequest {
  final int id;
  final int userId;
  final String customerName;
  final String? customerCode;
  final String? customerEmail;
  final String? phone;
  final String productName;
  final String? model;
  final String category;
  final int quantity;
  final double weight;
  final double expectedPrice;
  final String? description;
  final String status; // pending | reviewing | approved | rejected | fulfilled
  final String? adminNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductRequest({
    required this.id,
    required this.userId,
    required this.customerName,
    this.customerCode,
    this.customerEmail,
    this.phone,
    required this.productName,
    this.model,
    required this.category,
    required this.quantity,
    required this.weight,
    required this.expectedPrice,
    this.description,
    required this.status,
    this.adminNote,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductRequest.fromJson(Map<String, dynamic> json) {
    return ProductRequest(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      // The PHP endpoint stores a snapshot of the customer's name/email on the
      // row itself, but falls back to the joined `users` table if that's empty.
      customerName: _firstNonEmpty(
        [json['customer_name'], json['user_name']],
        fallback: 'Unknown customer',
      ),
      customerCode: _asStringOrNull(json['customer_code'] ?? json['user_customer_id']),
      customerEmail: _asStringOrNull(json['customer_email'] ?? json['user_email']),
      phone: _asStringOrNull(json['phone']),
      productName: _asStringOrNull(json['product_name']) ?? 'Product',
      model: _asStringOrNull(json['model']),
      category: _asStringOrNull(json['category']) ?? 'Gold',
      quantity: _asInt(json['quantity'], fallback: 1),
      weight: _asDouble(json['weight']),
      expectedPrice: _asDouble(json['expected_price']),
      description: _asStringOrNull(json['description']),
      status: _asStringOrNull(json['status']) ?? 'pending',
      adminNote: _asStringOrNull(json['admin_note']),
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asDateTime(json['updated_at']),
    );
  }

  ProductRequest copyWith({String? status, String? adminNote}) {
    return ProductRequest(
      id: id,
      userId: userId,
      customerName: customerName,
      customerCode: customerCode,
      customerEmail: customerEmail,
      phone: phone,
      productName: productName,
      model: model,
      category: category,
      quantity: quantity,
      weight: weight,
      expectedPrice: expectedPrice,
      description: description,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// e.g. "17.000 GRAMS" or, for non-gold/zero-weight items, "3 UNITS"
  String get formattedQuantityDetail {
    if (weight > 0) {
      return '${weight.toStringAsFixed(3)} GRAMS';
    }
    return '$quantity ${quantity == 1 ? 'UNIT' : 'UNITS'}';
  }

  /// Indian-style grouped currency, e.g. "₹3,57,002.64"
  String get formattedValuation => _formatIndianCurrency(expectedPrice);

  String get statusLabel => status.toUpperCase();

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static double _asDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static String? _asStringOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String _firstNonEmpty(List<dynamic> candidates, {required String fallback}) {
    for (final c in candidates) {
      final s = _asStringOrNull(c);
      if (s != null) return s;
    }
    return fallback;
  }

  static DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

/// Groups a number using the Indian numbering system (lakh/crore) with a
/// leading rupee sign and 2 decimal places, e.g. 357002.64 -> "₹3,57,002.64"
String _formatIndianCurrency(double value) {
  final isNegative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final wholePart = parts[0];
  final decimalPart = parts[1];

  String grouped;
  if (wholePart.length <= 3) {
    grouped = wholePart;
  } else {
    final lastThree = wholePart.substring(wholePart.length - 3);
    final remainder = wholePart.substring(0, wholePart.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < remainder.length; i++) {
      final posFromEnd = remainder.length - i;
      buffer.write(remainder[i]);
      if (posFromEnd > 1 && posFromEnd % 2 == 1) {
        buffer.write(',');
      }
    }
    grouped = '${buffer.toString()},$lastThree';
  }

  return '${isNegative ? '-' : ''}₹$grouped.$decimalPart';
}