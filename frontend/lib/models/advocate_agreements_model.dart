/// Model for a row in the Agreement Approvals Hub.
///
/// Populated from the `agreements` array returned by
/// `GET /api/advocate/stats.php`, which is `agreements` joined with
/// `users` and `products` (see the PHP for exact columns).
///
/// Status mapping assumption (based on how the backend itself computes
/// `pending_agreements` / `active_agreements` in stats.php):
///   - raw status 'verified'            -> UI status 'PENDING' (awaiting advocate signature)
///   - raw status 'ratified' or 'active' -> UI status 'SIGNED'
///   - anything else                     -> shown as-is, uppercased
class AgreementModel {
  final int id;
  final String customerName;
  final String customerEmail;
  final String type;
  final String rawStatus; // the exact status string from the backend
  String status; // UI status: PENDING / SIGNED / other (mutable for optimistic updates)

  AgreementModel({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.type,
    required this.rawStatus,
    required this.status,
  });

  factory AgreementModel.fromJson(Map<String, dynamic> json) {
    String toStr(dynamic v, [String fallback = '']) =>
        (v == null || v.toString().isEmpty) ? fallback : v.toString();

    final raw = toStr(json['status'], 'verified').toLowerCase();
    String uiStatus;
    if (raw == 'verified') {
      uiStatus = 'PENDING';
    } else if (raw == 'ratified' || raw == 'active') {
      uiStatus = 'SIGNED';
    } else {
      uiStatus = raw.toUpperCase();
    }

    // "Type" isn't an explicitly confirmed column — falls back through a
    // few plausible names, then to the linked product, then a generic label.
    final type = toStr(
      json['agreement_type'] ?? json['type'] ?? json['product_name'],
      'AGREEMENT',
    );

    return AgreementModel(
      id: int.tryParse(toStr(json['id'], '0')) ?? 0,
      customerName: toStr(json['user_name'], 'Unknown Customer'),
      customerEmail: toStr(json['user_email']),
      type: type.toUpperCase(),
      rawStatus: raw,
      status: uiStatus,
    );
  }
}