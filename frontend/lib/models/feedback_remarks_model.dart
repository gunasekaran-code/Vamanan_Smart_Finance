class FeedbackItem {
  final String id;
  final String? fromUserId;
  final String? toUserId;
  final String? fromName;
  final String? toName;
  final String? customerId;
  final String? senderRole;
  final String subject;
  final String message;
  final int? rating;
  final bool isRead;
  final String createdAt;
  final String direction; // customer_to_admin | admin_to_customer

  FeedbackItem({
    required this.id,
    this.fromUserId,
    this.toUserId,
    this.fromName,
    this.toName,
    this.customerId,
    this.senderRole,
    required this.subject,
    required this.message,
    this.rating,
    required this.isRead,
    required this.createdAt,
    required this.direction,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'].toString(),
      fromUserId: json['from_user_id']?.toString(),
      toUserId: json['to_user_id']?.toString(),
      fromName: json['from_name']?.toString(),
      toName: json['to_name']?.toString(),
      customerId: json['customer_id']?.toString(),
      senderRole: json['sender_role']?.toString(),
      subject: (json['subject'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      rating: json['rating'] == null ? null : int.tryParse(json['rating'].toString()),
      isRead: json['is_read'].toString() == '1' || json['is_read'] == true,
      createdAt: (json['created_at'] ?? '').toString(),
      direction: (json['direction'] ?? '').toString(),
    );
  }
}

class CustomerOption {
  final String id;
  final String name;

  CustomerOption({required this.id, required this.name});

  factory CustomerOption.fromJson(Map<String, dynamic> json) {
    return CustomerOption(
      id: json['id'].toString(),
      name: (json['name'] ?? json['full_name'] ?? 'Unnamed').toString(),
    );
  }
}