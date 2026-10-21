import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import '../../models/withdraw_liquidity_model.dart';
import '../../services/withdraw_liquidity_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class WithdrawLiquidityScreen extends StatefulWidget {
  const WithdrawLiquidityScreen({super.key});

  @override
  State<WithdrawLiquidityScreen> createState() =>
      _WithdrawLiquidityScreenState();
}

class _WithdrawLiquidityScreenState extends State<WithdrawLiquidityScreen> {
  final _service = WithdrawLiquidityService.instance;

  bool _loading = true;
  String? _error;
  List<WithdrawalRequest> _requests = const [];
  final Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Client-side guard only — withdrawals.php itself has no auth check.
    if (!SessionService.instance.isLoggedIn) {
      setState(() {
        _loading = false;
        _error = 'You must be signed in as an admin to view this queue.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await _service.fetchWithdrawals();

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _requests = (res.data ?? []).where((w) => w.isPending).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        _error = res.message ?? 'Failed to load withdrawals.';
      }
    });
  }

  Future<void> _act(WithdrawalRequest req, String status) async {
    final confirmed = await _confirm(req, status);
    if (confirmed != true) return;

    setState(() => _processingIds.add(req.id));

    final res = await _service.processWithdrawal(
      id: req.id,
      status: status,
    );

    if (!mounted) return;
    setState(() => _processingIds.remove(req.id));

    if (res.success) {
      setState(() => _requests.removeWhere((w) => w.id == req.id));
      _toast('Withdrawal #${req.id} marked as $status.');
    } else {
      _toast(res.message ?? 'Could not update this withdrawal.', error: true);
    }
  }

  Future<bool?> _confirm(WithdrawalRequest req, String status) {
    final approve = status == 'approved';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Approve withdrawal?' : 'Reject withdrawal?'),
        content: Text(
          '${req.userName} · ₹${req.amount.toStringAsFixed(2)}\n'
          '${req.paymentMethod}${req.bankDetails != null ? '\n${req.bankDetails}' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: approve ? Colors.green : Colors.red,
            ),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    // AppPage already scrolls, so the card grows with its content instead of
    // using a fixed height with a nested list (which overflowed on short
    // screens and in landscape).
    return RefreshIndicator(
      onRefresh: _load,
      child: AppPage(
        title: 'Liquidity Disbursement',
        subtitle: 'Manage and review pending liquidity disbursements.',
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: _buildLiquidityCard(context, isTablet: isTablet),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidityCard(BuildContext context, {required bool isTablet}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(isTablet ? 32 : 24),
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
      padding: EdgeInsets.all(isTablet ? 28 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expanded lets the title wrap instead of pushing the refresh
              // button off the card.
              Expanded(
                child: Text(
                  'LIQUIDITY DISBURSEMENT QUEUE',
                  style: TextStyle(
                    color: AppColors.kPrimary,
                    fontSize: isTablet ? 26 : 20,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          SizedBox(height: isTablet ? 32 : 24),
          _buildBody(context, isTablet: isTablet),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool isTablet}) {
    final minHeight = isTablet ? 420.0 : 300.0;

    if (_loading) {
      return SizedBox(
        height: minHeight,
        child: const Center(child: AppLoader()),
      );
    }

    if (_error != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: _buildEmptyState(
          icon: Icons.error_outline,
          title: 'COULD NOT LOAD QUEUE',
          subtitle: _error!,
          action: TextButton(onPressed: _load, child: const Text('Retry')),
        ),
      );
    }

    if (_requests.isEmpty) {
      return CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.kBorder,
          strokeWidth: 1.5,
          radius: 28,
          dashLength: 8,
          gapLength: 6,
        ),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.kBackground.withOpacity(0.4),
            borderRadius: BorderRadius.circular(28),
          ),
          child: _buildEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'ALL DISBURSEMENTS FINALIZED',
            subtitle: 'There are no pending liquidity disbursements.',
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _requests.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildRow(_requests[i], isTablet: isTablet),
        ],
      ],
    );
  }

  Widget _buildRow(WithdrawalRequest req, {required bool isTablet}) {
    final busy = _processingIds.contains(req.id);

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          req.userName.isNotEmpty ? req.userName : 'User #${req.userId}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          req.userEmail,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          '₹${req.amount.toStringAsFixed(2)}  ·  ${req.paymentMethod}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        if (req.bankDetails != null) ...[
          const SizedBox(height: 4),
          Text(
            req.bankDetails!,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Balance: ₹${req.currentBalance.toStringAsFixed(2)} · Requested ${req.createdAt}',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
        ),
      ],
    );

    const spinner = SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );

    final decoration = BoxDecoration(
      color: AppColors.kBackground.withOpacity(0.4),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.kBorder.withOpacity(0.6)),
    );

    // Tablet: compact icon actions beside the details.
    if (isTablet) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: decoration,
        child: Row(
          children: [
            Expanded(child: details),
            const SizedBox(width: 8),
            if (busy)
              spinner
            else ...[
              IconButton(
                onPressed: () => _act(req, 'rejected'),
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'Reject',
              ),
              IconButton(
                onPressed: () => _act(req, 'approved'),
                icon: const Icon(Icons.check, color: Colors.green),
                tooltip: 'Approve',
              ),
            ],
          ],
        ),
      );
    }

    // Phone: full-width buttons under the details so nothing gets squeezed.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          details,
          const SizedBox(height: 14),
          if (busy)
            const Center(child: spinner)
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _act(req, 'rejected'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _act(req, 'approved'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: const Color(0x26999999)),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            action,
          ],
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
        final double end =
            (distance + dashLength).clamp(0, pathMetric.length).toDouble();

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
