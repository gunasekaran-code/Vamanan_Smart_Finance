/// Models for the client-side referral-network integrity scan.
///
/// Nothing here maps 1:1 to a backend table — the backend exposes no fraud
/// endpoint. These types describe the findings produced by
/// `FraudDetectionService`, which derives them from data the existing
/// endpoints already return (`admin/all_users.php` and
/// `admin/get_genealogy.php`).
library;

enum FraudSeverity { high, medium, low }

extension FraudSeverityX on FraudSeverity {
  String get label => switch (this) {
        FraudSeverity.high => 'HIGH',
        FraudSeverity.medium => 'MEDIUM',
        FraudSeverity.low => 'LOW',
      };

  /// Contribution of a single alert of this severity to the network risk
  /// score (0-100, saturating).
  int get weight => switch (this) {
        FraudSeverity.high => 22,
        FraudSeverity.medium => 9,
        FraudSeverity.low => 3,
      };

  int get rank => switch (this) {
        FraudSeverity.high => 0,
        FraudSeverity.medium => 1,
        FraudSeverity.low => 2,
      };
}

/// One account implicated by an alert.
class FraudSubject {
  /// `users.id` — the value `get_genealogy.php?user_id=` expects, so the UI
  /// can jump straight into that account's tree.
  final String id;
  final String name;

  /// Human-facing identifier: customer id, else referral code, else raw id.
  final String systemId;

  /// Why this particular account was implicated ("2 accounts share this
  /// email", "joined 4 min after the previous signup", ...).
  final String detail;

  const FraudSubject({
    required this.id,
    required this.name,
    required this.systemId,
    this.detail = '',
  });
}

/// A single finding: one rule, one cluster of accounts.
class FraudAlert {
  /// Stable per-scan identity, used as the expansion-tile key.
  final String id;

  /// Rule identifier, e.g. `DUPLICATE_EMAIL`. Useful for filtering/logging.
  final String code;
  final FraudSeverity severity;
  final String title;
  final String description;
  final String recommendation;
  final List<FraudSubject> subjects;

  const FraudAlert({
    required this.id,
    required this.code,
    required this.severity,
    required this.title,
    required this.description,
    required this.recommendation,
    this.subjects = const [],
  });

  int get subjectCount => subjects.length;
}

/// Outcome of one scan pass.
class FraudScanResult {
  final List<FraudAlert> alerts;
  final int usersScanned;

  /// Accounts the scan could not price because the financial pass failed or
  /// was skipped. Surfaced so a partial scan is never mistaken for a clean one.
  final bool financialsIncluded;
  final String scopeLabel;
  final DateTime generatedAt;

  const FraudScanResult({
    required this.alerts,
    required this.usersScanned,
    required this.scopeLabel,
    required this.generatedAt,
    this.financialsIncluded = true,
  });

  factory FraudScanResult.empty(String scopeLabel) => FraudScanResult(
        alerts: const [],
        usersScanned: 0,
        scopeLabel: scopeLabel,
        generatedAt: DateTime.now(),
      );

  int countOf(FraudSeverity severity) =>
      alerts.where((a) => a.severity == severity).length;

  bool get isClean => alerts.isEmpty;

  /// Distinct accounts implicated by at least one alert.
  int get flaggedAccounts =>
      alerts.expand((a) => a.subjects).map((s) => s.id).toSet().length;

  /// 0-100. Saturating weighted sum — many low-severity findings can never
  /// outrank a single high-severity one reaching the same score.
  int get riskScore {
    if (alerts.isEmpty) return 0;
    final raw = alerts.fold<int>(0, (sum, a) => sum + a.severity.weight);
    return raw > 100 ? 100 : raw;
  }

  String get riskLabel {
    final s = riskScore;
    if (s == 0) return 'CLEAR';
    if (s < 20) return 'LOW';
    if (s < 50) return 'ELEVATED';
    return 'CRITICAL';
  }
}
