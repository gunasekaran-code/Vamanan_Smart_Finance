class AuditorAgreement {
  final int? id;
  final String agreementId;
  final String type;
  final String status;
  final DateTime? agreementDate;
  final DateTime? signedAt;
  final String customerName;
  final String customerEmail;
  final String customerAddress;
  final String customerPhone;
  final String productName;
  final double price;
  final double weight;
  final String companyName;
  final String companyOffice;

  const AuditorAgreement({
    required this.id,
    required this.agreementId,
    required this.type,
    required this.status,
    required this.agreementDate,
    required this.signedAt,
    required this.customerName,
    required this.customerEmail,
    required this.customerAddress,
    required this.customerPhone,
    required this.productName,
    required this.price,
    required this.weight,
    required this.companyName,
    required this.companyOffice,
  });

  bool get hasAgreement => id != null || agreementId != 'NOT AVAILABLE';

  factory AuditorAgreement.fromJson(Map<String, dynamic> json) {
    final user = _map(json['user']);
    // The existing PHP endpoint returns [] when no agreement exists. Treat it
    // as an empty object instead of crashing while reading the user/company.
    final agreement = _map(json['agreement']);
    final company = _map(json['company']);
    return AuditorAgreement(
      id: _int(agreement['id']),
      agreementId:
          _string(agreement['agreement_id'], fallback: 'NOT AVAILABLE'),
      type: _string(agreement['type'], fallback: 'Gold Purchase Agreement'),
      status: _string(agreement['status'], fallback: 'pending'),
      agreementDate: DateTime.tryParse(_string(agreement['agreement_date'])),
      signedAt: DateTime.tryParse(_string(agreement['signed_at'])),
      customerName: _string(user['name'], fallback: 'Customer'),
      customerEmail: _string(user['email']),
      customerAddress: _string(user['address'], fallback: 'Address pending'),
      customerPhone: _string(user['phone']),
      productName:
          _string(agreement['product_name'], fallback: 'Product pending'),
      price: _double(agreement['price']),
      weight: _double(agreement['weight']),
      companyName: _string(company['name'], fallback: 'Vamanan Enterprises'),
      companyOffice: _string(company['office']),
    );
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : const {};

  static int? _int(dynamic value) =>
      value == null ? null : int.tryParse(value.toString());
  static double _double(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('${value ?? ''}') ?? 0;
}
