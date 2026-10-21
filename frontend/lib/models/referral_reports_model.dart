// lib/features/admin/models/referral_model.dart
//
// ============================================================================
// IMPORTANT — FIELD NAMES ARE BEST-EFFORT, NOT CONFIRMED
// ============================================================================
// This screen is backed by admin/payout_reports.php and admin/payout_history.php,
// but their PHP source wasn't available when this model was written. Every
// `_pick()` call below tries several plausible key-name variants (based on the
// snake_case conventions used in your other endpoints, e.g. investments.php),
// and falls back to 0 / empty rather than throwing, so the UI degrades to the
// same "₹0 / no data" placeholder state the original mock screen shipped with
// instead of crashing.
//
// TO FINISH WIRING THIS UP CORRECTLY:
//   1. Hit admin/payout_reports.php and admin/payout_history.php directly
//      (Postman/browser) and look at the real JSON keys.
//   2. Add the real key name to the relevant _pick(...) list below (first
//      match wins), or replace it outright.
// ============================================================================

class ReferralSummary {
  final double aggregateYield;
  final int activeNodes;
  final double grossPayout;
  final double tdsDeducted;
  final double serviceCharge;
  final double netPayout;
  final double totalDeductions;
  final int transmissions; // count of referral payout transactions

  ReferralSummary({
    required this.aggregateYield,
    required this.activeNodes,
    required this.grossPayout,
    required this.tdsDeducted,
    required this.serviceCharge,
    required this.netPayout,
    required this.totalDeductions,
    required this.transmissions,
  });

  factory ReferralSummary.empty() => ReferralSummary(
        aggregateYield: 0,
        activeNodes: 0,
        grossPayout: 0,
        tdsDeducted: 0,
        serviceCharge: 0,
        netPayout: 0,
        totalDeductions: 0,
        transmissions: 0,
      );

  factory ReferralSummary.fromJson(Map<String, dynamic> json) {
    final gross = _pickDouble(json, ['gross_payout', 'gross_amount', 'total_commission']);
    final tds = _pickDouble(json, ['tds_deducted', 'tds_amount', 'total_tds']);
    final service = _pickDouble(json, ['service_charge', 'service_charge_amount', 'total_service_charge']);
    final net = _pickDouble(json, ['net_payout', 'net_amount', 'total_net_commission']);
    final deductions = _pickDouble(json, ['total_deductions']) != 0
        ? _pickDouble(json, ['total_deductions'])
        : (tds + service);

    return ReferralSummary(
      aggregateYield: _pickDouble(json, ['aggregate_yield', 'total_yield', 'aggregate_commission']) != 0
          ? _pickDouble(json, ['aggregate_yield', 'total_yield', 'aggregate_commission'])
          : gross,
      activeNodes: _pickInt(json, ['active_nodes', 'active_referrers', 'active_count']),
      grossPayout: gross,
      tdsDeducted: tds,
      serviceCharge: service,
      netPayout: net,
      totalDeductions: deductions,
      transmissions: _pickInt(json, ['transmissions', 'transaction_count', 'total_transactions']),
    );
  }
}

class EliteReferrer {
  final int userId;
  final String name;
  final String email;
  final double totalEarned;
  final int referralCount;

  EliteReferrer({
    required this.userId,
    required this.name,
    required this.email,
    required this.totalEarned,
    required this.referralCount,
  });

  factory EliteReferrer.fromJson(Map<String, dynamic> json) {
    return EliteReferrer(
      userId: _pickInt(json, ['user_id', 'id']),
      name: (_pick(json, ['user_name', 'name']) ?? '').toString(),
      email: (_pick(json, ['user_email', 'email']) ?? '').toString(),
      totalEarned: _pickDouble(json, ['total_earned', 'total_commission', 'net_payout']),
      referralCount: _pickInt(json, ['referral_count', 'referrals', 'node_count']),
    );
  }
}

class ReferralHistoryEntry {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final String? protocolRef; // transaction / reference id
  final String status; // e.g. 'completed', 'failed', 'pending'
  final double amount;
  final DateTime? createdAt;
  final bool referralActive; // current stop/resume state, if present in payload

  ReferralHistoryEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.protocolRef,
    required this.status,
    required this.amount,
    this.createdAt,
    required this.referralActive,
  });

  factory ReferralHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ReferralHistoryEntry(
      id: _pickInt(json, ['id', 'transaction_id']),
      userId: _pickInt(json, ['user_id']),
      userName: (_pick(json, ['user_name', 'name']) ?? '').toString(),
      userEmail: (_pick(json, ['user_email', 'email']) ?? '').toString(),
      protocolRef: _pick(json, ['reference', 'protocol_ref', 'transaction_ref'])?.toString(),
      status: (_pick(json, ['status', 'transaction_status']) ?? 'unknown').toString(),
      amount: _pickDouble(json, ['amount', 'net_amount', 'commission_amount']),
      createdAt: _pickDate(json, ['created_at', 'processed_at', 'date']),
      referralActive: _pickBool(json, ['referral_active'], defaultValue: true),
    );
  }

  String get initial => userName.isNotEmpty ? userName[0].toUpperCase() : '?';
}

// --- shared parsing helpers ---

dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k) && json[k] != null) return json[k];
  }
  return null;
}

double _pickDouble(Map<String, dynamic> json, List<String> keys) {
  final v = _pick(json, keys);
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int _pickInt(Map<String, dynamic> json, List<String> keys) {
  final v = _pick(json, keys);
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

bool _pickBool(Map<String, dynamic> json, List<String> keys, {bool defaultValue = false}) {
  final v = _pick(json, keys);
  if (v == null) return defaultValue;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase();
  return s == '1' || s == 'true' || s == 'yes';
}

DateTime? _pickDate(Map<String, dynamic> json, List<String> keys) {
  final v = _pick(json, keys);
  if (v == null) return null;
  final s = v.toString();
  if (s.isEmpty || s == '0000-00-00 00:00:00') return null;
  return DateTime.tryParse(s);
}