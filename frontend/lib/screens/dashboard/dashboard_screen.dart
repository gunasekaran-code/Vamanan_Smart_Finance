import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';

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

// Replaced _GlassCard with a clean, solid white card (iOS Style)
class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.borderColor,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 20,
  });

  final Widget child;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor?.withOpacity(0.3) ?? Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
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
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: Colors.grey.shade600,
      ),
    );
  }
}

class _CommandCenterHeader extends StatelessWidget {
  const _CommandCenterHeader();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              color: AppColors.kSuccess, // Green accent indicator
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Command Center',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'System Operational & Monitoring Secure',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
          _DashboardCard(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // TODO: wire up navigation for "${a.label}".
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: a.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a.icon, color: a.color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      a.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
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

class _StatData {
  const _StatData({
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
            _StatData(
              icon: Icons.account_balance_outlined,
              title: 'ACTIVE LOAN',
              value: '₹24,500',
              footer: 'Outstanding balance',
              color: AppColors.kPrimary,
            ),
            _StatData(
              icon: Icons.event_outlined,
              title: 'NEXT EMI DUE',
              value: '5 Sep',
              footer: 'Upcoming installment',
              color: AppColors.kWarning,
            ),
            _StatData(
              icon: Icons.check_circle_outline,
              title: 'PAID THIS YEAR',
              value: '₹18,900',
              footer: 'Total repayments',
              color: AppColors.kSuccess,
            ),
            _StatData(
              icon: Icons.support_agent_outlined,
              title: 'OPEN TICKETS',
              value: '0',
              footer: 'All clear',
              color: AppColors.kInfo,
            ),
          ]
        : const [
            _StatData(
              icon: Icons.people_outline,
              title: 'ACTIVE MEMBERS',
              value: '4',
              footer: 'Growth: +0% this month',
              color: AppColors.kSuccess,
            ),
            _StatData(
              icon: Icons.account_tree_outlined,
              title: 'BRANCHES',
              value: '2',
              footer: 'Network Active',
              color: AppColors.kInfo,
            ),
            _StatData(
              icon: Icons.payments_outlined,
              title: "TODAY'S COLLECTION",
              value: '₹0',
              footer: 'Unified Revenue',
              color: AppColors.kWarning,
            ),
            _StatData(
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
  final _StatData stat;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
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
                  color: stat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(stat.icon, size: 16, color: stat.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stat.title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Colors.grey.shade500,
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
              color: stat.valueColor ?? Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.footer,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PendingCheckCard extends StatelessWidget {
  const _PendingCheckCard({required this.proofCount});
  final int proofCount;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      borderColor: AppColors.kInfo,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.kInfo.withOpacity(0.12),
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
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$proofCount',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PROOFS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
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

class _GrowthTrendCard extends StatelessWidget {
  const _GrowthTrendCard();

  static const _points = <double>[400, 2600, 200, 100, 9800, 2400];
  static const _labels = <String>['Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Growth Trend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total revenue collection timeline',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 13, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Last 6 Months',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down,
                        size: 15, color: Colors.grey.shade700),
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
              painter: _LineChartPainter(
                  values: _points, labels: _labels, color: AppColors.kSuccess), // Changed to Green
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
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    final labelStyle = TextStyle(color: Colors.grey.shade500, fontSize: 10);

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
        colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
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

class _VolumeDensityCard extends StatelessWidget {
  const _VolumeDensityCard();

  static const _bars = <String, double>{
    'Main Office': 1,
    "Teacher's Colony Branch": 3,
  };

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Volume Density',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Member distribution per Branch',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarChartPainter(values: _bars, color: AppColors.kSuccess), // Changed to Green
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
    final labelStyle = TextStyle(color: Colors.grey.shade500, fontSize: 11);

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
          colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
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

class _Transaction {
  const _Transaction(this.member, this.date, this.amount);
  final String member;
  final String date;
  final String amount;
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard();

  static const _transactions = <_Transaction>[
    _Transaction('Jessica', '10 Jul', '₹1000'),
    _Transaction('Varshini', '20 Apr', '₹1000'),
    _Transaction('Roki', '20 Apr', '₹1000'),
    _Transaction('Jessica', '15 Apr', '₹1000'),
    _Transaction('Roki', '10 Apr', '₹1000'),
  ];

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
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
            backgroundColor: AppColors.kSuccess.withOpacity(0.15),
            child: Text(
              t.member.characters.first.toUpperCase(),
              style: const TextStyle(color: AppColors.kSuccess, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.member,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  t.date,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            t.amount,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.kSuccess.withOpacity(0.15),
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
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat, size: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _PriorityFollowUpsCard extends StatelessWidget {
  const _PriorityFollowUpsCard();

  static const _followUps = <Never>[];

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
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
                            color: AppColors.kDanger.withOpacity(0.1),
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
                    const Text(
                      'Priority Follow-ups',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Members with pending or overdue installments',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.call_outlined, size: 15, color: Colors.black87),
                label: const Text('Call List', style: TextStyle(color: Colors.black87)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
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
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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

class _BroadcastEvent {
  const _BroadcastEvent(this.group, this.round, this.date, this.status);
  final String group;
  final String round;
  final String date;
  final String status;
}

class _BroadcastCalendarList extends StatelessWidget {
  const _BroadcastCalendarList();

  static const _events = <_BroadcastEvent>[
    _BroadcastEvent('Silver', 'Round #1', 'Monday, 20 Apr', 'Scheduled'),
    _BroadcastEvent('Gold', 'Round #2', 'Sunday, 10 May', 'Scheduled'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final e in _events) ...[
          _DashboardCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.kSuccess.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.event_available_outlined,
                      size: 17, color: AppColors.kSuccess),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.group,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${e.date} • ${e.round}',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // This completes the code that was truncated in your prompt
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.kSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    e.status,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kSuccess,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// Added the missing RealTimeActivityCard to prevent errors
class _RealTimeActivityCard extends StatelessWidget {
  const _RealTimeActivityCard();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.feed_outlined, size: 32, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No recent activity to show',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}