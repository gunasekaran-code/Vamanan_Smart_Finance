import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class WalletPayoutReportsScreen extends StatefulWidget {
  const WalletPayoutReportsScreen({super.key});

  @override
  State<WalletPayoutReportsScreen> createState() => _PayoutReportsScreenState();
}

class _PayoutReportsScreenState extends State<WalletPayoutReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Global Search Bar ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users, orders, assets...',
                    hintStyle: TextStyle(
                      color: AppColors.kTextMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 2. Yield Volume Node (Hero Section) ---
              Container(
                decoration: BoxDecoration(
                  color: AppColors.kPrimary,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.kPrimary.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'YIELD VOLUME NODE',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LAST 15 DAY PERFORMANCE LEDGER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withOpacity(0.7),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => ToastService.show(
                                title: 'Protocol Initiated',
                                message: 'Daily protocol is running.',
                                type: ToastType.success,
                              ),
                              icon: const Icon(Icons.play_arrow, size: 16),
                              label: const Text(
                                'RUN DAILY PROTOCOL',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 11,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.goldColor,
                                foregroundColor: AppColors.kPrimary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.circle,
                                  size: 10, color: AppColors.goldColor),
                              label: const Text(
                                'LIVE PULSE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 11,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                    color: Colors.white.withOpacity(0.2)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 48, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.show_chart,
                              color: AppColors.goldColor, size: 32),
                          const SizedBox(height: 16),
                          const Text(
                            'LIVE DATABASE LINK ESTABLISHED',
                            style: TextStyle(
                              color: AppColors.goldColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'AWAITING TRANSMISSION NODES...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(child: _buildHeroStat('PEAK YIELD', '₹0')),
                        Expanded(child: _buildHeroStat('TOTAL PERIOD', '₹0')),
                        Expanded(child: _buildHeroStat('ACTIVE CYCLES', '0')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. Summary Cards ---
              _buildSummaryCard(
                title: 'TOTAL CAPITAL DISBURSED',
                value: '₹0',
                subtext: '0 SUCCESSFUL TRANSMISSIONS',
                icon: Icons.attach_money,
                iconColor: AppColors.goldColor,
                backgroundColor: AppColors.goldBg,
                borderColor: AppColors.goldBorder,
                badgeBgColor: AppColors.goldBadgeBg,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                title: 'PENDING AUTHORIZATIONS',
                value: '₹0',
                subtext: '0 AWAITING PROTOCOL',
                icon: Icons.schedule,
                iconColor: const Color(0xFF3B82F6),
                backgroundColor: const Color(0xFFF0F7FF),
                borderColor: const Color(0xFFBFDBFE),
                badgeBgColor: const Color(0xFFDBEAFE),
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                title: 'SYSTEM INTERCEPTS',
                value: '₹0',
                subtext: '0 FAILED NODE MATCHES',
                icon: Icons.error_outline,
                iconColor: const Color(0xFF3B82F6),
                backgroundColor: const Color(0xFFF0F7FF),
                borderColor: const Color(0xFFBFDBFE),
                badgeBgColor: const Color(0xFFDBEAFE),
              ),
              const SizedBox(height: 24),

              // --- 4. Global Payout Registry (Data Table) ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: LayoutBuilder(builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 500;

                        Widget titles = Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: AppColors.kPrimary,
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.show_chart,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'GLOBAL PAYOUT REGISTRY',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.kPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'LIVE MULTI-NODE TRANSACTION HISTORY',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      color: const Color(0xFF94A3B8)
                                          .withOpacity(0.8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );

                        Widget actions = Column(
                          crossAxisAlignment: isMobile
                              ? CrossAxisAlignment.stretch
                              : CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.kBorder),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.filter_alt_outlined,
                                      size: 14, color: AppColors.kTextMuted),
                                  SizedBox(width: 8),
                                  Text(
                                    'ALL PROTOCOL STATUS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.download, size: 14),
                              label: const Text(
                                'EXPORT LEDGER',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 10,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.kPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        );

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              titles,
                              const SizedBox(height: 20),
                              actions
                            ],
                          );
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Expanded(child: titles), actions],
                        );
                      }),
                    ),
                    const Divider(height: 1, color: AppColors.kBorder),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width - 48,
                        ),
                        child: DataTable(
                          columnSpacing: 48,
                          headingRowHeight: 56,
                          headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFF8FAFC)),
                          dividerThickness: 0,
                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                          columns: const [
                            DataColumn(label: Text('INVESTOR\nENTITY')),
                            DataColumn(label: Text('BANKING\nNODE')),
                            DataColumn(label: Text('TRANSMISSION\nVALUE')),
                            DataColumn(label: Text('PROTOCOL\nSTATUS')),
                            DataColumn(label: Text('TIMESTAMP')),
                          ],
                          rows: const [],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 80),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 40,
                            color: const Color(0xFFCBD5E1).withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'ZERO ANOMALIES DETECTED IN CURRENT PROTOCOL MATRIX',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStat(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 8,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required Color badgeBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: iconColor),
                    const SizedBox(width: 6),
                    Text(
                      subtext,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: iconColor,
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