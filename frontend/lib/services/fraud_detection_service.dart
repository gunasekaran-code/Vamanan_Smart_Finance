import 'dart:math' as math;

import '../models/admin_user_model.dart';
import '../models/fraud_detection_model.dart';
import '../models/genealogy_explorer_model.dart';
import 'admin_users_service.dart';
import 'genealogy_explorer_service.dart';

/// Thrown when the scan cannot get the data it needs. [message] is safe to
/// show to the user.
class FraudDetectionException implements Exception {
  final String message;
  FraudDetectionException(this.message);

  @override
  String toString() => message;
}

/// Referral-network integrity scan, computed entirely on the client.
///
/// The backend exposes no fraud endpoint and must not be changed, so every
/// rule here is derived from what the existing admin endpoints already
/// return:
///   * `admin/all_users.php`     — identity, sponsor edge, KYC, status, wallet
///   * `admin/get_genealogy.php` — per-node investment/payout totals
///
/// Rules fall into two passes:
///   * [_structuralRules] need only the flat user list (one request).
///   * [_financialRules] need the genealogy trees, which carry
///     `total_investment` / `total_earned` (one request per root).
/// The financial pass is best-effort: if it fails the scan still returns the
/// structural findings with [FraudScanResult.financialsIncluded] false, so a
/// partial scan is never mistaken for a clean one.
class FraudDetectionService {
  FraudDetectionService._();
  static final FraudDetectionService instance = FraudDetectionService._();

  // ---- Rule thresholds ---------------------------------------------------

  /// Direct signups under one sponsor inside [_burstWindow] before the
  /// cluster is treated as account stuffing.
  static const int _burstThreshold = 5;
  static const Duration _burstWindow = Duration(hours: 24);

  /// Length of an unbranched sponsor chain (every node has exactly one
  /// direct referral) that looks like pass-through accounts stacked to farm
  /// commission.
  static const int _chainStackingDepth = 4;

  /// Guard on the fan-out of per-root tree requests.
  static const int _treeFetchConcurrency = 4;

  final AdminUsersService _usersService = AdminUsersService.instance;
  final GenealogyService _genealogyService = GenealogyService();

  /// Scans the whole referral network.
  ///
  /// When [rootNodeId] is given the scan is narrowed to that account and its
  /// downline; otherwise every account is considered. Pass [preloadedTree]
  /// (the downline a screen has already fetched) to skip the financial
  /// round-trip entirely.
  Future<FraudScanResult> scan({
    String? rootNodeId,
    String? scopeLabel,
    List<GenealogyNode>? preloadedTree,
    bool includeFinancials = true,
  }) async {
    final users = await _loadUsers();

    List<GenealogyNode>? tree;
    if (includeFinancials) {
      try {
        tree = preloadedTree ?? await _loadTrees(rootNodeId: rootNodeId);
      } catch (_) {
        // Best effort — the structural findings still stand, and the result
        // reports that the payout checks did not run.
        tree = null;
      }
    }

    return analyze(
      users: users,
      tree: tree,
      rootNodeId: rootNodeId,
      scopeLabel: scopeLabel,
    );
  }

  /// Runs the rule engine over data the caller already holds — no network
  /// access. Used by [scan], and available to any screen that has the users
  /// (and optionally the genealogy tree) in hand already.
  FraudScanResult analyze({
    required List<AdminUserModel> users,
    List<GenealogyNode>? tree,
    String? rootNodeId,
    String? scopeLabel,
  }) {
    if (users.isEmpty) {
      return FraudScanResult.empty(scopeLabel ?? 'ENTIRE NETWORK');
    }

    final byId = {for (final u in users) u.id: u};
    final scoped =
        rootNodeId == null ? users : _scopeToSubtree(users, byId, rootNodeId);

    final alerts = <FraudAlert>[
      ..._structuralRules(scoped, byId),
      if (tree != null) ..._financialRules(tree),
    ];

    alerts.sort((a, b) {
      final bySeverity = a.severity.rank.compareTo(b.severity.rank);
      if (bySeverity != 0) return bySeverity;
      return b.subjectCount.compareTo(a.subjectCount);
    });

    return FraudScanResult(
      alerts: alerts,
      usersScanned: scoped.length,
      scopeLabel: scopeLabel ??
          (rootNodeId == null ? 'ENTIRE NETWORK' : 'SELECTED SUBTREE'),
      generatedAt: DateTime.now(),
      financialsIncluded: tree != null,
    );
  }

  // ---- Data loading ------------------------------------------------------

  Future<List<AdminUserModel>> _loadUsers() async {
    final res = await _usersService.fetchUsers();
    if (!res.success || res.data == null) {
      throw FraudDetectionException(res.message);
    }
    return res.data!;
  }

  /// Downline trees carrying the financial totals. Without [rootNodeId] this
  /// walks every root the backend reports (capped at 20 server-side).
  Future<List<GenealogyNode>> _loadTrees({String? rootNodeId}) async {
    if (rootNodeId != null) {
      return _genealogyService.fetchDownline(rootNodeId);
    }

    final roots = await _genealogyService.fetchRootUsers();
    final collected = <GenealogyNode>[];
    for (var i = 0; i < roots.length; i += _treeFetchConcurrency) {
      final batch = roots.skip(i).take(_treeFetchConcurrency);
      final trees = await Future.wait(
        batch.map((r) => _genealogyService.fetchDownline(r.id)),
      );
      for (final t in trees) {
        collected.addAll(t);
      }
    }
    return collected;
  }

  /// Every account at or below [rootId] following the sponsor edge.
  List<AdminUserModel> _scopeToSubtree(
    List<AdminUserModel> users,
    Map<int, AdminUserModel> byId,
    String rootId,
  ) {
    final root = int.tryParse(rootId);
    if (root == null || !byId.containsKey(root)) return users;

    final childrenOf = <int, List<AdminUserModel>>{};
    for (final u in users) {
      final parent = u.referrerId;
      if (parent != null && parent != 0) {
        childrenOf.putIfAbsent(parent, () => []).add(u);
      }
    }

    final scoped = <AdminUserModel>[byId[root]!];
    final queue = <int>[root];
    final seen = <int>{root};
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final child in childrenOf[current] ?? const <AdminUserModel>[]) {
        if (seen.add(child.id)) {
          scoped.add(child);
          queue.add(child.id);
        }
      }
    }
    return scoped;
  }

  // ---- Structural rules --------------------------------------------------

  List<FraudAlert> _structuralRules(
    List<AdminUserModel> users,
    Map<int, AdminUserModel> byId,
  ) {
    return [
      ..._selfAndCircularReferrals(users, byId),
      ..._orphanSponsors(users, byId),
      ..._duplicateEmails(users),
      ..._duplicateNamesUnderSameSponsor(users, byId),
      ..._signupBursts(users, byId),
      ..._chainStacking(users, byId),
      ..._kycGaps(users),
      ..._restrictedAccountsWithNetwork(users),
      ..._dormantLinksWithDownline(users),
    ];
  }

  Iterable<FraudAlert> _selfAndCircularReferrals(
    List<AdminUserModel> users,
    Map<int, AdminUserModel> byId,
  ) sync* {
    final selfRef = <FraudSubject>[];
    final circular = <FraudSubject>[];

    for (final u in users) {
      final parent = u.referrerId;
      if (parent == null || parent == 0) continue;

      if (parent == u.id) {
        selfRef.add(_subject(u, 'Sponsored by their own account'));
        continue;
      }

      // Walk up; a revisit means the sponsor edges form a cycle.
      final path = <int>{u.id};
      var cursor = byId[parent];
      var hops = 0;
      while (cursor != null && hops < 64) {
        if (!path.add(cursor.id)) {
          circular.add(_subject(u, 'Sponsor chain loops back after $hops hop(s)'));
          break;
        }
        final next = cursor.referrerId;
        if (next == null || next == 0) break;
        cursor = byId[next];
        hops++;
      }
    }

    if (selfRef.isNotEmpty) {
      yield FraudAlert(
        id: 'SELF_REFERRAL',
        code: 'SELF_REFERRAL',
        severity: FraudSeverity.high,
        title: 'SELF-REFERRAL DETECTED',
        description:
            '${selfRef.length} account(s) are recorded as their own sponsor. '
            'Direct commission on these accounts pays the referrer back to themselves.',
        recommendation:
            'Clear the referrer link on these accounts and reverse any 2% direct commission already credited.',
        subjects: selfRef,
      );
    }

    if (circular.isNotEmpty) {
      yield FraudAlert(
        id: 'CIRCULAR_REFERRAL',
        code: 'CIRCULAR_REFERRAL',
        severity: FraudSeverity.high,
        title: 'CIRCULAR SPONSOR CHAIN',
        description:
            '${circular.length} account(s) sit in a sponsor loop. A cycle in the '
            'genealogy can make commission runs pay indefinitely and will stall a tree walk.',
        recommendation:
            'Break the loop by re-pointing one edge to a genuine sponsor, then audit commissions paid inside the cycle.',
        subjects: circular,
      );
    }
  }

  Iterable<FraudAlert> _orphanSponsors(
    List<AdminUserModel> users,
    Map<int, AdminUserModel> byId,
  ) sync* {
    final orphans = users
        .where((u) =>
            u.referrerId != null &&
            u.referrerId != 0 &&
            u.referrerId != u.id &&
            !byId.containsKey(u.referrerId))
        .map((u) => _subject(u, 'Sponsor #${u.referrerId} no longer exists'))
        .toList();

    if (orphans.isEmpty) return;
    yield FraudAlert(
      id: 'ORPHAN_SPONSOR',
      code: 'ORPHAN_SPONSOR',
      severity: FraudSeverity.medium,
      title: 'ORPHANED SPONSOR LINK',
      description:
          '${orphans.length} account(s) point at a sponsor record that is missing. '
          'Commission on these placements has nowhere legitimate to land.',
      recommendation:
          'Re-attach these accounts to a verified sponsor or mark them as root placements.',
      subjects: orphans,
    );
  }

  Iterable<FraudAlert> _duplicateEmails(List<AdminUserModel> users) sync* {
    final buckets = <String, List<AdminUserModel>>{};
    for (final u in users) {
      final key = _normalizeEmail(u.email);
      if (key.isEmpty) continue;
      buckets.putIfAbsent(key, () => []).add(u);
    }

    final subjects = <FraudSubject>[];
    for (final entry in buckets.entries) {
      if (entry.value.length < 2) continue;
      for (final u in entry.value) {
        subjects.add(_subject(
          u,
          '${entry.value.length} accounts resolve to ${entry.key}',
        ));
      }
    }

    if (subjects.isEmpty) return;
    yield FraudAlert(
      id: 'DUPLICATE_EMAIL',
      code: 'DUPLICATE_EMAIL',
      severity: FraudSeverity.high,
      title: 'SHARED / ALIASED EMAIL IDENTITY',
      description:
          '${subjects.length} account(s) collapse onto a shared mailbox once dot and '
          '"+tag" aliases are normalised — the standard way one person opens several accounts.',
      recommendation:
          'Require distinct KYC identity per account, or merge the duplicates and claw back referral credit between them.',
      subjects: subjects,
    );
  }

  Iterable<FraudAlert> _duplicateNamesUnderSameSponsor(
    List<AdminUserModel> users,
    Map<int, AdminUserModel> byId,
  ) sync* {
    final buckets = <String, List<AdminUserModel>>{};
    for (final u in users) {
      final parent = u.referrerId;
      if (parent == null || parent == 0) continue;
      final name = _normalizeName(u.name);
      if (name.isEmpty) continue;
      buckets.putIfAbsent('$parent|$name', () => []).add(u);
    }

    final subjects = <FraudSubject>[];
    for (final group in buckets.values) {
      if (group.length < 2) continue;
      for (final u in group) {
        subjects.add(_subject(
          u,
          '${group.length} same-name accounts under ${_sponsorLabel(u, byId)}',
        ));
      }
    }

    if (subjects.isEmpty) return;
    yield FraudAlert(
      id: 'DUPLICATE_NAME_SAME_SPONSOR',
      code: 'DUPLICATE_NAME_SAME_SPONSOR',
      severity: FraudSeverity.medium,
      title: 'REPEATED NAME UNDER ONE SPONSOR',
      description:
          '${subjects.length} account(s) repeat the same name beneath a single sponsor, '
          'a common signature of duplicated identities used to widen a leg.',
      recommendation:
          'Compare KYC documents across the group before releasing further payouts on that leg.',
      subjects: subjects,
    );
  }

  Iterable<FraudAlert> _signupBursts(
    List<AdminUserModel> users,
    Map<int, AdminUserModel> byId,
  ) sync* {
    final bySponsor = <int, List<AdminUserModel>>{};
    for (final u in users) {
      final parent = u.referrerId;
      if (parent == null || parent == 0 || u.createdAt == null) continue;
      bySponsor.putIfAbsent(parent, () => []).add(u);
    }

    final subjects = <FraudSubject>[];
    for (final entry in bySponsor.entries) {
      final group = entry.value..sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
      if (group.length < _burstThreshold) continue;

      // Sliding window over the sorted signup times.
      var start = 0;
      for (var end = 0; end < group.length; end++) {
        while (group[end].createdAt!.difference(group[start].createdAt!) >
            _burstWindow) {
          start++;
        }
        if (end - start + 1 < _burstThreshold) continue;

        final window = group.sublist(start, end + 1);
        final span = window.last.createdAt!.difference(window.first.createdAt!);
        for (final u in window) {
          subjects.add(_subject(
            u,
            '${window.length} signups under ${_sponsorLabel(u, byId)} in ${_humanizeDuration(span)}',
          ));
        }
        break; // One finding per sponsor is enough to trigger review.
      }
    }

    if (subjects.isEmpty) return;
    final deduped = _dedupeSubjects(subjects);
    yield FraudAlert(
      id: 'SIGNUP_BURST',
      code: 'SIGNUP_BURST',
      severity: FraudSeverity.high,
      title: 'BULK SIGNUP BURST',
      description:
          '${deduped.length} account(s) were created under the same sponsor within '
          '${_humanizeDuration(_burstWindow)}. Genuine recruitment rarely clusters this tightly.',
      recommendation:
          'Hold direct commission on the burst and verify each account has an independent KYC identity and funding source.',
      subjects: deduped,
    );
  }

  Iterable<FraudAlert> _chainStacking(
    List<AdminUserModel> users,
    Map<int, AdminUserModel> byId,
  ) sync* {
    final childrenOf = <int, List<AdminUserModel>>{};
    for (final u in users) {
      final parent = u.referrerId;
      if (parent != null && parent != 0 && parent != u.id) {
        childrenOf.putIfAbsent(parent, () => []).add(u);
      }
    }

    final scopedIds = users.map((u) => u.id).toSet();
    final consumed = <int>{};
    final subjects = <FraudSubject>[];

    for (final u in users) {
      if (consumed.contains(u.id)) continue;

      // Only start a chain at a node that is not itself an only-child link.
      final parent = u.referrerId;
      final parentIsSingleLink = parent != null &&
          parent != 0 &&
          scopedIds.contains(parent) &&
          (childrenOf[parent]?.length ?? 0) == 1;
      if (parentIsSingleLink) continue;

      final chain = <AdminUserModel>[u];
      var cursor = u;
      while ((childrenOf[cursor.id]?.length ?? 0) == 1) {
        final next = childrenOf[cursor.id]!.first;
        if (chain.any((c) => c.id == next.id)) break; // cycle guard
        chain.add(next);
        cursor = next;
      }

      if (chain.length < _chainStackingDepth) continue;
      for (final node in chain) {
        consumed.add(node.id);
        subjects.add(_subject(
          node,
          'Link ${chain.indexOf(node) + 1} of a ${chain.length}-deep single-child chain',
        ));
      }
    }

    if (subjects.isEmpty) return;
    yield FraudAlert(
      id: 'CHAIN_STACKING',
      code: 'CHAIN_STACKING',
      severity: FraudSeverity.medium,
      title: 'STACKED PASS-THROUGH CHAIN',
      description:
          '${subjects.length} account(s) form unbranched runs at least '
          '$_chainStackingDepth levels deep, every account in the run referring exactly '
          'one other. Stacking like this manufactures depth instead of recruiting.',
      recommendation:
          'Confirm each link in the chain has its own investment and KYC identity; collapse the placeholders otherwise.',
      subjects: subjects,
    );
  }

  Iterable<FraudAlert> _kycGaps(List<AdminUserModel> users) sync* {
    final childCount = <int, int>{};
    for (final u in users) {
      final parent = u.referrerId;
      if (parent != null && parent != 0) {
        childCount[parent] = (childCount[parent] ?? 0) + 1;
      }
    }

    final funded = <FraudSubject>[];
    final sponsoring = <FraudSubject>[];

    for (final u in users) {
      if (_isKycVerified(u.kycStatus)) continue;

      if (u.balance > 0) {
        funded.add(_subject(
          u,
          'Wallet holds ₹${u.balance.toStringAsFixed(0)} — KYC ${_kycLabel(u.kycStatus)}',
        ));
      }
      final children = childCount[u.id] ?? 0;
      if (children > 0) {
        sponsoring.add(_subject(
          u,
          'Sponsors $children account(s) — KYC ${_kycLabel(u.kycStatus)}',
        ));
      }
    }

    if (funded.isNotEmpty) {
      yield FraudAlert(
        id: 'KYC_GAP_FUNDED',
        code: 'KYC_GAP_FUNDED',
        severity: FraudSeverity.high,
        title: 'UNVERIFIED ACCOUNT HOLDING FUNDS',
        description:
            '${funded.length} account(s) carry a positive wallet balance without a '
            'verified KYC record — funds are payable to an unidentified holder.',
        recommendation:
            'Freeze withdrawals on these wallets until KYC clears.',
        subjects: funded,
      );
    }

    if (sponsoring.isNotEmpty) {
      yield FraudAlert(
        id: 'KYC_GAP_SPONSOR',
        code: 'KYC_GAP_SPONSOR',
        severity: FraudSeverity.medium,
        title: 'UNVERIFIED SPONSOR EARNING COMMISSION',
        description:
            '${sponsoring.length} unverified account(s) sit above a downline and so '
            'accrue the flat 2% direct commission.',
        recommendation:
            'Escrow the direct commission on these placements until the sponsor is verified.',
        subjects: sponsoring,
      );
    }
  }

  Iterable<FraudAlert> _restrictedAccountsWithNetwork(
    List<AdminUserModel> users,
  ) sync* {
    const restricted = {'SUSPENDED', 'BLOCKED', 'PENDING REVIEW', 'INACTIVE'};

    final childCount = <int, int>{};
    for (final u in users) {
      final parent = u.referrerId;
      if (parent != null && parent != 0) {
        childCount[parent] = (childCount[parent] ?? 0) + 1;
      }
    }

    final subjects = users
        .where((u) => restricted.contains(u.status) && (childCount[u.id] ?? 0) > 0)
        .map((u) => _subject(
              u,
              '${u.status} — still sponsoring ${childCount[u.id]} account(s)',
            ))
        .toList();

    if (subjects.isEmpty) return;
    yield FraudAlert(
      id: 'RESTRICTED_SPONSOR',
      code: 'RESTRICTED_SPONSOR',
      severity: FraudSeverity.medium,
      title: 'RESTRICTED ACCOUNT STILL SPONSORING',
      description:
          '${subjects.length} account(s) are suspended or under review yet remain '
          'active sponsors collecting commission on new placements.',
      recommendation:
          'Suspend commission accrual for the duration of the account restriction.',
      subjects: subjects,
    );
  }

  Iterable<FraudAlert> _dormantLinksWithDownline(
    List<AdminUserModel> users,
  ) sync* {
    final childCount = <int, int>{};
    for (final u in users) {
      final parent = u.referrerId;
      if (parent != null && parent != 0) {
        childCount[parent] = (childCount[parent] ?? 0) + 1;
      }
    }

    final subjects = users
        .where((u) => !u.referralActive && (childCount[u.id] ?? 0) > 0)
        .map((u) => _subject(
              u,
              'Referral link disabled but ${childCount[u.id]} placement(s) exist',
            ))
        .toList();

    if (subjects.isEmpty) return;
    yield FraudAlert(
      id: 'DORMANT_LINK_WITH_DOWNLINE',
      code: 'DORMANT_LINK_WITH_DOWNLINE',
      severity: FraudSeverity.low,
      title: 'DISABLED LINK WITH LIVE PLACEMENTS',
      description:
          '${subjects.length} account(s) have referrals recorded against a referral '
          'link that is switched off — the placements were made outside the normal flow.',
      recommendation:
          'Confirm these placements were entered deliberately by an operator, not injected.',
      subjects: subjects,
    );
  }

  // ---- Financial rules ---------------------------------------------------

  List<FraudAlert> _financialRules(List<GenealogyNode> tree) {
    final flat = <GenealogyNode>[];
    void walk(List<GenealogyNode> nodes) {
      for (final n in nodes) {
        flat.add(n);
        walk(n.downline);
      }
    }

    walk(tree);
    if (flat.isEmpty) return const [];

    // A node can surface under more than one root request; keep one copy.
    final seen = <String>{};
    final unique = flat.where((n) => seen.add(n.id)).toList();

    final overpaid = <FraudSubject>[];
    final ghostEarnings = <FraudSubject>[];

    for (final n in unique) {
      if (n.totalInvestment <= 0 && n.totalEarned > 0) {
        ghostEarnings.add(FraudSubject(
          id: n.id,
          name: n.name,
          systemId: n.systemId,
          detail: 'Paid ₹${n.totalEarned.toStringAsFixed(0)} against zero investment',
        ));
        continue;
      }
      if (n.totalInvestment > 0 && n.totalEarned > n.totalInvestment) {
        final pct = (n.totalEarned / n.totalInvestment) * 100;
        overpaid.add(FraudSubject(
          id: n.id,
          name: n.name,
          systemId: n.systemId,
          detail:
              'Paid ₹${n.totalEarned.toStringAsFixed(0)} on ₹${n.totalInvestment.toStringAsFixed(0)} '
              '(${pct.toStringAsFixed(0)}% of cycle value)',
        ));
      }
    }

    return [
      if (ghostEarnings.isNotEmpty)
        FraudAlert(
          id: 'EARNINGS_WITHOUT_INVESTMENT',
          code: 'EARNINGS_WITHOUT_INVESTMENT',
          severity: FraudSeverity.high,
          title: 'PAYOUT WITHOUT A CASHBACK CYCLE',
          description:
              '${ghostEarnings.length} account(s) have been paid although no cashback '
              'cycle value is recorded against them.',
          recommendation:
              'Trace these payouts to a source cycle; reverse them if none exists.',
          subjects: ghostEarnings,
        ),
      if (overpaid.isNotEmpty)
        FraudAlert(
          id: 'PAYOUT_OVER_CYCLE_VALUE',
          code: 'PAYOUT_OVER_CYCLE_VALUE',
          severity: FraudSeverity.high,
          title: 'PAYOUT EXCEEDS CYCLE VALUE',
          description:
              '${overpaid.length} account(s) have received more than the total value of '
              'their cashback cycles — the monthly yield run has over-credited them.',
          recommendation:
              'Stop further monthly yield on these cycles and reconcile the excess against the wallet ledger.',
          subjects: overpaid,
        ),
    ];
  }

  // ---- Helpers -----------------------------------------------------------

  FraudSubject _subject(AdminUserModel u, String detail) => FraudSubject(
        id: u.id.toString(),
        name: u.name.isEmpty ? 'UNNAMED ACCOUNT' : u.name,
        systemId: u.customerId.isNotEmpty
            ? u.customerId
            : (u.referralCode.isNotEmpty ? u.referralCode : '#${u.id}'),
        detail: detail,
      );

  List<FraudSubject> _dedupeSubjects(List<FraudSubject> subjects) {
    final seen = <String>{};
    return subjects.where((s) => seen.add(s.id)).toList();
  }

  String _sponsorLabel(AdminUserModel u, Map<int, AdminUserModel> byId) {
    final sponsor = u.referrerId == null ? null : byId[u.referrerId];
    if (sponsor == null) return 'sponsor #${u.referrerId}';
    return sponsor.name.isNotEmpty ? sponsor.name : 'sponsor #${sponsor.id}';
  }

  /// Lowercases, then collapses the aliases a single mailbox accepts:
  /// everything after `+` is dropped, and dots are stripped from Gmail-style
  /// local parts (where they are not significant).
  String _normalizeEmail(String raw) {
    final email = raw.trim().toLowerCase();
    final at = email.indexOf('@');
    if (at <= 0 || at == email.length - 1) return '';

    var local = email.substring(0, at);
    final domain = email.substring(at + 1);

    final plus = local.indexOf('+');
    if (plus >= 0) local = local.substring(0, plus);
    if (domain == 'gmail.com' || domain == 'googlemail.com') {
      local = local.replaceAll('.', '');
    }
    if (local.isEmpty) return '';
    return '$local@$domain';
  }

  String _normalizeName(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  bool _isKycVerified(String status) {
    final s = status.trim().toLowerCase();
    return s == 'verified' || s == 'approved';
  }

  String _kycLabel(String status) =>
      status.trim().isEmpty ? 'not submitted' : status.trim().toLowerCase();

  String _humanizeDuration(Duration d) {
    if (d.inMinutes < 1) return '${math.max(d.inSeconds, 1)}s';
    if (d.inHours < 1) return '${d.inMinutes} min';
    if (d.inHours < 48) return '${d.inHours}h';
    return '${d.inDays} days';
  }
}
