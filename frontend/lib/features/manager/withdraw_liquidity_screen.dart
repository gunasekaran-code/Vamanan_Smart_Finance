import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';

class WithdrawLiquidityScreen extends StatelessWidget {
  const WithdrawLiquidityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Liquidity Disbursement',
      subtitle: 'Manage and review pending liquidity disbursements.',
      children: [
        _buildLiquidityCard(context),
      ],
    );
  }

  Widget _buildLiquidityCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.kBorder.withOpacity(0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimary.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LIQUIDITY DISBURSEMENT\nQUEUE',
            style: TextStyle(
              color: AppColors.kPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 32),

          Expanded(
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: AppColors.kBorder,
                strokeWidth: 1.5,
                radius: 28,
                dashLength: 8,
                gapLength: 6,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.kBackground.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 72,
                      color: Color(0x26999999),
                    ),

                    SizedBox(height: 20),

                    Text(
                      'ALL DISBURSEMENTS FINALIZED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.2,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'There are no pending liquidity disbursements.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a dashed rounded rectangle without external packages.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gapLength;
  final double dashLength;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gapLength = 5.0,
    this.dashLength = 5.0,
    this.radius = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0;

      while (distance < pathMetric.length) {
        final double end = (distance + dashLength)
            .clamp(0, pathMetric.length)
            .toDouble();

        dashPath.addPath(
          pathMetric.extractPath(distance, end),
          Offset.zero,
        );

        distance += dashLength + gapLength;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        gapLength != oldDelegate.gapLength ||
        dashLength != oldDelegate.dashLength ||
        radius != oldDelegate.radius;
  }
}
