import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/tally_integration_model.dart';
import 'package:frontend/services/tally_integration_service.dart';
import 'package:frontend/shared/widgets/stat_card.dart';
import 'tally_state_views.dart';

/// Headline metrics, the 6-month revenue trend and the integration counters,
/// all from `?resource=dashboard`.
class DashboardViewWidget extends StatefulWidget {
  const DashboardViewWidget({super.key});

  @override
  State<DashboardViewWidget> createState() => _DashboardViewWidgetState();
}

class _DashboardViewWidgetState extends State<DashboardViewWidget> {
  final TallyIntegrationService _service = TallyIntegrationService();

  TallyDashboard? _dashboard;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dashboard = await _service.fetchDashboard();
      if (!mounted) return;
      setState(() => _dashboard = dashboard);
    } on TallyIntegrationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _dashboard == null) {
      return const TallyLoadingCard(label: 'LOADING ACCOUNTING SNAPSHOT');
    }
    if (_error != null && _dashboard == null) {
      return TallyErrorCard(message: _error!, onRetry: _load);
    }

    final dashboard = _dashboard!;
    final metrics = dashboard.metrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- 1. Statistics Grid ---
        LayoutBuilder(
          builder: (context, constraints) {
            return StatCardGrid(
              children: [
                StatCard(
                  label: 'SALES REVENUE',
                  value: formatInr(metrics.salesRevenue),
                  icon: Icons.trending_up,
                  color: kTallyGold,
                  badgeText: 'REVENUE',
                  backgroundColor: AppColors.goldBg,
                  borderColor: AppColors.goldBorder,
                  badgeBackgroundColor: AppColors.goldBadgeBg,
                  badgeTextColor: AppColors.goldColor,
                ),
                StatCard(
                  label: 'CASHBACK PAID',
                  value: formatInr(metrics.cashbackPaid),
                  icon: Icons.monetization_on_outlined,
                  color: kTallyGold,
                  badgeText: 'PAID',
                  backgroundColor: AppColors.goldBg,
                  borderColor: AppColors.goldBorder,
                  badgeBackgroundColor: AppColors.goldBadgeBg,
                  badgeTextColor: AppColors.goldColor,
                ),
                StatCard(
                  label: 'REFERRAL PAID',
                  value: formatInr(metrics.referralPaid),
                  icon: Icons.call_made,
                  color: const Color(0xFF3B82F6),
                  badgeText: 'REFERRAL',
                  backgroundColor: const Color(0xFFF0F7FF),
                  borderColor: const Color(0xFFBFDBFE),
                  badgeBackgroundColor: const Color(0xFFDBEAFE),
                  badgeTextColor: const Color(0xFF1D4ED8),
                ),
                StatCard(
                  label: 'WITHDRAWN',
                  value: formatInr(metrics.withdrawn),
                  icon: Icons.account_balance_outlined,
                  color: const Color(0xFF3B82F6),
                  badgeText: 'WITHDRAWN',
                  backgroundColor: const Color(0xFFF0F7FF),
                  borderColor: const Color(0xFFBFDBFE),
                  badgeBackgroundColor: const Color(0xFFDBEAFE),
                  badgeTextColor: const Color(0xFF1D4ED8),
                ),
                StatCard(
                  label: 'INVENTORY VALUE',
                  value: formatInr(metrics.inventoryValue),
                  icon: Icons.shopping_bag_outlined,
                  color: const Color(0xFF3B82F6),
                  badgeText: 'INVENTORY',
                  backgroundColor: const Color(0xFFF0F7FF),
                  borderColor: const Color(0xFFBFDBFE),
                  badgeBackgroundColor: const Color(0xFFDBEAFE),
                  badgeTextColor: const Color(0xFF1D4ED8),
                ),
                StatCard(
                  label: 'NET POSITION',
                  value: formatInr(metrics.netPosition),
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFF3B82F6),
                  badgeText: 'POSITION',
                  backgroundColor: const Color(0xFFF0F7FF),
                  borderColor: const Color(0xFFBFDBFE),
                  badgeBackgroundColor: const Color(0xFFDBEAFE),
                  badgeTextColor: const Color(0xFF1D4ED8),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // --- 2. Revenue Trend Chart ---
        _buildRevenueTrendChart(dashboard),
        const SizedBox(height: 24),

        // --- 3. Integration Status List ---
        _buildIntegrationStatusList(dashboard.counts),
      ],
    );
  }

  // --- Component Builders ---

  Widget _buildRevenueTrendChart(TallyDashboard dashboard) {
    final peak = dashboard.trendPeak;

    return TallyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'REVENUE TREND · 6 MONTHS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: kTallyNavy,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : _load,
                tooltip: 'Refresh',
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: kTallyGold),
                      )
                    : Icon(Icons.refresh,
                        color: kTallyGold.withOpacity(0.7), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 120,
            child: dashboard.trend.isEmpty
                ? const Center(
                    child: Text(
                      'NO REVENUE IN THIS PERIOD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: kTallyMuted,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: dashboard.trend
                        // Bars are scaled against the tallest month; a flat-zero
                        // period would divide by zero, so it renders as stubs.
                        .map((point) => _buildChartBar(
                              point,
                              peak > 0 ? point.amount / peak : 0,
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(TallyTrendPoint point, double heightPercentage) {
    return Tooltip(
      message: '${point.month} · ${formatInr(point.amount)}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 32,
            // Keep a visible sliver for a zero month rather than nothing at all.
            height: (120 * heightPercentage).clamp(4.0, 120.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE68A), // Light Gold fill
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: kTallyGold.withOpacity(0.5)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            point.month,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: kTallyMuted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationStatusList(TallyCounts counts) {
    return TallyCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INTEGRATION STATUS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: kTallyNavy,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatusRow(
              Icons.receipt_long_outlined, 'MANAGED VOUCHERS', counts.vouchers),
          _buildStatusRow(
              Icons.check_circle_outline, 'SYNCED TO TALLY', counts.synced),
          _buildStatusRow(Icons.bolt, 'PENDING SYNC', counts.pendingSync),
          _buildStatusRow(Icons.sync, 'SYNC RUNS', counts.syncRuns),
          _buildStatusRow(
              Icons.description_outlined, 'AUDIT ENTRIES', counts.auditEntries),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: kTallyMuted),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: kTallyNavy,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: kTallyNavy,
            ),
          ),
        ],
      ),
    );
  }
}
