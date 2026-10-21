/// Model for a row on the Disputes screen.
///
/// Populated from the `disputes` array returned by
/// `GET /api/advocate/stats.php`, which is `disputes` joined with `users`
/// (`d.*, u.name as user_name`). Only `user_name` is confirmed from the
/// PHP you've shared — the rest of the `disputes` table's columns
/// (subject/description/reason, etc.) aren't, so `fromJson` below falls
/// back through several plausible names. Point it at your real column
/// names if these don't match.
class DisputeModel {
  final int id;
  final String customerName;
  final String customerEmail;
  final String subject;
  final String description;
  final String createdDate;
  final String rawStatus; // 'open' | 'in_resolution' | 'resolved' | 'closed' (lowercase)
  String status; // UI label, e.g. 'OPEN', 'IN RESOLUTION', 'RESOLVED' (mutable)

  DisputeModel({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.subject,
    required this.description,
    required this.createdDate,
    required this.rawStatus,
    required this.status,
  });

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    String toStr(dynamic v, [String fallback = '']) =>
        (v == null || v.toString().isEmpty) ? fallback : v.toString();

    final raw = toStr(json['status'], 'open').toLowerCase();
    String uiStatus;
    switch (raw) {
      case 'open':
        uiStatus = 'OPEN';
        break;
      case 'in_resolution':
        uiStatus = 'IN RESOLUTION';
        break;
      case 'resolved':
        uiStatus = 'RESOLVED';
        break;
      case 'closed':
        uiStatus = 'CLOSED';
        break;
      default:
        uiStatus = raw.toUpperCase();
    }

    String formattedDate = toStr(json['created_at']);
    final parsed = DateTime.tryParse(formattedDate);
    if (parsed != null) {
      formattedDate = '${parsed.day}/${parsed.month}/${parsed.year}';
    }

    return DisputeModel(
      id: int.tryParse(toStr(json['id'], '0')) ?? 0,
      customerName: toStr(json['user_name'], 'Unknown Customer'),
      customerEmail: toStr(json['user_email']),
      subject: toStr(json['subject'] ?? json['title'] ?? json['reason'], 'Dispute'),
      description: toStr(json['description'] ?? json['message'] ?? json['details']),
      createdDate: formattedDate,
      rawStatus: raw,
      status: uiStatus,
    );
  }
}