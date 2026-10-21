class NotificationLog {
  final String id;
  final String title;
  final String message;
  final String recipient;
  final String priority;
  final String timestamp;
  final String? userId; // set when the log targeted one specific user

  NotificationLog({
    required this.id,
    required this.title,
    required this.message,
    required this.recipient,
    required this.priority,
    required this.timestamp,
    this.userId,
  });

  factory NotificationLog.fromJson(Map<String, dynamic> json) {
    return NotificationLog(
      id: json['id']?.toString() ?? '',
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      recipient: (json['recipient'] ?? json['user_name'] ?? 'GLOBAL BROADCAST (ALL INVESTORS)').toString(),
      priority: (json['priority'] ?? json['type'] ?? 'INFO').toString().toUpperCase(),
      timestamp: (json['timestamp'] ?? json['created_at'] ?? '').toString(),
      userId: (json['user_id']?.toString().trim().isNotEmpty ?? false)
          ? json['user_id'].toString()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'message': message,
        'recipient': recipient,
        'priority': priority,
      };
}