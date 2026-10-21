/// Maps to the row shape returned by `admin/get_all_notifications.php`:
/// n.* (only id, user_id, created_at are guaranteed by the query shown)
/// joined with u.name as user_name.
///
/// Column names beyond id/user_id/created_at/user_name were not visible
/// in the PHP, so this parses several common aliases defensively. If your
/// `notifications` table uses different column names, adjust the
/// fromJson lookups below.
class SupportNotification {
  final int id;
  final int? userId;
  final String userName;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  /// Anything returned by the API that wasn't mapped to a field above,
  /// kept around so nothing is silently dropped.
  final Map<String, dynamic> raw;

  const SupportNotification({
    required this.id,
    this.userId,
    required this.userName,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.raw = const {},
  });

  factory SupportNotification.fromJson(Map<String, dynamic> json) {
    return SupportNotification(
      id: _asInt(json['id']),
      userId: json['user_id'] == null ? null : _asInt(json['user_id']),
      userName: (json['user_name'] ?? '').toString(),
      title: (json['title'] ?? json['subject'] ?? '').toString(),
      message:
          (json['message'] ?? json['body'] ?? json['content'] ?? '').toString(),
      type: (json['type'] ?? json['category'] ?? 'general').toString(),
      isRead: _asBool(json['is_read'] ?? json['read']),
      createdAt: _asDate(json['created_at']) ?? DateTime.now(),
      raw: json,
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty || s.startsWith('0000-00-00')) return null;
    return DateTime.tryParse(s);
  }
}