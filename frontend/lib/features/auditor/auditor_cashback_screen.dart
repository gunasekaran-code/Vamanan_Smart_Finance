import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

// --- Dummy Data Model ---
class CashbackTransaction {
  final String date;
  final String type;
  final String description;
  final double amount;
  final String status;

  CashbackTransaction({
    required this.date,
    required this.type,
    required this.description,
    required this.amount,
    required this.status,
  });
}

class AuditorCashbackScreen extends StatefulWidget {
  const AuditorCashbackScreen({super.key});

  @override
  State<AuditorCashbackScreen> createState() => _AuditorCashbackScreenState();
}

class _AuditorCashbackScreenState extends State<AuditorCashbackScreen> {
  String _selectedFilter = 'ALL';
  
  // Dummy Data (Empty by default to match screenshot)
  final List<CashbackTransaction> _transactions = [];

  // --- ACTIONS ---
  void _handleRefresh() {
    ToastService.show(
      title: 'Refreshing',
      message: 'Syncing latest cashback data from the server...',
      type: ToastType.info,
    );
  }

  void _setFilter(String filter) {
    setState(() => _selectedFilter = filter);
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // Using custom header
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800), // Desktop/Tablet constraint
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. CUSTOM HEADER
                _buildHeader(),
                const SizedBox(height: 32),

                // 2. 2x2 STAT CARDS GRID (Using your requested layout structure)
                const _StatCards2x2Grid(),
                const SizedBox(height: 24),

                // 3. CYCLE PROGRESS CARD
                _buildCycleProgressCard(),
                const SizedBox(height: 24),

                // 4. NEXT PAYOUT COUNTDOWN CARD
                _buildNextPayoutCard(),
                const SizedBox(height: 24),

                // 5. CASHBACK HISTORY TABLE
                _buildCashbackHistoryTable(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // 1. HEADER WIDGET
  // ==========================================================================
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.star, color: AppColors.goldColor, size: 10),
            SizedBox(width: 6),
            Text(
              'CASHBACK PLAN',
              style: TextStyle(color: AppColors.goldColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2.0),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'MY CASHBACK',
          style: TextStyle(color: AppColors.kPrimaryDark, fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0),
        ),
        const SizedBox(height: 4),
        const Text(
          '10% MONTHLY PAYOUT • 10 MONTHS = 100% — TRACKED LIVE',
          style: TextStyle(color: AppColors.kTextMuted, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _handleRefresh,
          icon: const Icon(Icons.sync, size: 16),
          label: const Text('REFRESH', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1.0)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.kTextDark,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.kBorder, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // 3. CYCLE PROGRESS CARD
  // ==========================================================================
  Widget _buildCycleProgressCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CYCLE PROGRESS', style: TextStyle(color: AppColors.kPrimaryDark, fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.kBorder)),
                child: const Text('NO PLAN', style: TextStyle(color: AppColors.kTextMuted, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
              )
            ],
          ),
          const SizedBox(height: 32),
          
          // Progress Bar Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('MONTHS COMPLETED', style: TextStyle(color: AppColors.kTextMuted, fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
              Text('0 / 10', style: TextStyle(color: AppColors.goldColor, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.0, // 0 progress
              backgroundColor: const Color(0xFFF1F5F9),
              color: AppColors.goldColor,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          
          // Progress Bar Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('MONTH 0', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
              Text('MONTH 10', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: AppColors.kBorder, thickness: 1.5),
          const SizedBox(height: 24),
          
          // Bottom Stats Row
          Row(
            children: [
              Expanded(child: _buildProgressStat('REMAINING', '₹0', const Color(0xFF3B82F6))),
              Expanded(child: _buildProgressStat('MONTHS LEFT', '10', AppColors.kPrimaryDark)),
              Expanded(child: _buildProgressStat('REFERRAL INCOME', '₹0', AppColors.goldColor)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.kTextMuted, fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        Text(value, textAlign: TextAlign.center, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
      ],
    );
  }

  // ==========================================================================
  // 4. NEXT PAYOUT COUNTDOWN CARD
  // ==========================================================================
  Widget _buildNextPayoutCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.kPrimaryDark,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppColors.kPrimaryDark.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Stack(
        children: [
          // Background Watermark
          Positioned(
            right: -20, bottom: -20,
            child: Icon(Icons.schedule, size: 180, color: Colors.white.withOpacity(0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.access_time, color: AppColors.goldColor, size: 16),
              ),
              const SizedBox(height: 24),
              const Text('NEXT PAYOUT IN', style: TextStyle(color: AppColors.kTextMuted, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              
              // Timer Text (Static for UI)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: const Text('29d 23h 59m 57s', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0)),
              ),
              const SizedBox(height: 8),
              const Text('WEEKDAYS ONLY • 09:00 AM', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
              const SizedBox(height: 32),

              // Info Rows
              _buildPayoutInfoRow(Icons.star_border, '1% OF INVESTED AMOUNT CREDITED DAILY', AppColors.goldColor),
              const SizedBox(height: 12),
              _buildPayoutInfoRow(Icons.event_busy_outlined, 'NO PAYOUTS ON WEEKENDS & HOLIDAYS', Colors.white70),
              const SizedBox(height: 12),
              _buildPayoutInfoRow(Icons.trending_flat, 'CYCLE CLOSES WHEN 100% IS EARNED', Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutInfoRow(IconData icon, String text, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 5. CASHBACK HISTORY TABLE
  // ==========================================================================
  Widget _buildCashbackHistoryTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Filters
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.kPrimaryDark, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.show_chart, color: AppColors.goldColor, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('CASHBACK HISTORY', style: TextStyle(color: AppColors.kPrimaryDark, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
                        SizedBox(height: 4),
                        Text('0 ENTRIES FOUND', style: TextStyle(color: AppColors.kTextMuted, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterPill('ALL'),
                      _buildFilterPill('CASHBACK'),
                      _buildFilterPill('REFERRAL'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 2, color: Color(0xFFF1F5F9)),
          
          // Scrollable Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width > 800 ? 800 : MediaQuery.of(context).size.width - 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                    child: Row(
                      children: [
                        _buildHeaderCell('DATE', width: 100),
                        _buildHeaderCell('TYPE', width: 120),
                        _buildHeaderCell('DESCRIPTION', width: 200),
                        _buildHeaderCell('AMOUNT', width: 100),
                        _buildHeaderCell('STATUS', width: 100),
                      ],
                    ),
                  ),
                  
                  // Body (Empty State exactly as shown in screenshot)
                  if (_transactions.isEmpty)
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 800 ? 800 : MediaQuery.of(context).size.width - 64,
                      height: 250,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.show_chart_rounded, size: 64, color: Color(0xFFE2E8F0)),
                          SizedBox(height: 16),
                          Text('NO TRANSACTIONS YET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String title) {
    final isActive = _selectedFilter == title;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => _setFilter(title),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.kPrimaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? AppColors.kPrimaryDark : AppColors.kBorder),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.kTextMuted,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, {required double width}) {
    return SizedBox(
      width: width,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
    );
  }
}

// ============================================================================
// REQUESTED 2x2 GRID STRUCTURE (Adapted for Cashback Stats)
// ============================================================================
class _StatCards2x2Grid extends StatelessWidget {
  const _StatCards2x2Grid({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 380;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: isSmallMobile ? 8.0 : 16.0,
      crossAxisSpacing: isSmallMobile ? 8.0 : 16.0,
      childAspectRatio: isSmallMobile ? 0.75 : 1.05,
      children: [
        _CashbackStatCard(
          label: 'TOTAL PAID (INCL. GST)',
          value: '₹0',
          icon: Icons.trending_up,
          subText: 'CASHBACK BASIS: ₹0 - EXCL. GST: ₹0',
          color: Colors.white,
          backgroundColor: AppColors.kPrimaryDark,
          borderColor: AppColors.kPrimaryDark,
          iconBg: Colors.white.withOpacity(0.1),
          subTextColor: Colors.white70,
        ),
        _CashbackStatCard(
          label: 'MONTHLY PAYOUT',
          value: '₹0',
          icon: Icons.bolt,
          subText: 'PER MONTH (1ST DAY - 100TH)',
          color: AppColors.goldColor,
          backgroundColor: Colors.white,
          borderColor: AppColors.kBorder,
          iconBg: AppColors.goldBadgeBg,
          subTextColor: const Color(0xFFCBD5E1),
        ),
        _CashbackStatCard(
          label: 'TOTAL EARNED',
          value: '₹0',
          icon: Icons.card_giftcard,
          subText: 'SUM OF PROGRESS YIELDS (EXCL. GST)',
          color: AppColors.kPrimaryDark,
          backgroundColor: Colors.white,
          borderColor: AppColors.kBorder,
          iconBg: AppColors.goldBadgeBg,
          subTextColor: const Color(0xFFCBD5E1),
          iconColor: AppColors.goldColor,
        ),
        _CashbackStatCard(
          label: 'TODAY\'S EARNING',
          value: '₹0',
          icon: Icons.payments_outlined,
          subText: 'CREDITED TODAY',
          color: AppColors.kPrimaryDark,
          backgroundColor: Colors.white,
          borderColor: AppColors.kBorder,
          iconBg: const Color(0xFFEFF6FF),
          subTextColor: const Color(0xFFCBD5E1),
          iconColor: const Color(0xFF3B82F6),
        ),
      ],
    );
  }
}

// Customized Card mimicking the provided `StatCard` structure to match the design's bottom sub-text precisely.
class _CashbackStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String subText;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBg;
  final Color subTextColor;
  final Color? iconColor;

  const _CashbackStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.subText,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBg,
    required this.subTextColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [if (backgroundColor == Colors.white) BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor ?? color, size: 16),
          ),
          const Spacer(),
          Text(label, style: TextStyle(color: backgroundColor == Colors.white ? AppColors.kTextMuted : Colors.white70, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 8),
          Text(subText, style: TextStyle(color: subTextColor, fontSize: 7, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}