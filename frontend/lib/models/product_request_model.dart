double _numOf(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _intOf(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

class ProductRequest {
  final int id;
  final int userId;
  final String customerName;
  final String customerId;
  final String customerEmail;
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
  final DateTime createdAt;

  const ProductRequest({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerId,
    required this.customerEmail,
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
  });

  factory ProductRequest.fromJson(Map<String, dynamic> j) => ProductRequest(
        id: _intOf(j['id']),
        userId: _intOf(j['user_id']),
        customerName: (j['customer_name']?.toString().trim().isNotEmpty ?? false)
            ? j['customer_name'].toString()
            : (j['user_name']?.toString() ?? 'Unknown'),
        customerId: (j['customer_code']?.toString().trim().isNotEmpty ?? false)
            ? j['customer_code'].toString()
            : (j['user_customer_id']?.toString() ?? '-'),
        customerEmail: (j['customer_email']?.toString().trim().isNotEmpty ?? false)
            ? j['customer_email'].toString()
            : (j['user_email']?.toString() ?? ''),
        phone: j['phone']?.toString(),
        productName: j['product_name']?.toString() ?? '',
        model: j['model']?.toString(),
        category: j['category']?.toString() ?? 'Gold',
        quantity: _intOf(j['quantity']) == 0 ? 1 : _intOf(j['quantity']),
        weight: _numOf(j['weight']),
        expectedPrice: _numOf(j['expected_price']),
        description: j['description']?.toString(),
        status: (j['status']?.toString() ?? 'pending').toLowerCase(),
        adminNote: j['admin_note']?.toString(),
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      );

  String get statusLabel => status.toUpperCase();
  String get dateDay => createdAt.day.toString().padLeft(2, '0');
  String get dateMonth => _monthAbbr(createdAt.month);
  String get modelLabel => model?.trim().isNotEmpty == true ? 'MODEL: ${model!.toUpperCase()}' : '';

  static String _monthAbbr(int m) => const [
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
      ][m - 1];
}