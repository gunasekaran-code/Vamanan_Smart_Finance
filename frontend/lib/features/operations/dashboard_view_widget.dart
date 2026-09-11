import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/stat_card.dart';

class DashboardViewWidget extends StatelessWidget {
  const DashboardViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- 1. Statistics Grid ---
 LayoutBuilder(
  builder: (context, constraints) {
    final screenWidth = constraints.maxWidth;
    final isSmallMobile = screenWidth < 380;
    // 2 columns for mobile, 3 for tablets, 4 for wide screens
    int crossAxisCount = screenWidth > 800 ? 4 : (screenWidth > 500 ? 3 : 2);
    
    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: isSmallMobile ? 8.0 : 16.0,
      mainAxisSpacing: isSmallMobile ? 8.0 : 16.0,
      childAspectRatio: screenWidth > 500 ? 1.4 : (isSmallMobile ? 0.82 : 1.1),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        StatCard(
          label: 'SALES REVENUE',
          value: '₹1,95,36,477.75',
          icon: Icons.trending_up,
          color: Color(0xFFD97706),
          badgeText: 'REVENUE',
          backgroundColor: AppColors.goldBg,
          borderColor: AppColors.goldBorder,
          badgeBackgroundColor: AppColors.goldBadgeBg,
          badgeTextColor: AppColors.goldColor,
        ),
        StatCard(
          label: 'CASHBACK PAID',
          value: '₹3,09,911.16',
          icon: Icons.monetization_on_outlined,
          color: Color(0xFFD97706),
          badgeText: 'PAID',
          backgroundColor: AppColors.goldBg,
          borderColor: AppColors.goldBorder,
          badgeBackgroundColor: AppColors.goldBadgeBg,
          badgeTextColor: AppColors.goldColor,
        ),
        StatCard(
          label: 'REFERRAL PAID',
          value: '₹55,503.42',
          icon: Icons.call_made,
          color: Color(0xFF3B82F6),
          badgeText: 'REFERRAL',
          backgroundColor: Color(0xFFF0F7FF),
          borderColor: Color(0xFFBFDBFE),
          badgeBackgroundColor: Color(0xFFDBEAFE),
          badgeTextColor: Color(0xFF1D4ED8),
        ),
        StatCard(
          label: 'WITHDRAWN',
          value: '₹0.00',
          icon: Icons.account_balance_outlined,
          color: Color(0xFF3B82F6),
          badgeText: 'WITHDRAWN',
          backgroundColor: Color(0xFFF0F7FF),
          borderColor: Color(0xFFBFDBFE),
          badgeBackgroundColor: Color(0xFFDBEAFE),
          badgeTextColor: Color(0xFF1D4ED8),
        ),
        StatCard(
          label: 'INVENTORY VALUE',
          value: '₹1,29,54,698.00',
          icon: Icons.shopping_bag_outlined,
          color: Color(0xFF3B82F6),
          badgeText: 'INVENTORY',
          backgroundColor: Color(0xFFF0F7FF),
          borderColor: Color(0xFFBFDBFE),
          badgeBackgroundColor: Color(0xFFDBEAFE),
          badgeTextColor: Color(0xFF1D4ED8),
        ),
        StatCard(
          label: 'NET POSITION',
          value: '₹1,91,71,063.17',
          icon: Icons.account_balance_wallet_outlined,
          color: Color(0xFF3B82F6),
          badgeText: 'POSITION',
          backgroundColor: Color(0xFFF0F7FF),
          borderColor: Color(0xFFBFDBFE),
          badgeBackgroundColor: Color(0xFFDBEAFE),
          badgeTextColor: Color(0xFF1D4ED8),
        ),
      ],
    );
  },
),
        const SizedBox(height: 24),

        // --- 2. Revenue Trend Chart Mock ---
        _buildRevenueTrendChart(),
        const SizedBox(height: 24),

        // --- 3. Integration Status List ---
        _buildIntegrationStatusList(),
      ],
    );
  }

  // --- Component Builders ---

  Widget _buildRevenueTrendChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
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
                  color: Color(0xFF1E3A8A),
                  letterSpacing: 1,
                ),
              ),
              Icon(Icons.trending_up, color: const Color(0xFFD97706).withOpacity(0.7), size: 18),
            ],
          ),
          const SizedBox(height: 40),
          
          // Custom Bar Chart Representation
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildChartBar('APR', 0.15),
                _buildChartBar('MAY', 0.20),
                _buildChartBar('JUN', 0.18),
                _buildChartBar('JUL', 0.22),
                _buildChartBar('AUG', 0.15),
                _buildChartBar('SEP', 0.12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, double heightPercentage) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32, // Fixed width for bars
          height: 120 * heightPercentage, // Max height is 120px
          decoration: BoxDecoration(
            color: const Color(0xFFFDE68A), // Light Gold fill
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFD97706).withOpacity(0.5)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Color(0xFF94A3B8),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildIntegrationStatusList() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INTEGRATION STATUS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF1E3A8A),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatusRow(Icons.receipt_long_outlined, 'MANAGED VOUCHERS', '0'),
          _buildStatusRow(Icons.check_circle_outline, 'SYNCED TO TALLY', '0'),
          _buildStatusRow(Icons.bolt, 'PENDING SYNC', '0'),
          _buildStatusRow(Icons.sync, 'SYNC RUNS', '0'),
          _buildStatusRow(Icons.description_outlined, 'AUDIT ENTRIES', '2'), // Showing 2 based on the design
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }
}