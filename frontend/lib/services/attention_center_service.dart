import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/core/services/permission_service.dart';
import 'package:frontend/core/services/session_service.dart';
import '../models/cashback_application_model.dart';
import '../models/identity_verification_model.dart';
import 'admin_users_service.dart';
import 'cashback_application_service.dart';
import 'feedback_remarks_service.dart';
import 'identity_verification_service.dart';
import 'investment_service.dart';

/// The queues the header bell watches.
enum AttentionKind { purchases, accounts, kyc, cashback, feedback }

/// One pending record, pre-formatted for the panel.
class AttentionItem {
  final String id;

  /// Bold lead text, e.g. "Guna Sekaran V · ₹15,248.31".
  final String headline;
  final DateTime? at;

  const AttentionItem({required this.id, required this.headline, this.at});
}

class AttentionCategory {
  final AttentionKind kind;
  final String title;

  /// Screen that works the queue; OPEN navigates here.
  final String route;
  final List<AttentionItem> items;
  final int newCount;

  const AttentionCategory({
    required this.kind,
    required this.title,
    required this.route,
    required this.items,
    required this.newCount,
  });

  int get total => items.length;
}

/// "Needs attention" feed behind the header bell.
///
/// Built only from existing endpoints (no backend changes):
///   - purchases awaiting approval  `admin/investments.php`
///   - accounts awaiting access     `admin/all_users.php` (status = pending)
///   - KYC to verify                `admin/all_users.php` (kyc_status pending)
///   - cashback applications        `admin/cashback_applications.php?status=pending`
///   - unread customer feedback     `admin/feedback.php` (is_read = 0)
///
/// Feedback read-state lives in the database (`is_read`), so MARK READ there
/// writes through. The other queues have no read flag server-side, so which
/// items have been seen is remembered per user on the device; an item stays
/// counted until it's actually actioned, it just stops being "new".
class AttentionCenter extends ChangeNotifier {
  AttentionCenter._();
  static final AttentionCenter instance = AttentionCenter._();

  static const Duration _pollInterval = Duration(seconds: 60);
  static const int _maxSeenKeys = 5000;

  final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  final Map<AttentionKind, List<AttentionItem>> _items = {};
  Set<String> _seen = {};

  UserRole? _role;
  String? _userId;
  Timer? _timer;
  bool _loading = false;
  bool _hasLoaded = false;
  bool _watchingSession = false;
  String? _error;

  bool get isLoading => _loading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  List<AttentionCategory> get categories => [
        for (final kind in AttentionKind.values)
          if (_enabled(kind) && (_items[kind]?.isNotEmpty ?? false))
            AttentionCategory(
              kind: kind,
              title: _titleFor(kind),
              route: _routeFor(kind),
              items: _items[kind]!,
              newCount: _items[kind]!.where((i) => !_isSeen(kind, i)).length,
            ),
      ];

  int get totalCount => categories.fold(0, (sum, c) => sum + c.total);
  int get totalNew => categories.fold(0, (sum, c) => sum + c.newCount);

  /// Starts (or restarts, on a user switch) live polling for [userId].
  Future<void> start({required String userId, required UserRole role}) async {
    if (_userId == userId && _role == role && _timer != null) return;
    _watchSession();
    stop();
    _userId = userId;
    _role = role;
    _items.clear();
    _hasLoaded = false;
    _seen = await _loadSeen();
    if (!_anyEnabled) {
      notifyListeners();
      return;
    }
    await refresh();
    _timer = Timer.periodic(_pollInterval, (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  // Every sign-out path goes through SessionService, so polling stops (and
  // the previous user's counts clear) however the user logs out.
  void _watchSession() {
    if (_watchingSession) return;
    _watchingSession = true;
    SessionService.instance.addListener(() {
      if (SessionService.instance.currentUser != null || _userId == null) return;
      stop();
      _userId = null;
      _role = null;
      _items.clear();
      _hasLoaded = false;
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    if (_loading || _role == null) return;
    _loading = true;
    notifyListeners();

    final results = await Future.wait([
      for (final kind in AttentionKind.values)
        if (_enabled(kind)) _fetchSafely(kind) else Future.value(null),
    ]);

    var failures = 0;
    var attempted = 0;
    for (var i = 0; i < AttentionKind.values.length; i++) {
      final kind = AttentionKind.values[i];
      if (!_enabled(kind)) continue;
      attempted++;
      final items = results[i];
      // A failed source keeps its last good list instead of blanking out.
      if (items == null) {
        failures++;
      } else {
        _items[kind] = items;
      }
    }

    _error = attempted > 0 && failures == attempted
        ? 'Could not reach the server. Pull again shortly.'
        : null;
    _hasLoaded = true;
    _loading = false;
    notifyListeners();
  }

  Future<void> markRead(AttentionKind kind) async {
    final items = _items[kind] ?? const [];
    if (kind == AttentionKind.feedback) {
      await Future.wait(items.map((i) => FeedbackService.instance.markRead(i.id).catchError((_) {})));
      _items[kind] = const [];
    } else {
      _seen.addAll(items.map((i) => _key(kind, i)));
      await _saveSeen();
    }
    notifyListeners();
  }

  Future<void> markAllRead() async {
    for (final kind in AttentionKind.values) {
      if (_enabled(kind)) await markRead(kind);
    }
  }

  // --- Sources ---------------------------------------------------------------

  Future<List<AttentionItem>?> _fetchSafely(AttentionKind kind) async {
    try {
      return await _fetch(kind);
    } catch (e) {
      debugPrint('AttentionCenter: $kind failed: $e');
      return null;
    }
  }

  Future<List<AttentionItem>> _fetch(AttentionKind kind) async {
    switch (kind) {
      case AttentionKind.purchases:
        final res = await InvestmentService.instance.fetchPending();
        if (!res.success) throw Exception(res.message);
        return [
          for (final p in res.data ?? const [])
            AttentionItem(
              id: '${p.id}',
              headline: _join([p.userName, _money(p.totalValue)]),
              at: p.createdAt,
            ),
        ];

      case AttentionKind.accounts:
        final res = await AdminUsersService.instance.fetchUsers();
        if (!res.success) throw Exception(res.message);
        return [
          for (final u in res.data ?? const [])
            if (u.status.trim().toUpperCase() == 'PENDING')
              AttentionItem(
                id: '${u.id}',
                headline: _join([u.name, u.email]),
                at: u.createdAt,
              ),
        ];

      case AttentionKind.kyc:
        final rows = await IdentityVerificationService.instance
            .fetchRequests(filter: IdentityFilter.pending);
        return [
          for (final r in rows)
            AttentionItem(
              id: r.id,
              headline: _join([r.name, r.customerId]),
              at: r.submittedAt,
            ),
        ];

      case AttentionKind.cashback:
        final res = await CashbackApplicationService.instance
            .fetchApplications(status: CashbackStatus.pending);
        if (!res.success) throw Exception(res.message);
        return [
          for (final a in res.data?.applications ?? const <CashbackApplication>[])
            AttentionItem(
              id: '${a.id}',
              headline: _join([a.customerName, _money(a.purchaseAmount)]),
              at: a.createdAt,
            ),
        ];

      case AttentionKind.feedback:
        final feed = await FeedbackService.instance.fetchFeedback();
        return [
          for (final f in feed.inbox)
            if (!f.isRead)
              AttentionItem(
                id: f.id,
                headline: _join([
                  (f.fromName?.trim().isNotEmpty ?? false) ? f.fromName! : 'Customer',
                  f.subject.trim().isEmpty ? 'Feedback' : f.subject,
                ]),
                at: DateTime.tryParse(f.createdAt),
              ),
        ];
    }
  }

  // --- Config ----------------------------------------------------------------

  static String _titleFor(AttentionKind kind) => switch (kind) {
        AttentionKind.purchases => 'Purchases awaiting approval',
        AttentionKind.accounts => 'Accounts awaiting access',
        AttentionKind.kyc => 'KYC to verify',
        AttentionKind.cashback => 'Cashback applications',
        AttentionKind.feedback => 'Unread customer feedback',
      };

  static String _routeFor(AttentionKind kind) => switch (kind) {
        AttentionKind.purchases => '/purchases',
        AttentionKind.accounts => '/users',
        AttentionKind.kyc => '/identity-verification',
        AttentionKind.cashback => '/cashback-applications',
        AttentionKind.feedback => '/feedback',
      };

  /// Only queues the signed-in role can actually open are fetched/shown.
  bool _enabled(AttentionKind kind) {
    final role = _role;
    if (role == null || role == UserRole.customer) return false;
    return PermissionService.canAccess(_routeFor(kind), role);
  }

  bool get _anyEnabled => AttentionKind.values.any(_enabled);

  // --- Helpers ---------------------------------------------------------------

  String _money(double v) => v > 0 ? _inr.format(v) : '';

  static String _join(List<String?> parts) => parts
      .where((p) => p != null && p.trim().isNotEmpty)
      .map((p) => p!.trim())
      .join(' · ');

  static String _key(AttentionKind kind, AttentionItem item) => '${kind.name}:${item.id}';

  bool _isSeen(AttentionKind kind, AttentionItem item) =>
      kind != AttentionKind.feedback && _seen.contains(_key(kind, item));

  String get _prefsKey => 'attention_seen_${_userId ?? 'anon'}';

  Future<Set<String>> _loadSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_prefsKey) ?? const []).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveSeen() async {
    try {
      // Drop keys for items that are no longer pending so the set can't grow forever.
      final live = {
        for (final e in _items.entries)
          for (final i in e.value) _key(e.key, i),
      };
      _seen = _seen.where(live.contains).toSet();
      final list = _seen.toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsKey,
        list.length > _maxSeenKeys ? list.sublist(list.length - _maxSeenKeys) : list,
      );
    } catch (_) {}
  }
}
