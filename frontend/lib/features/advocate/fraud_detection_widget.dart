import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

import '../../../models/fraud_detection_model.dart';
import '../../../models/genealogy_explorer_model.dart';
import '../../../services/fraud_detection_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

/// Live referral-network integrity panel.
///
/// Runs [FraudDetectionService.scan] against the existing admin endpoints and
/// renders the findings. Tapping a flagged account calls [onInspectSubject],
/// which the genealogy explorer wires to `NetworkNodesScreen` so an auditor
/// lands directly on that account's tree.
class FraudDetectionWidget extends StatefulWidget {
  /// Narrows the scan to this account and its downline. Null scans everything.
  final String? rootNodeId;

  /// Header caption for the scope, e.g. the root investor's name.
  final String? scopeLabel;

  /// Tree a parent screen has already fetched — passing it skips the
  /// financial round-trip.
  final List<GenealogyNode>? preloadedTree;

  /// Invoked with the `users.id` and display name of a flagged account.
  final void Function(String userId, String name)? onInspectSubject;

  /// Scan as soon as the widget mounts. Set false to require a manual tap.
  final bool autoScan;

  const FraudDetectionWidget({
    super.key,
    this.rootNodeId,
    this.scopeLabel,
    this.preloadedTree,
    this.onInspectSubject,
    this.autoScan = true,
  });

  @override
  State<FraudDetectionWidget> createState() => FraudDetectionWidgetState();
}

/// Public so a parent can hold a `GlobalKey<FraudDetectionWidgetState>` and
/// re-run the scan after it changes the network (e.g. a yield run).
class FraudDetectionWidgetState extends State<FraudDetectionWidget> {
  static const Color _navy = Color(0xFF1E3A8A);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _hairline = Color(0xFFF1F5F9);

  final FraudDetectionService _service = FraudDetectionService.instance;

  FraudScanResult? _result;
  bool _isScanning = false;
  String? _error;
  FraudSeverity? _filter;

  @override
  void initState() {
    super.initState();
    if (widget.autoScan) runScan();
  }

  @override
  void didUpdateWidget(covariant FraudDetectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-scan when the scope moves, or when the parent hands down a freshly
    // fetched tree (a pull-to-refresh on NetworkNodesScreen).
    if (widget.autoScan &&
        (oldWidget.rootNodeId != widget.rootNodeId ||
            !identical(oldWidget.preloadedTree, widget.preloadedTree))) {
      runScan();
    }
  }

  /// Re-runs the scan. Safe to call from a parent via the state key.
  Future<void> runScan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _error = null;
    });
    try {
      final result = await _service.scan(
        rootNodeId: widget.rootNodeId,
        scopeLabel: widget.scopeLabel,
        preloadedTree: widget.preloadedTree,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _isScanning = false;
        // Drop a filter that no longer matches anything.
        if (_filter != null && result.countOf(_filter!) == 0) _filter = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final scope = (widget.scopeLabel ?? _result?.scopeLabel ?? 'ENTIRE NETWORK')
        .toUpperCase();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FRAUD DETECTION',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: _navy)),
              const SizedBox(height: 4),
              Text(
                'INTEGRITY SCAN — $scope',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: _muted.withOpacity(0.8),
                    letterSpacing: 0.5),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Re-run scan',
          onPressed: _isScanning ? null : runScan,
          icon: _isScanning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: _navy),
                )
              : const Icon(Icons.refresh, size: 20, color: _navy),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isScanning && _result == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: AppLoader()),
      );
    }

    if (_error != null && _result == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: runScan, child: const Text('RETRY SCAN')),
          ],
        ),
      );
    }

    final result = _result;
    if (result == null) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: runScan,
          icon: const Icon(Icons.radar, size: 16),
          label: const Text('RUN SCAN'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRiskGauge(result),
        const SizedBox(height: 16),
        _buildSeverityChips(result),
        if (!result.financialsIncluded) ...[
          const SizedBox(height: 12),
          _buildPartialNotice(),
        ],
        const SizedBox(height: 16),
        const Divider(height: 1, color: _hairline),
        const SizedBox(height: 12),
        if (result.isClean) _buildCleanState() else _buildAlertList(result),
        const SizedBox(height: 12),
        _buildFooter(result),
      ],
    );
  }

  Widget _buildRiskGauge(FraudScanResult result) {
    final score = result.riskScore;
    final color = _riskColor(score);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$score',
                  style: TextStyle(
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: color)),
              const SizedBox(height: 2),
              Text('RISK SCORE',
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: color.withOpacity(0.7))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.riskLabel,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: color)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.flaggedAccounts} of ${result.usersScanned} accounts flagged',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChips(FraudScanResult result) {
    return Row(
      children: FraudSeverity.values.map((severity) {
        final count = result.countOf(severity);
        final selected = _filter == severity;
        final color = _severityColor(severity);
        return Expanded(
          child: Padding(
            padding:
                EdgeInsets.only(right: severity == FraudSeverity.low ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: count == 0
                  ? null
                  : () => setState(() => _filter = selected ? null : severity),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withOpacity(0.12)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected ? color : AppColors.kBorder,
                      width: selected ? 1.4 : 1),
                ),
                child: Column(
                  children: [
                    Text('$count',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: count == 0 ? _muted : color)),
                    const SizedBox(height: 2),
                    Text(severity.label,
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: count == 0 ? _muted : color)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPartialNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: Color(0xFFB45309)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Payout checks were skipped — genealogy totals could not be loaded. '
              'Structural findings only.',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.verified_user_outlined,
                color: Color(0xFF16A34A), size: 22),
          ),
          const SizedBox(height: 12),
          const Text('NO INTEGRITY ISSUES DETECTED',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF16A34A))),
          const SizedBox(height: 4),
          const Text('Every rule passed on this scan.',
              style: TextStyle(fontSize: 11, color: _muted)),
        ],
      ),
    );
  }

  Widget _buildAlertList(FraudScanResult result) {
    final alerts = _filter == null
        ? result.alerts
        : result.alerts.where((a) => a.severity == _filter).toList();

    if (alerts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No alerts at this severity.',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w600)),
        ),
      );
    }

    return Column(
      children: alerts.map(_buildAlertTile).toList(),
    );
  }

  Widget _buildAlertTile(FraudAlert alert) {
    final color = _severityColor(alert.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _hairline),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>(alert.id),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding:
              const EdgeInsets.only(left: 14, right: 14, bottom: 14),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(_severityIcon(alert.severity), size: 17, color: color),
          ),
          title: Text(alert.title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: _navy)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '${alert.severity.label} · ${alert.subjectCount} ACCOUNT(S)',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: color),
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(alert.description,
                  style: const TextStyle(
                      fontSize: 11.5, height: 1.45, color: Color(0xFF475569))),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RECOMMENDED ACTION',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: _muted)),
                  const SizedBox(height: 4),
                  Text(alert.recommendation,
                      style: const TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...alert.subjects.map((s) => _buildSubjectRow(s, color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectRow(FraudSubject subject, Color color) {
    final tappable = widget.onInspectSubject != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: tappable
            ? () => widget.onInspectSubject!(subject.id, subject.name)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center,
                child: Text(
                  subject.name.isNotEmpty
                      ? subject.name.substring(0, 1).toUpperCase()
                      : '?',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: color),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(subject.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: _navy)),
                        ),
                        const SizedBox(width: 6),
                        Text(subject.systemId,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _muted)),
                      ],
                    ),
                    if (subject.detail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subject.detail,
                          style: const TextStyle(
                              fontSize: 10,
                              height: 1.35,
                              color: Color(0xFF64748B))),
                    ],
                  ],
                ),
              ),
              if (tappable)
                const Icon(Icons.account_tree_outlined,
                    size: 15, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(FraudScanResult result) {
    final t = result.generatedAt;
    final stamp =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('LAST SCAN $stamp',
            style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: _muted)),
        Text('${result.alerts.length} RULE(S) TRIGGERED',
            style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: _muted)),
      ],
    );
  }

  Color _riskColor(int score) {
    if (score == 0) return const Color(0xFF16A34A);
    if (score < 20) return const Color(0xFF2563EB);
    if (score < 50) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  Color _severityColor(FraudSeverity severity) => switch (severity) {
        FraudSeverity.high => const Color(0xFFDC2626),
        FraudSeverity.medium => const Color(0xFFF59E0B),
        FraudSeverity.low => const Color(0xFF2563EB),
      };

  IconData _severityIcon(FraudSeverity severity) => switch (severity) {
        FraudSeverity.high => Icons.gpp_bad_outlined,
        FraudSeverity.medium => Icons.warning_amber_rounded,
        FraudSeverity.low => Icons.info_outline,
      };
}
