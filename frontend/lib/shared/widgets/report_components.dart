import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

/// Building blocks shared by the "Analytical Command Node" report screens
/// (cashback, transactions): header, velocity chart, efficiency/registry
/// cards and the protocol-history registry.

class ReportColors {
  ReportColors._();
  static const navy = Color(0xFF1E3A8A);
  static const gold = Color(0xFFD97706);
  static const goldCard = Color(0xFFC29B38);
  static const muted = Color(0xFF94A3B8);
  static const red = Color(0xFFEF4444);
  static const tile = Color(0xFFF8FAFC);
  static const chartBlue = Color(0xFF2563EB);
}

final _money = NumberFormat('#,##,##0.##', 'en_IN');
final _dateFmt = DateFormat('d/M/yyyy');
final reportTimeFormat = DateFormat('h:mm:ss a');

/// Indian grouping, up to 2 decimals: ₹2,36,67,602.8
String formatInr(double v) => '₹${_money.format(v)}';
String formatInrDigits(double v) => _money.format(v);

BoxDecoration reportWhiteCard({double radius = 32}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.kBorder),
    );

class ReportCardTitle extends StatelessWidget {
  final String text;
  const ReportCardTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: ReportColors.navy, letterSpacing: -0.3));
}

class ReportCardSubtitle extends StatelessWidget {
  final String text;
  const ReportCardSubtitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: ReportColors.muted.withValues(alpha: 0.9), letterSpacing: 1.2));
}

class ReportErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ReportErrorBanner({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: ReportColors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w600, fontSize: 12))),
          TextButton(onPressed: onRetry, child: const Text('RETRY')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class ReportHeader extends StatelessWidget {
  final String navyTitle; // e.g. CASHBACK
  final String goldTitle; // e.g. REPORTS
  final bool isMobile;
  final bool loading;
  final DateTime? lastSync;
  final VoidCallback onRefresh;

  const ReportHeader({
    super.key,
    required this.navyTitle,
    required this.goldTitle,
    required this.isMobile,
    required this.loading,
    required this.lastSync,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = isMobile ? 40.0 : 56.0;
    TextStyle titleStyle(Color c) =>
        TextStyle(fontSize: titleSize, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: c, height: 0.95, letterSpacing: -1.5);

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 32, height: 2, color: ReportColors.gold),
            const SizedBox(width: 10),
            const Flexible(
              child: Text('ANALYTICAL COMMAND NODE',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: ReportColors.gold, letterSpacing: 3)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(navyTitle, style: titleStyle(ReportColors.navy))),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(goldTitle, style: titleStyle(ReportColors.goldCard))),
        const SizedBox(height: 16),
        Container(
          width: isMobile ? 200 : 300,
          height: 2,
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [ReportColors.goldCard, Color(0x00C29B38)])),
        ),
        const SizedBox(height: 16),
        Text('HIGH-FIDELITY FISCAL INTELLIGENCE & ASSET OVERSIGHT',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: ReportColors.muted.withValues(alpha: 0.8), letterSpacing: 2)),
      ],
    );

    final mutedSmall = TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: ReportColors.muted.withValues(alpha: 0.8), letterSpacing: 1);
    final action = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: loading ? null : onRefresh,
          icon: loading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: ReportColors.gold))
              : const Icon(Icons.sync, size: 16),
          label: const Text('REFRESH PROTOCOL', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: ReportColors.gold,
            side: const BorderSide(color: Color(0xFFFDE68A)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            elevation: 2,
            shadowColor: ReportColors.gold.withValues(alpha: 0.15),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 10, color: ReportColors.muted.withValues(alpha: 0.8)),
            const SizedBox(width: 4),
            Text(loading ? 'SYNCING...' : 'LAST SYNC: ${lastSync == null ? '—' : reportTimeFormat.format(lastSync!)}', style: mutedSmall),
          ],
        ),
      ],
    );

    if (isMobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 24), action]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: title), const SizedBox(width: 24), action]);
  }
}

// ---------------------------------------------------------------------------
// Overview row: velocity chart + efficiency + registry
// ---------------------------------------------------------------------------

/// Chart card on the left, efficiency and registry stacked on the right;
/// everything stacks below 900px.
class ReportOverviewRow extends StatelessWidget {
  final double width;
  final double gap;
  final Widget velocity;
  final Widget efficiency;
  final Widget registry;

  const ReportOverviewRow({
    super.key,
    required this.width,
    required this.gap,
    required this.velocity,
    required this.efficiency,
    required this.registry,
  });

  @override
  Widget build(BuildContext context) {
    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [efficiency, SizedBox(height: gap), registry],
    );
    if (width < 900) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [velocity, SizedBox(height: gap), side]);
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(flex: 2, child: velocity), SizedBox(width: gap), Expanded(child: side)],
      ),
    );
  }
}

class ReportVelocityCard extends StatelessWidget {
  final List<double> values;
  final bool loading;
  final bool isMobile;
  final String aggregateValue;
  final String nodeCount;
  final bool healthy;
  final Color lineColor;

  const ReportVelocityCard({
    super.key,
    required this.values,
    required this.loading,
    required this.isMobile,
    required this.aggregateValue,
    required this.nodeCount,
    required this.healthy,
    this.lineColor = ReportColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: reportWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReportCardTitle('TRANSMISSION VELOCITY'),
                    SizedBox(height: 4),
                    ReportCardSubtitle('TEMPORAL YIELD ANALYSIS (15D CYCLE)'),
                  ],
                ),
              ),
              SizedBox(width: 8),
              ReportPillBadge('LIVE NODE ACTIVE', dot: true),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: isMobile ? 160 : 220,
            width: double.infinity,
            child: loading
                ? const Center(child: AppLoader())
                : values.isEmpty
                    ? Center(child: Icon(Icons.monitor_heart_outlined, size: 48, color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)))
                    : CustomPaint(painter: ReportLineChartPainter(values, color: lineColor)),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: AppColors.kBorder),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _stat('AGGREGATE VALUE', aggregateValue, ReportColors.navy)),
              Expanded(child: _stat('NODE COUNT', nodeCount, ReportColors.navy)),
              Expanded(child: _stat('PROTOCOL STATUS', healthy ? 'OPTIMAL' : 'DEGRADED', ReportColors.goldCard)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: ReportColors.muted, letterSpacing: 1)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: color)),
        ),
      ],
    );
  }
}

class ReportEfficiencyCard extends StatelessWidget {
  final String efficiency;
  const ReportEfficiencyCard({super.key, required this.efficiency});

  @override
  Widget build(BuildContext context) {
    final label = TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 1.5);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFD4AF37), Color(0xFFB8902A)]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: ReportColors.gold.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 20),
          Text('MARKET EFFICIENCY', style: label),
          const SizedBox(height: 6),
          Text(efficiency, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white, height: 1)),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.north_east, color: Colors.white, size: 12),
              const SizedBox(width: 6),
              Text('INSTITUTIONAL GRADE', style: label),
            ],
          ),
        ],
      ),
    );
  }
}

class ReportRegistryCard extends StatelessWidget {
  final int registryCount;
  final VoidCallback? onExport;
  const ReportRegistryCard({super.key, required this.registryCount, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: reportWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
            child: const Icon(Icons.language, color: ReportColors.gold, size: 18),
          ),
          const SizedBox(height: 20),
          const Text('GLOBAL OPERATIONS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: ReportColors.muted, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('$registryCount NODE REGISTRY',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: ReportColors.navy)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.download, size: 14),
              label: const Text('EXPORT LEDGER', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ReportColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportPillBadge extends StatelessWidget {
  final String text;
  final bool dot;
  const ReportPillBadge(this.text, {super.key, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFDE68A))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: ReportColors.goldCard, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(text, style: const TextStyle(color: ReportColors.gold, fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

/// Line with a soft gradient fill underneath.
class ReportLineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  ReportLineChartPainter(this.values, {this.color = ReportColors.gold});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.reduce(math.max);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;
    const topPad = 8.0;
    final h = size.height - topPad;

    Offset point(int i) {
      final x = values.length == 1 ? size.width / 2 : i * size.width / (values.length - 1);
      return Offset(x, topPad + h - (values[i] / safeMax) * h * 0.92);
    }

    final line = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(point(i).dx, point(i).dy);
    }

    final fill = Path.from(line)
      ..lineTo(point(values.length - 1).dx, size.height)
      ..lineTo(point(0).dx, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant ReportLineChartPainter oldDelegate) => oldDelegate.values != values || oldDelegate.color != color;
}

// ---------------------------------------------------------------------------
// Protocol history registry
// ---------------------------------------------------------------------------

/// One registry line, already formatted for display.
class ReportHistoryRow {
  final String name;
  final String email;
  final String ref;
  final String? refDetail; // gold line under the ref, e.g. GOLD (8.000G)
  final String value;
  final String? valueDetail; // line under the value, e.g. GROSS · TDS · CHG
  final Color valueDetailColor;
  final String statusLabel;
  final String statusKey; // raw status, drives badge colour
  final DateTime? timestamp;

  const ReportHistoryRow({
    required this.name,
    required this.email,
    required this.ref,
    this.refDetail,
    required this.value,
    this.valueDetail,
    this.valueDetailColor = ReportColors.red,
    required this.statusLabel,
    required this.statusKey,
    required this.timestamp,
  });
}

class ReportHistoryCard extends StatelessWidget {
  final double width;
  final bool isMobile;
  final bool loading;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Widget? tabs; // optional tab chips shown next to the subtitle
  final TextEditingController searchController;
  final Widget filter;
  final List<ReportHistoryRow> rows;

  const ReportHistoryCard({
    super.key,
    required this.width,
    required this.isMobile,
    required this.loading,
    required this.searchController,
    required this.filter,
    required this.rows,
    this.icon = Icons.bolt_outlined,
    this.iconColor = ReportColors.goldCard,
    this.iconBackground = const Color(0xFFFFFBEB),
    this.tabs,
  });

  static const _colFlex = [5, 3, 3, 2, 2];

  @override
  Widget build(BuildContext context) {
    final asTable = width >= 760;
    final items = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) items.add(asTable ? const Divider(height: 1, color: Color(0xFFF1F5F9)) : const SizedBox(height: 12));
      items.add(asTable ? _tableRow(_cells(rows[i])) : Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _mobileCard(rows[i])));
    }

    return Container(
      decoration: reportWhiteCard(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: EdgeInsets.all(isMobile ? 20 : 32), child: _toolbar()),
          if (asTable) _tableHeader(),
          if (loading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: AppLoader()))
          else if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              child: Text('NO REGISTRY ENTRIES FOUND',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1), letterSpacing: 2)),
            )
          else
            ...items,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _toolbar() {
    final title = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PROTOCOL HISTORY',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: ReportColors.navy, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [const ReportCardSubtitle('IMMUTABLE TRANSACTION REGISTRY'), if (tabs != null) tabs!],
              ),
            ],
          ),
        ),
      ],
    );

    final search = SizedBox(
      height: 44,
      child: TextField(
        controller: searchController,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: 'SEARCH IDENTITY...',
          hintStyle: const TextStyle(color: ReportColors.muted, fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900, letterSpacing: 1),
          prefixIcon: const Icon(Icons.search, size: 18, color: ReportColors.muted),
          filled: true,
          fillColor: ReportColors.tile,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ReportColors.goldCard)),
        ),
      ),
    );

    final controls = Row(children: [Expanded(child: search), const SizedBox(width: 12), filter]);

    if (width < 1000) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [title, const SizedBox(height: 20), controls]);
    }
    return Row(children: [Expanded(flex: 5, child: title), const SizedBox(width: 24), Expanded(flex: 4, child: controls)]);
  }

  Widget _tableRow(List<Widget> cells, {EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 22)}) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: _colFlex[i],
              child: Padding(
                padding: EdgeInsets.only(right: i == cells.length - 1 ? 0 : 12),
                child: Align(alignment: i == cells.length - 1 ? Alignment.centerRight : Alignment.centerLeft, child: cells[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    const style = TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: ReportColors.muted, letterSpacing: 1.5);
    return Container(
      decoration: const BoxDecoration(
        color: ReportColors.tile,
        border: Border.symmetric(horizontal: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: _tableRow(
        const [
          Text('ENTITY NODE', style: style),
          Text('PROTOCOL REF', style: style),
          Text('VALUE (₹)', style: style),
          Text('STATUS', style: style),
          Text('TIMESTAMP', style: style),
        ],
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      ),
    );
  }

  List<Widget> _cells(ReportHistoryRow r) => [
        _entity(r.name, r.email),
        _ref(r.ref, r.refDetail),
        _value(r.value, r.valueDetail, r.valueDetailColor),
        ReportStatusBadge(label: r.statusLabel, status: r.statusKey),
        _timestamp(r.timestamp),
      ];

  /// Narrow-screen layout: same data stacked in a card.
  Widget _mobileCard(ReportHistoryRow r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _entity(r.name, r.email),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _value(r.value, r.valueDetail, r.valueDetailColor)),
              const SizedBox(width: 8),
              ReportStatusBadge(label: r.statusLabel, status: r.statusKey),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: _ref(r.ref, r.refDetail)), const SizedBox(width: 8), _timestamp(r.timestamp)],
          ),
        ],
      ),
    );
  }

  Widget _entity(String name, String email) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: Text(initial, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: ReportColors.muted)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name.isEmpty ? '—' : name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: ReportColors.navy, letterSpacing: -0.3)),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(email.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: ReportColors.muted, letterSpacing: 0.8)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _value(String value, String? detail, Color detailColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: ReportColors.navy, letterSpacing: -0.3)),
        if (detail != null) ...[
          const SizedBox(height: 4),
          Text(detail, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: detailColor, height: 1.4)),
        ],
      ],
    );
  }

  Widget _ref(String ref, String? detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(ref,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF64748B), letterSpacing: 1.2)),
        if (detail != null) ...[
          const SizedBox(height: 4),
          Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: ReportColors.goldCard)),
        ],
      ],
    );
  }

  Widget _timestamp(DateTime? dt) {
    if (dt == null) return const Text('—', style: TextStyle(color: ReportColors.muted));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_dateFmt.format(dt),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF475569), letterSpacing: 0.8)),
        const SizedBox(height: 3),
        Text(reportTimeFormat.format(dt), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: ReportColors.muted, letterSpacing: 0.8)),
      ],
    );
  }
}

class ReportStatusBadge extends StatelessWidget {
  final String label;
  final String status;
  const ReportStatusBadge({super.key, required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color border;
    final Color bg;
    switch (status) {
      case 'failed':
      case 'rejected':
      case 'cancelled':
        fg = const Color(0xFFDC2626);
        border = const Color(0xFFFECACA);
        bg = const Color(0xFFFEF2F2);
        break;
      case 'paused':
        fg = const Color(0xFF64748B);
        border = AppColors.kBorder;
        bg = ReportColors.tile;
        break;
      default: // completed, active, pending
        fg = const Color(0xFFB8902A);
        border = const Color(0xFFF5E1A4);
        bg = const Color(0xFFFFFBEB);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: fg, letterSpacing: 1.2)),
    );
  }
}

/// "ALL NODES" status filter. [options] maps raw status → display label.
class ReportStatusFilter extends StatelessWidget {
  final String? selected;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  const ReportStatusFilter({super.key, required this.selected, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Filter by status',
      onSelected: (value) => onChanged(value == '*' ? null : value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: '*', child: Text('ALL NODES')),
        for (final e in options.entries) PopupMenuItem(value: e.key, child: Text(e.value)),
      ],
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.kBorder), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_alt_outlined, size: 16, color: ReportColors.muted),
            const SizedBox(width: 8),
            Text(selected == null ? 'ALL NODES' : (options[selected] ?? selected!.toUpperCase()),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: ReportColors.navy)),
          ],
        ),
      ),
    );
  }
}

/// `GROSS ₹42,516.16 · TDS −₹2,125.81 · CHG −₹2,125.81`, or null when the
/// row carries no deduction breakdown.
String? deductionLine({double? gross, double? tds, double? charges}) {
  if (gross == null || gross <= 0) return null;
  return 'GROSS ${formatInr(gross)} · TDS −${formatInr(tds ?? 0)} · CHG −${formatInr(charges ?? 0)}';
}
