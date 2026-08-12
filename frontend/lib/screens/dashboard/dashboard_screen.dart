import 'dart:ui';
import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';

/// SmartFinance "Command Center" style dashboard.
///
/// Glassmorphism throughout: translucent frosted cards over a dark
/// navy backdrop, soft borders, subtle shadows.
///
/// TODO: replace the static values/lists below with data from the API
/// once the backend is available (e.g. GET /dashboard/summary).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser!;
    final isCustomer = user.role == UserRole.customer;

    return AppPage(
      title: 'Welcome back, ${user.name.split(' ').first}',
      subtitle:
          isCustomer ? 'Here is a snapshot of your account.' : 'Organization-wide overview.',
      children: [
        const _CommandCenterHeader(),
        const SizedBox(height: 20),
        _QuickActionsGrid(isCustomer: isCustomer),
        const SizedBox(height: 20),
        _StatCardsGrid(isCustomer: isCustomer),
        const SizedBox(height: 16),
        const _PendingCheckCard(proofCount: 0),
        const SizedBox(height: 24),
        const _GrowthTrendCard(),
        const SizedBox(height: 20),
        const _VolumeDensityCard(),
        const SizedBox(height: 20),
        const _RecentTransactionsCard(),
        const SizedBox(height: 20),
        const _PriorityFollowUpsCard(),
        const SizedBox(height: 24),
        const _SectionLabel('Broadcast Calendar'),
        const SizedBox(height: 12),
        const _BroadcastCalendarList(),
        const SizedBox(height: 24),
        const _SectionLabel('Global Operation Feed'),
        const SizedBox(height: 12),
        const _RealTimeActivityCard(),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared glass building blocks
// ---------------------------------------------------------------------------

/// Frosted-glass container used for every card on this page.
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.borderColor,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 22,
  });

  final Widget child;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor?.withOpacity(0.55) ?? Colors.white.withOpacity(0.14),
              width: borderColor != null ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: Colors.white.withOpacity(0.55),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _CommandCenterHeader extends StatelessWidget {
  const _CommandCenterHeader();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(
              color: AppColors.kSuccess,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Command Center',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'System Operational & Monitoring Secure',
                  style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.55)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions grid
// ---------------------------------------------------------------------------

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.isCustomer});
  final bool isCustomer;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      const _QuickAction('Field Collect', Icons.location_on_outlined, Color(0xFF6C8CFF)),
      const _QuickAction('Loan Stream', Icons.account_balance_outlined, Color(0xFFFF7597)),
      const _QuickAction('Add Member', Icons.person_add_alt_outlined, Color(0xFFFFB74D)),
      const _QuickAction('Verifications', Icons.verified_outlined, Color(0xFF7C6CFF)),
      const _QuickAction('Workspace', Icons.dashboard_customize_outlined, Color(0xFF4FC3F7)),
      const _QuickAction('Audit Hub', Icons.shield_outlined, Color(0xFF4CD9A6)),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        for (final a in actions)
          _GlassCard(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                // TODO: wire up navigation for "${a.label}".
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: a.color.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a.icon, color: a.color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      a.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stat cards grid (Active Members / Branches / Today's Collection / Overdue)
// ---------------------------------------------------------------------------

class _GlassStat {
  const _GlassStat({
    required this.icon,
    required this.title,
    required this.value,
    required this.footer,
    required this.color,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final String footer;
  final Color color;
  final Color? valueColor;
}

class _StatCardsGrid extends StatelessWidget {
  const _StatCardsGrid({required this.isCustomer});
  final bool isCustomer;

  @override
  Widget build(BuildContext context) {
    final stats = isCustomer
        ? const [
            _GlassStat(
              icon: Icons.account_balance_outlined,
              title: 'ACTIVE LOAN',
              value: '₹24,500',
              footer: 'Outstanding balance',
              color: AppColors.kPrimary,
            ),
            _GlassStat(
              icon: Icons.event_outlined,
              title: 'NEXT EMI DUE',
              value: '5 Sep',
              footer: 'Upcoming installment',
              color: AppColors.kWarning,
            ),
            _GlassStat(
              icon: Icons.check_circle_outline,
              title: 'PAID THIS YEAR',
              value: '₹18,900',
              footer: 'Total repayments',
              color: AppColors.kSuccess,
            ),
            _GlassStat(
              icon: Icons.support_agent_outlined,
              title: 'OPEN TICKETS',
              value: '0',
              footer: 'All clear',
              color: AppColors.kInfo,
            ),
          ]
        : const [
            _GlassStat(
              icon: Icons.people_outline,
              title: 'ACTIVE MEMBERS',
              value: '4',
              footer: 'Growth: +0% this month',
              color: AppColors.kSuccess,
            ),
            _GlassStat(
              icon: Icons.account_tree_outlined,
              title: 'BRANCHES',
              value: '2',
              footer: 'Network Active',
              color: AppColors.kInfo,
            ),
            _GlassStat(
              icon: Icons.payments_outlined,
              title: "TODAY'S COLLECTION",
              value: '₹0',
              footer: 'Unified Revenue',
              color: AppColors.kWarning,
            ),
            _GlassStat(
              icon: Icons.error_outline,
              title: 'TOTAL OVERDUE',
              value: '₹92,828',
              footer: 'Attention Required',
              color: AppColors.kDanger,
              valueColor: AppColors.kDanger,
            ),
          ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [for (final s in stats) _StatCard(stat: s)],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final _GlassStat stat;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderColor: stat.color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(stat.icon, size: 16, color: stat.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stat.title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: stat.valueColor ?? Colors.white.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.footer,
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending check
// ---------------------------------------------------------------------------

class _PendingCheckCard extends StatelessWidget {
  const _PendingCheckCard({required this.proofCount});
  final int proofCount;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderColor: AppColors.kInfo,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.kInfo.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_outlined, color: AppColors.kInfo),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PENDING CHECK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$proofCount',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PROOFS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Growth trend (line + area chart)
// ---------------------------------------------------------------------------

class _GrowthTrendCard extends StatelessWidget {
  const _GrowthTrendCard();

  // TODO: replace with real monthly totals from the reports API.
  static const _points = <double>[400, 2600, 200, 100, 9800, 2400];
  static const _labels = <String>['Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Growth Trend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total revenue collection timeline',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 13, color: Colors.white.withOpacity(0.7)),
                    const SizedBox(width: 6),
                    Text(
                      'Last 6 Months',
                      style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down,
                        size: 15, color: Colors.white.withOpacity(0.7)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(values: _points, labels: _labels, color: AppColors.kPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.values, required this.labels, required this.color});

  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 38.0;
    const bottomPad = 24.0;
    final chartWidth = size.width - leftPad;
    final chartHeight = size.height - bottomPad;

    final maxVal = (values.reduce((a, b) => a > b ? a : b)).clamp(1, double.infinity);
    final niceMax = (maxVal / 2000).ceil() * 2000.0;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10);

    // Horizontal grid lines + y-axis labels.
    for (var i = 0; i <= 6; i++) {
      final y = chartHeight - (chartHeight * i / 6);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      final labelVal = (niceMax * i / 6).round();
      final tp = TextPainter(
        text: TextSpan(text: '$labelVal', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Points.
    final dx = chartWidth / (values.length - 1);
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(leftPad + dx * i, chartHeight - (values[i] / niceMax) * chartHeight),
    ];

    // Smooth-ish path through points.
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    // Area fill under the curve.
    final areaPath = Path.from(path)
      ..lineTo(points.last.dx, chartHeight)
      ..lineTo(points.first.dx, chartHeight)
      ..close();
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.35), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(leftPad, 0, chartWidth, chartHeight));
    canvas.drawPath(areaPath, areaPaint);

    // Line stroke.
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Point dots + x-axis labels.
    final dotFill = Paint()..color = Colors.white;
    final dotRing = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3.5, dotFill);
      canvas.drawCircle(points[i], 3.5, dotRing);

      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, size.height - bottomPad + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

// ---------------------------------------------------------------------------
// Volume density (bar chart)
// ---------------------------------------------------------------------------

class _VolumeDensityCard extends StatelessWidget {
  const _VolumeDensityCard();

  // TODO: replace with real per-branch member counts.
  static const _bars = <String, double>{
    'Main Office': 1,
    "Teacher's Colony Branch": 3,
  };

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Volume Density',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Member distribution per Branch',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55)),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarChartPainter(values: _bars, color: AppColors.kInfo),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.values, required this.color});
  final Map<String, double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const bottomPad = 22.0;
    final chartHeight = size.height - bottomPad;
    final maxVal = values.values.reduce((a, b) => a > b ? a : b);
    final labelStyle = TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11);

    final entries = values.entries.toList();
    final slotWidth = size.width / entries.length;
    final barWidth = slotWidth * 0.32;

    for (var i = 0; i < entries.length; i++) {
      final ratio = entries[i].value / maxVal;
      final barHeight = chartHeight * ratio;
      final left = slotWidth * i + (slotWidth - barWidth) / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, chartHeight - barHeight, barWidth, barHeight),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.9), color.withOpacity(0.35)],
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);

      final tp = TextPainter(
        text: TextSpan(text: entries[i].key, style: labelStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 1,
      )..layout(maxWidth: slotWidth - 4);
      tp.paint(
        canvas,
        Offset(slotWidth * i + (slotWidth - tp.width) / 2, size.height - bottomPad + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => oldDelegate.values != values;
}

// ---------------------------------------------------------------------------
// Recent transactions
// ---------------------------------------------------------------------------

class _Transaction {
  const _Transaction(this.member, this.date, this.amount);
  final String member;
  final String date;
  final String amount;
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard();

  // TODO: replace with the latest transactions from the collections API.
  static const _transactions = <_Transaction>[
    _Transaction('Jessica', '10 Jul', '₹1000'),
    _Transaction('Varshini', '20 Apr', '₹1000'),
    _Transaction('Roki', '20 Apr', '₹1000'),
    _Transaction('Jessica', '15 Apr', '₹1000'),
    _Transaction('Roki', '10 Apr', '₹1000'),
  ];

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: navigate to the full transactions list.
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final t in _transactions) _TransactionRow(t: t),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.t});
  final _Transaction t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.kPrimary.withOpacity(0.2),
            child: Text(
              t.member.characters.first.toUpperCase(),
              style: const TextStyle(color: AppColors.kPrimary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.member,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  t.date,
                  style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          Text(
            t.amount,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.kSuccess.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'P',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.kSuccess),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.kSuccess.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat, size: 14, color: AppColors.kSuccess),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Priority follow-ups
// ---------------------------------------------------------------------------

class _PriorityFollowUpsCard extends StatelessWidget {
  const _PriorityFollowUpsCard();

  // TODO: populate from the overdue-installments API. Empty = all clear.
  static const _followUps = <Never>[];

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.kDanger.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Action Needed',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.kDanger),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Priority Follow-ups',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Members with pending or overdue installments',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55)),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: open the call list flow.
                },
                icon: const Icon(Icons.call_outlined, size: 15),
                label: const Text('Call List'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.9),
                  side: BorderSide(color: Colors.white.withOpacity(0.25)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_followUps.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.kSuccess, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'No pending follow-ups found. Excellent!',
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Broadcast calendar
// ---------------------------------------------------------------------------

class _BroadcastEvent {
  const _BroadcastEvent(this.group, this.round, this.date, this.status);
  final String group;
  final String round;
  final String date;
  final String status;
}

class _BroadcastCalendarList extends StatelessWidget {
  const _BroadcastCalendarList();

  // TODO: replace with scheduled broadcast rounds from the API.
  static const _events = <_BroadcastEvent>[
    _BroadcastEvent('Silver', 'Round #1', 'Monday, 20 Apr', 'Scheduled'),
    _BroadcastEvent('Gold', 'Round #2', 'Sunday, 10 May', 'Scheduled'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final e in _events) ...[
          _GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.kInfo.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.event_available_outlined,
                      size: 17, color: AppColors.kInfo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.group,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.92),
                        ),
                      ),
                      Text(
                        '${e.date} • ${e.round}',
                        style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.kInfo.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    e.status,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.kInfo),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Global operation feed / real-time activity
// ---------------------------------------------------------------------------

class _ActivityItem {
  const _ActivityItem(this.actor, this.timeAgo, this.description);
  final String actor;
  final String timeAgo;
  final String description;
}

class _RealTimeActivityCard extends StatelessWidget {
  const _RealTimeActivityCard();

  // TODO: replace with the live audit feed from the API.
  static const _items = <_ActivityItem>[
    _ActivityItem('Admin', '4 minutes ago', 'User admin successfully logged into the system.'),
    _ActivityItem('Admin', '1 day, 1 hour ago', 'User admin successfully logged into the system.'),
    _ActivityItem('Admin', '1 day, 2 hours ago', 'User admin successfully logged into the system.'),
    _ActivityItem(
        'Guna_Sekaran', '1 day, 2 hours ago', 'User Guna_Sekaran logged out of the session.'),
    _ActivityItem(
        'Guna_Sekaran', '1 day, 2 hours ago', 'User Guna_Sekaran successfully logged into the system.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Real-time Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: navigate to the Audit Hub page.
                },
                icon: const Icon(Icons.shield_outlined, size: 15),
                label: const Text('Audit Hub'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kSuccess,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _items.length; i++) _ActivityRow(item: _items[i], isFirst: i == 0),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, required this.isFirst});
  final _ActivityItem item;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.access_time, size: 14, color: Colors.white.withOpacity(0.6)),
              ),
              if (isFirst)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.kSuccess,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.actor,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.timeAgo,
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}