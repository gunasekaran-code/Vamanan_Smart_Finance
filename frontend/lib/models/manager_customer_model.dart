class ManagerCustomerModel {
  const ManagerCustomerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.customerId,
    required this.joinedDate,
    required this.walletBalance,
    required this.status,
    required this.isNewRequest,
  });

  factory ManagerCustomerModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');
    return ManagerCustomerModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: (json['role']?.toString() ?? '').toUpperCase(),
      customerId: json['customer_id']?.toString() ?? '',
      joinedDate: createdAt == null
          ? '—'
          : '${createdAt.day}/${createdAt.month}/${createdAt.year}',
      walletBalance: _toDouble(json['balance']),
      status: (json['status']?.toString() ?? 'ACTIVE').toUpperCase(),
      isNewRequest:
          (json['status']?.toString() ?? '').toUpperCase().contains('PENDING'),
    );
  }

  final int id;
  final String name;
  final String email;
  final String role;
  final String customerId;
  final String joinedDate;
  final double walletBalance;
  final String status;
  final bool isNewRequest;

  static int _toInt(Object? value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static double _toDouble(Object? value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
}
