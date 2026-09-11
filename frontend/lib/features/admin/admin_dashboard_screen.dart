import 'package:flutter/material.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser!;

    return AppPage(
      title: 'Welcome back, ${user.name.split(' ').first}',
      subtitle: 'Organization-wide overview.',
      children: [
        const _StatusBanner(),
        const SizedBox(height: 16),
        const _StatCards2x2Grid(),
        const SizedBox(height: 24),
        const _InstitutionalGrowthCard(),
        const SizedBox(height: 20),
        const _InvestorNetworkPulseCard(),
        const SizedBox(height: 20),
        const _NetworkYieldMatrixCard(),
        const SizedBox(height: 20),
        const _AlphaNetworkCard(),
        const SizedBox(height: 20),
        const _RecentInvestmentProtocolCard(),
        const SizedBox(height: 24),
      ],
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
  const _StatCards2x2Grid({super.key});

  @override
  Widget build(BuildContext context) {

    // Responsive breakpoints for narrow screens
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 380;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: isSmallMobile ? 8.0 : 12.0,
      crossAxisSpacing: isSmallMobile ? 8.0 : 12.0,
      childAspectRatio: isSmallMobile ? 0.82 : 1.15,
      children: [
        const StatCard(
          label: 'Institutional Revenue',
          value: '₹34,60,429.72',
          icon: Icons.account_balance_wallet_outlined,
          // color: ,
          color: AppColors.goldColor,
          badgeText: '+12.4%',
          backgroundColor: AppColors.goldBg,
          borderColor: AppColors.goldBorder,
          badgeBackgroundColor: AppColors.goldBadgeBg,
          badgeTextColor: AppColors.goldColor,
        ),

        StatCard(
          label: 'Total Payouts',
          value: '₹0',
          icon: Icons.payments_outlined,
          color: AppColors.kPrimary,
          badgeText: '0.0%',
          backgroundColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
          badgeBackgroundColor: const Color(0xFFEDF2F7),
          badgeTextColor: AppColors.kPrimary,
        ),

        StatCard(
          label: 'Active Investors',
          value: '96',
          icon: Icons.group_outlined,
          color: const Color(0xFF3B82F6),
          badgeText: 'ACTIVE NOW',
          backgroundColor: const Color(0xFFF0F7FF),
          borderColor: const Color(0xFFBFDBFE),
          badgeBackgroundColor: const Color(0xFFDBEAFE),
          badgeTextColor: const Color(0xFF1D4ED8),
        ),

        const StatCard(
          label: 'Asset Inventory',
          value: '152.000g',
          icon: Icons.workspace_premium_outlined,
          color: AppColors.goldColor,
          badgeText: '24K Gold',
          backgroundColor: AppColors.goldBg,
          borderColor: AppColors.goldBorder,
          badgeBackgroundColor: AppColors.goldBadgeBg,
          badgeTextColor: AppColors.goldColor,
        ),
      ],
    );
  }
}




// ============================================================================
// INSTITUTIONAL GROWTH ANALYTICA
// ============================================================================
class _InstitutionalGrowthCard extends StatelessWidget {
  const _InstitutionalGrowthCard();

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
                      'INSTITUTIONAL GROWTH ANALYTICA',
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
                      'Real-time revenue & yield analytics timeline',
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
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: Size.infinite,
              painter: _GoldGrowthChartPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldGrowthChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const goldColor = Color(0xFFC59B27);
    final chartHeight = size.height - 20;

    final points = [
      Offset(0, chartHeight * 0.1),
      Offset(size.width * 0.15, chartHeight * 0.35),
      Offset(size.width * 0.3, chartHeight * 0.45),
      Offset(size.width * 0.45, chartHeight * 0.85),
      Offset(size.width * 0.6, chartHeight * 0.85),
      Offset(size.width * 0.75, chartHeight * 0.85),
      Offset(size.width, chartHeight * 0.85),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

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

    for (var p in points) {
      canvas.drawCircle(p, 4.5, dotPaint);
      canvas.drawCircle(p, 2.5, dotInner);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// INVESTOR NETWORK PULSE
// ============================================================================
class _InvestorNetworkPulseCard extends StatelessWidget {
  const _InvestorNetworkPulseCard();

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
                      'Active node connections & live streaming data',
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
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BluePulseChartPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BluePulseChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 20;

    final linePaint = Paint()
      ..color = AppColors.kPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final y = chartHeight * 0.7;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    final dotCount = 6;
    final dx = size.width / (dotCount - 1);

    for (var i = 0; i < dotCount; i++) {
      final pos = Offset(dx * i, y);
      canvas.drawCircle(pos, 5, Paint()..color = AppColors.kPrimary);
      canvas.drawCircle(pos, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// NETWORK YIELD MATRIX
// ============================================================================
class _NetworkYieldMatrixCard extends StatelessWidget {
  const _NetworkYieldMatrixCard();

  @override
  Widget build(BuildContext context) {
    const goldAccent = Color(0xFFC59B27);

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NETWORK YIELD MATRIX',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: AppColors.kPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: goldAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'LIVE YIELD',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: goldAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Multi-tier reward structures and current node shares',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.kTextMuted,
            ),
          ),
          const SizedBox(height: 16),
          _yieldRow('LEVEL 1', 'PRIMARY REFERRAL', '15%', goldAccent),
          _yieldRow('LEVEL 2', 'SECONDARY NETWORK', '8%', AppColors.kPrimary),
          _yieldRow('LEVEL 3', 'TERTIARY NODE', '5%', AppColors.kPrimary),
          _yieldRow('LEVEL 4', 'OVERRIDE PROTOCOL', '2%', goldAccent),
          _yieldRow('LEVEL 5', 'EXECUTIVE POOL', '1%', AppColors.kPrimary),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: goldAccent.withOpacity(0.2)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'ESTIMATED ROI',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.kTextMuted),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '+28.4%',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: goldAccent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.kPrimary.withOpacity(0.1)),
                  ),
                  child: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.kPrimary,
                  ).applyToColumn(
                    title: 'DAILY YIELD',
                    val: '2,450/Day',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _yieldRow(String level, String label, String percentage, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              level,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextMuted,
            ),
          ),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

extension on TextStyle {
  Widget applyToColumn({required String title, required String val}) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.kTextMuted),
        ),
        const SizedBox(height: 2),
        Text(val, style: this),
      ],
    );
  }
}

// ============================================================================
// ALPHA NETWORK (DARK NAVY SECTION)
// ============================================================================
class _AlphaNetworkCard extends StatelessWidget {
  const _AlphaNetworkCard();

  @override
  Widget build(BuildContext context) {
    const goldAccent = Color(0xFFC59B27);

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
          const SizedBox(height: 16),
          _leaderRow('1', 'DIRECTOR ONE', '₹12,50,000.00', goldAccent, isGold: true),
          _leaderRow('2', 'EXECUTIVE TWO', '₹8,75,000.00', Colors.white70),
          _leaderRow('3', 'MANAGER THREE', '₹5,40,000.00', Colors.white70),
          _leaderRow('4', 'LEAD FOUR', '₹3,20,000.00', Colors.white70),
          _leaderRow('5', 'ASSOCIATE FIVE', '₹1,80,000.00', Colors.white70),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SYSTEM MATRIX 2.0',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.75,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(goldAccent),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: goldAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.equalizer_rounded,
                    color: AppColors.kPrimary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderRow(String rank, String name, String amount, Color textColor, {bool isGold = false}) {
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
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isGold ? goldAccent : Colors.white,
            ),
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
  const _RecentInvestmentProtocolCard();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECENT INVESTMENT PROTOCOL',
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
            'Latest institutional ledger activities & deployments',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.kTextMuted,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LAST 30 DAYS ACTIVITY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.kTextMuted,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.kTextMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '10 Aug 2026',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.kPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '10:45 AM • Verified',
                      style: TextStyle(fontSize: 10, color: AppColors.kTextMuted),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹34,60,429.72',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'GOLD POOL ALLOCATION',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC59B27),
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