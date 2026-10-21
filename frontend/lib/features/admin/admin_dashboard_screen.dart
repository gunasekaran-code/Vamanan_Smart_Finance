import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// `intl` also exports a TextDirection type (with uppercase enum values),
// which shadows Flutter's `dart:ui` TextDirection used by TextPainter.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/investment_report_model.dart';
import 'package:frontend/services/admin_dashboard_service.dart';
import 'package:frontend/services/investment_report_service.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AdminDashboardService _service = AdminDashboardService();
  final InvestmentService _investmentService = InvestmentService();
  AdminDashboardData? _dashboard;
  bool _isLoading = true;
  String? _error;

  List<Investment> _recentInvestments = const [];
  bool _isLoadingInvestments = true;
  String? _investmentsError;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadRecentInvestments();
  }

  Future<void> _loadRecentInvestments() async {
    setState(() {
      _isLoadingInvestments = true;
      _investmentsError = null;
    });
    try {
      // investment_history.php returns processed cycles newest first.
      final history = await _investmentService.fetchInvestmentHistory();
      if (!mounted) return;
      setState(() => _recentInvestments = history.take(5).toList());
    } on InvestmentApiException catch (error) {
      if (mounted) setState(() => _investmentsError = error.message);
    } finally {
      if (mounted) setState(() => _isLoadingInvestments = false);
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dashboard = await _service.fetchDashboard();
      if (!mounted) return;
      setState(() => _dashboard = dashboard);
    } on AdminDashboardException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser!;

    return AppPage(
      title: 'Welcome back, ${user.name.split(' ').first}',
      subtitle: 'Organization-wide overview.',
      children: [
        const _StatusBanner(),
        const SizedBox(height: 16),
        if (_isLoading && _dashboard == null)
          const _DashboardLoadingState()
        else if (_error != null && _dashboard == null)
          _DashboardErrorState(message: _error!, onRetry: _loadDashboard)
        else ...[
          _StatCards2x2Grid(data: _dashboard!),
          const SizedBox(height: 24),
          _DashboardPair(
            first: _InstitutionalGrowthCard(data: _dashboard!),
            second: _InvestorNetworkPulseCard(data: _dashboard!),
          ),
          const SizedBox(height: 20),
          _DashboardPair(
            first: const _PayoutFlowCard(),
            second: _AlphaNetworkCard(data: _dashboard!),
            firstFlex: 2,
          ),
          const SizedBox(height: 20),
          _RecentInvestmentProtocolCard(
            investments: _recentInvestments,
            error: _investmentsError,
            isLoading: _isLoadingInvestments,
            onRetry: _loadRecentInvestments,
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

final _inrFormat =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

String _formatInr(double value) => _inrFormat.format(value);

String _compactInr(double value) {
  if (value >= 10000000) return '₹${(value / 10000000).toStringAsFixed(2)} Cr';
  if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(2)} L';
  return _formatInr(value);
}

class _DashboardPair extends StatelessWidget {
  const _DashboardPair({
    required this.first,
    required this.second,
    this.firstFlex = 1,
  });

  final Widget first;
  final Widget second;
  final int firstFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              const SizedBox(height: 20),
              second,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: firstFlex, child: first),
            const SizedBox(width: 20),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: AppLoader()),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined,
              color: AppColors.kPrimary, size: 32),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STYLED CARD CONTAINER
// ============================================================================
class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.borderColor,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 22,
  });

  final Widget child;
  final Color? borderColor;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ============================================================================
// TOP STATUS BANNER
// ============================================================================
class _StatusBanner extends StatelessWidget {
  const _StatusBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.kPrimary.withOpacity(0.85),
            AppColors.kPrimary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'SYSTEM STATUS: OPERATIONAL ONLINE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCards2x2Grid extends StatelessWidget {
  const _StatCards2x2Grid({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 4 : 2;
        final spacing = constraints.maxWidth < 360 ? 10.0 : 14.0;
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: 148,
          ),
          children: [
            _DashboardMetricCard(
              label: 'INSTITUTIONAL REVENUE',
              value: _compactInr(data.revenue),
              icon: Icons.bar_chart_rounded,
              color: AppColors.goldColor,
              background: AppColors.goldBg,
              badge: '↗ ₹0 · LAST 7 DAYS',
              footerLabel: 'EXACT',
              footerValue: _formatInr(data.revenue),
            ),
            _DashboardMetricCard(
              label: 'TOTAL PAYOUTS',
              value: _compactInr(data.payouts),
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.kPrimary,
              background: const Color(0xFFF8FAFC),
              badge: 'CASHBACK + REFERRAL · NET',
              footerLabel: 'TDS + CHARGES KEPT',
              footerValue: '₹4,21,197.60',
            ),
            _DashboardMetricCard(
              label: 'REGISTERED INVESTORS',
              value: data.users.toString(),
              icon: Icons.people_outline_rounded,
              color: const Color(0xFF2563EB),
              background: const Color(0xFFF0F7FF),
              badge:
                  '+${data.userHistory.fold<int>(0, (sum, item) => sum + item.value.toInt())} THIS WEEK',
              footerLabel: 'JOINED LAST 24H',
              footerValue: '${data.newUsersLast24h}',
            ),
            _DashboardMetricCard(
              label: 'ASSET INVENTORY',
              value: '${data.totalGoldWeight.toStringAsFixed(3)} g',
              icon: Icons.workspace_premium_outlined,
              color: AppColors.goldColor,
              background: AppColors.goldBg,
              badge: 'GOLD · ACTIVE HOLDINGS',
              footerLabel: 'SILVER RESERVE',
              footerValue: '${data.totalSilverWeight.toStringAsFixed(2)} g',
            ),
          ],
        );
      },
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    required this.badge,
    required this.footerLabel,
    required this.footerValue,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;
  final String badge;
  final String footerLabel;
  final String footerValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.kTextMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 17, color: color),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.kPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            constraints: const BoxConstraints(maxWidth: double.infinity),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  footerLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.kTextMuted,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  footerValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.kPrimary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INSTITUTIONAL GROWTH ANALYTICS
// ============================================================================
class _InstitutionalGrowthCard extends StatelessWidget {
  const _InstitutionalGrowthCard({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFC59B27);

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INSTITUTIONAL GROWTH ANALYTICS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.kPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'ROLLING 7-DAY REVENUE MATRIX',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.kTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.kPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: goldColor,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatInr(data.revenue),
                  style: const TextStyle(
                    color: AppColors.kPrimary,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const Text(
                'TOTAL LIQUID REVENUE',
                style: TextStyle(
                  color: AppColors.goldColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: Size.infinite,
              painter: _GoldGrowthChartPainter(points: data.revenueHistory),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldGrowthChartPainter extends CustomPainter {
  const _GoldGrowthChartPainter({required this.points});

  final List<AdminDashboardPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const goldColor = Color(0xFFC59B27);
    final chartHeight = size.height - 26;

    if (points.isEmpty) return;
    final maxValue =
        points.map((point) => point.value).reduce((a, b) => a > b ? a : b);
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = chartHeight * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final chartPoints = points.asMap().entries.map((entry) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * entry.key / (points.length - 1);
      final normalized = maxValue == 0
          ? 0.85
          : 1 - (entry.value.value / maxValue * 0.75 + 0.1);
      return Offset(x, chartHeight * normalized);
    }).toList();

    final path = Path()..moveTo(chartPoints.first.dx, chartPoints.first.dy);
    for (var i = 0; i < chartPoints.length - 1; i++) {
      final p0 = chartPoints[i];
      final p1 = chartPoints[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(chartPoints.last.dx, chartPoints.last.dy);

    // Gradient Fill
    final areaPath = Path.from(path)
      ..lineTo(size.width, chartHeight)
      ..lineTo(0, chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          goldColor.withOpacity(0.25),
          goldColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));

    canvas.drawPath(areaPath, fillPaint);

    // Stroke
    final linePaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Dots
    final dotPaint = Paint()..color = goldColor;
    final dotInner = Paint()..color = Colors.white;

    for (var p in chartPoints) {
      canvas.drawCircle(p, 4.5, dotPaint);
      canvas.drawCircle(p, 2.5, dotInner);
    }

    for (var i = 0; i < points.length; i++) {
      final painter = TextPainter(
        text: TextSpan(
          text: points[i].label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.kTextMuted,
            fontSize: 7,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = points.length == 1
          ? (size.width - painter.width) / 2
          : size.width * i / (points.length - 1) - painter.width / 2;
      painter.paint(canvas, Offset(x, chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _GoldGrowthChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

// ============================================================================
// INVESTOR NETWORK PULSE
// ============================================================================
class _InvestorNetworkPulseCard extends StatelessWidget {
  const _InvestorNetworkPulseCard({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVESTOR NETWORK PULSE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.kPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'ROLLING 7-DAY ENROLLMENT MATRIX',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.kTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.kPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.users} Entities',
                style: const TextStyle(
                  color: AppColors.kPrimary,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Text(
                'LIVE SYNCHRONIZATION',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BluePulseChartPainter(points: data.userHistory),
            ),
          ),
        ],
      ),
    );
  }
}

class _BluePulseChartPainter extends CustomPainter {
  const _BluePulseChartPainter({required this.points});

  final List<AdminDashboardPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 26;
    if (points.isEmpty) return;

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = chartHeight * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maxValue =
        points.map((point) => point.value).reduce((a, b) => a > b ? a : b);
    final chartPoints = points.asMap().entries.map((entry) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * entry.key / (points.length - 1);
      final normalized =
          maxValue == 0 ? 0.85 : 0.85 - (entry.value.value / maxValue * 0.72);
      return Offset(x, chartHeight * normalized);
    }).toList();

    final path = Path()..moveTo(chartPoints.first.dx, chartPoints.first.dy);
    for (var i = 0; i < chartPoints.length - 1; i++) {
      final p0 = chartPoints[i];
      final p1 = chartPoints[i + 1];
      final midpoint = (p0.dx + p1.dx) / 2;
      path.quadraticBezierTo(p0.dx, p0.dy, midpoint, (p0.dy + p1.dy) / 2);
    }
    path.lineTo(chartPoints.last.dx, chartPoints.last.dy);

    final areaPath = Path.from(path)
      ..lineTo(chartPoints.last.dx, chartHeight)
      ..lineTo(chartPoints.first.dx, chartHeight)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF3478F6).withOpacity(0.22),
          const Color(0xFF3478F6).withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
    canvas.drawPath(areaPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.kPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    for (var i = 0; i < chartPoints.length; i++) {
      final point = chartPoints[i];
      canvas.drawCircle(point, 4.5, Paint()..color = AppColors.kPrimary);
      canvas.drawCircle(point, 2.5, Paint()..color = Colors.white);

      final label = TextPainter(
        text: TextSpan(
          text: points[i].label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.kTextMuted,
            fontSize: 7,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = points.length == 1
          ? (size.width - label.width) / 2
          : point.dx - label.width / 2;
      label.paint(canvas, Offset(x, chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _BluePulseChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _PayoutFlowCard extends StatelessWidget {
  const _PayoutFlowCard();

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD6B331);
    const blue = Color(0xFF3478F6);
    const muted = Color(0xFF94A3B8);

    return _DashboardCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAYOUT FLOW',
                      style: TextStyle(
                        color: AppColors.kPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'MONTHLY CASHBACK + FLAT 2% REFERRAL · PAID TO WALLETS',
                      style: TextStyle(
                        color: AppColors.kTextMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '●  LIVE',
                style: TextStyle(
                  color: AppColors.goldColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _payoutRow(
            title: 'MONTHLY CASHBACK PAID',
            subtitle: 'NET TO WALLETS, AFTER REVERSALS',
            amount: '₹37.39 L',
            progress: 0.92,
            color: gold,
          ),
          const SizedBox(height: 16),
          _payoutRow(
            title: 'REFERRAL PAID',
            subtitle: '2% PER REFERRED PURCHASE · ONCE',
            amount: '₹3.39 L',
            progress: 0.09,
            color: blue,
          ),
          const SizedBox(height: 16),
          _payoutRow(
            title: 'TDS + CHARGES WITHHELD',
            subtitle: 'DEDUCTED BEFORE CREDITING',
            amount: '₹4.21 L',
            progress: 0.12,
            color: muted,
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(
                child: _PayoutStatusTile(
                  label: 'RUNNING PLANS',
                  value: '42',
                  color: Color(0xFFC59B27),
                  background: Color(0xFFFFFBF0),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _PayoutStatusTile(
                  label: 'COMPLETED',
                  value: '0',
                  color: Color(0xFF2563EB),
                  background: Color(0xFFEFF6FF),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _PayoutStatusTile(
                  label: 'AWAITING APPROVAL',
                  value: '1',
                  color: Color(0xFFEF4444),
                  background: Color(0xFFFEF2F2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.kPrimary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CASHBACK DUE NEXT MONTH',
                        style: TextStyle(
                          color: Color(0xFFE8C54D),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'GROSS · ONE INSTALLMENT PER RUNNING PLAN (10%)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '₹18.81 L',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _PayoutFooterMetric(
                  label: 'REFERRAL PAID',
                  value: '₹3.39 L',
                  icon: Icons.trending_up_rounded,
                ),
              ),
              Expanded(
                child: _PayoutFooterMetric(
                  label: 'REFERRED MEMBERS',
                  value: '90',
                  icon: Icons.people_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _payoutRow({
    required String title,
    required String subtitle,
    required String amount,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.kPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.kTextMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: const TextStyle(
                color: AppColors.kPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _PayoutStatusTile extends StatelessWidget {
  const _PayoutStatusTile({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 7,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutFooterMetric extends StatelessWidget {
  const _PayoutFooterMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF0),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.goldColor, size: 17),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.kTextMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.kPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ALPHA NETWORK (DARK NAVY SECTION)
// ============================================================================
class _AlphaNetworkCard extends StatelessWidget {
  const _AlphaNetworkCard({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    const goldAccent = Color(0xFFC59B27);
    final topReferrers = data.topReferrers.take(5).toList();
    final topFiveEarnings = topReferrers.fold<double>(
        0, (total, referrer) => total + referrer.earnings);
    final topFiveDirects = topReferrers.fold<int>(
        0, (total, referrer) => total + referrer.referrals);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kPrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: goldAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ALPHA NETWORK',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'TOP 5 REFERRERS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          if (topReferrers.isEmpty)
            const Text('No referral activity available.',
                style: TextStyle(color: Colors.white70))
          else
            ...topReferrers.asMap().entries.map((entry) {
              final referrer = entry.value;
              return _leaderRow(
                '${entry.key + 1}',
                referrer,
                isGold: entry.key == 0,
              );
            }),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOP-5 COMMISSION',
                  style: TextStyle(
                    color: Color(0xFFE8C54D),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _compactInr(topFiveEarnings),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '#1 EARNS 10% · $topFiveDirects DIRECTS ACROSS TOP 5',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderRow(String rank, AdminReferrer referrer,
      {bool isGold = false}) {
    const goldAccent = Color(0xFFC59B27);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: isGold ? Border.all(color: goldAccent.withOpacity(0.5)) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isGold ? goldAccent : Colors.white24,
            child: Text(
              rank,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isGold ? AppColors.kPrimary : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referrer.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  referrer.referralCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE8C54D),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _compactInr(referrer.earnings),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isGold ? goldAccent : Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${referrer.referrals} DIRECTS',
                style: const TextStyle(
                  fontSize: 6,
                  fontWeight: FontWeight.w800,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RECENT INVESTMENT PROTOCOL
// ============================================================================
class _RecentInvestmentProtocolCard extends StatelessWidget {
  const _RecentInvestmentProtocolCard({
    required this.investments,
    required this.error,
    required this.isLoading,
    required this.onRetry,
  });

  final List<Investment> investments;
  final String? error;
  final bool isLoading;
  final VoidCallback onRetry;

  static const _gold = Color(0xFFB8962E);
  static const _muted = Color(0xFF94A3B8);
  static const _headerBg = Color(0xFFF8FAFC);
  static const _divider = Color(0xFFF1F5F9);

  static final _amountFmt = NumberFormat('#,##0.00');
  static final _dateFmt = DateFormat('d MMM yyyy');
  static final _timeFmt = DateFormat('hh:mm a');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 720;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, isWide),
          const SizedBox(height: 20),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isWide ? 40 : 24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                if (isWide) _tableHeader(),
                ..._body(isWide),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _header(BuildContext context, bool isWide) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT INVESTMENT PROTOCOL',
          style: TextStyle(
            fontSize: isWide ? 26 : 18,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: AppColors.kPrimary,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'LAST 5 PROCESSED INSTITUTIONAL ACQUISITIONS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            color: _muted,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );

    final button = OutlinedButton(
      onPressed: () => context.go('/purchase-history'),
      style: OutlinedButton.styleFrom(
        backgroundColor: _headerBg,
        foregroundColor: _muted,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'VIEW FULL AUDIT LOG',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.arrow_forward, size: 16),
        ],
      ),
    );

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 12), button],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: title), button],
    );
  }

  Widget _tableHeader() {
    Text label(String text) => Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: _muted,
            letterSpacing: 2,
          ),
        );

    return Container(
      color: _headerBg,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: Row(
        children: [
          Expanded(flex: 5, child: label('PROCESSING NODE')),
          Expanded(flex: 6, child: label('CUSTOMER')),
          Expanded(flex: 5, child: label('CAPITAL MATRIX')),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: label('STATUS CODE'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _body(bool isWide) {
    if (isLoading && investments.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: AppLoader()),
        ),
      ];
    }
    if (error != null && investments.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.kTextMuted)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ];
    }
    if (investments.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text('No processed investments yet.',
                style: TextStyle(color: AppColors.kTextMuted)),
          ),
        ),
      ];
    }

    return [
      for (var i = 0; i < investments.length; i++) ...[
        if (i > 0 || isWide) const Divider(height: 1, color: _divider),
        isWide ? _wideRow(investments[i]) : _compactRow(investments[i]),
      ],
    ];
  }

  Widget _wideRow(Investment inv) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Row(
        children: [
          Expanded(flex: 5, child: _dateBlock(inv)),
          Expanded(flex: 6, child: _customerBlock(inv)),
          Expanded(flex: 5, child: _capitalBlock(inv, amountSize: 22)),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: _statusChip(inv.status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactRow(Investment inv) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _customerBlock(inv)),
              const SizedBox(width: 8),
              _statusChip(inv.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _capitalBlock(inv, amountSize: 18)),
              const SizedBox(width: 8),
              _dateBlock(inv, alignEnd: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateBlock(Investment inv, {bool alignEnd = false}) {
    final date = inv.processedDate ?? inv.createdAt;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          date != null ? _dateFmt.format(date) : '-',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: AppColors.kPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          date != null ? _timeFmt.format(date) : '',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            color: _muted,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _customerBlock(Investment inv) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          inv.userName.isEmpty
              ? 'UNKNOWN INVESTOR'
              : inv.userName.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: AppColors.kPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          inv.userEmail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.kTextMuted,
          ),
        ),
      ],
    );
  }

  Widget _capitalBlock(Investment inv, {required double amountSize}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '₹${_amountFmt.format(inv.totalValue)}',
            style: TextStyle(
              fontSize: amountSize,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: AppColors.kPrimary,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'YIELD: ₹${inv.dailyPayout.toStringAsFixed(2)}/DAY',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: _gold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _statusChip(InvestmentStatus status) {
    final color = switch (status) {
      InvestmentStatus.active => _gold,
      InvestmentStatus.rejected => AppColors.kDanger,
      _ => _muted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            investmentStatusLabel(status),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
