// models/auditor_request_models.dart
//
// Maps the response of api/customer/product_request.php exactly:
//   GET  ?user_id=123  -> { status, data: { user: {...}, requests: [...] } }
//   POST               -> { status, message, request_id }

class CustomerInfo {
  final int id;
  final String? customerId;
  final String name;
  final String email;
  final String? phone;

  CustomerInfo({
    required this.id,
    this.customerId,
    required this.name,
    required this.email,
    this.phone,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: _asInt(json['id']) ?? 0,
      customerId: json['customer_id']?.toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone']?.toString(),
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

class ProductRequestItem {
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
  final String createdAt;
  final String? updatedAt;

  ProductRequestItem({
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
    required this.createdAt,
    this.updatedAt,
  });

  factory ProductRequestItem.fromJson(Map<String, dynamic> json) {
    return ProductRequestItem(
      id: _asInt(json['id']) ?? 0,
      userId: _asInt(json['user_id']) ?? 0,
      customerName: (json['customer_name'] ?? '').toString(),
      customerCode: json['customer_code']?.toString(),
      customerEmail: json['customer_email']?.toString(),
      phone: json['phone']?.toString(),
      productName: (json['product_name'] ?? '').toString(),
      model: json['model']?.toString(),
      category: (json['category'] ?? 'Gold').toString(),
      quantity: _asInt(json['quantity']) ?? 1,
      weight: _asDouble(json['weight']) ?? 0,
      expectedPrice: _asDouble(json['expected_price']) ?? 0,
      description: json['description']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      adminNote: json['admin_note']?.toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: json['updated_at']?.toString(),
    );
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

/// Bundled result of GET customer/product_request.php?user_id=...
class ProductRequestPrefill {
  final CustomerInfo user;
  final List<ProductRequestItem> requests;

  ProductRequestPrefill({required this.user, required this.requests});
}