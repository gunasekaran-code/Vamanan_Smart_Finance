import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/stat_card.dart';

class ReferralReportsScreen extends StatefulWidget {
  const ReferralReportsScreen({super.key});

  @override
  State<ReferralReportsScreen> createState() => _ReferralReportsScreenState();
}

class _ReferralReportsScreenState extends State<ReferralReportsScreen> {
  // Search Controller for the Registry
  final TextEditingController _registrySearchController =
      TextEditingController();

  @override
  void dispose() {
    _registrySearchController.dispose();
    super.dispose();
  }

  // --- Handlers ---
  void _handleRefreshProtocol() {
    ToastService.show(
      title: 'Protocol Refreshed',
      message: 'Referral intelligence data synced with the global node.',
      type: ToastType.success,
    );
  }

  Future<void> _handleExportLedger() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'EXPORT LEDGER',
      message: 'Generate a full data dump of the referral network registry?',
      confirmLabel: 'EXPORT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );

    if (confirmed == true) {
      ToastService.show(
        title: 'Export Initiated',
        message: 'The referral ledger is being prepared for download.',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light crisp background
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
                    hintStyle:
                        TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- 2. Header Section ---
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;

                  Widget titleContent = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                              width: 32,
                              height: 2,
                              color: const Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          const Text(
                            'ANALYTICAL COMMAND NODE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFFD97706), // Gold
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                              width: 32,
                              height: 2,
                              color: const Color(0xFFD97706)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'REFERRAL',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E3A8A), // Navy
                          height: 0.9,
                          letterSpacing: -1,
                        ),
                      ),
                      const Text(
                        'REPORTS',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFD97706), // Gold
                          height: 0.9,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'HIGH-FIDELITY FISCAL INTELLIGENCE & ASSET OVERSIGHT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF94A3B8).withOpacity(0.8),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  );

                  Widget actionContent = Column(
                    crossAxisAlignment: isMobile
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _handleRefreshProtocol,
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text(
                          'REFRESH PROTOCOL',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              fontSize: 11,
                              letterSpacing: 1),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFD97706), // Gold text
                          side: const BorderSide(
                              color: Color(0xFFFDE68A)), // Light gold border
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32)),
                          elevation: 2,
                          shadowColor: const Color(0xFFD97706).withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'LAST UPDATED: JUST NOW',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF94A3B8).withOpacity(0.7),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleContent,
                        const SizedBox(height: 24),
                        actionContent,
                      ],
                    );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: titleContent),
                      actionContent,
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // --- 3. Financial Inflection Chart Card ---
              _buildFinancialInflectionCard(),
              const SizedBox(height: 24),

              // --- 4. Node Yield & Transmissions Row ---
              LayoutBuilder(builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 800;

                Widget netNodeCard = _buildNetNodeYieldCard();
                Widget transmissionsCard = _buildTransmissionsCard();

                if (isMobile) {
                  return Column(
                    children: [
                      netNodeCard,
                      const SizedBox(height: 24),
                      transmissionsCard,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: netNodeCard),
                    const SizedBox(width: 24),
                    Expanded(child: transmissionsCard),
                  ],
                );
              }),
              const SizedBox(height: 24),

              // --- 5. Deduction Breakdown ---
              _buildDeductionBreakdownCard(),
              const SizedBox(height: 24),

              // --- 6. Elite Referrers ---
              _buildEliteReferrersCard(),
              const SizedBox(height: 24),

              // --- 7. Network Growth Velocity ---
              _buildNetworkGrowthVelocityCard(),
              const SizedBox(height: 24),

              // --- 8. Protocol History Table ---
              _buildProtocolHistoryCard(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Sub-Components ---

  Widget _buildFinancialInflectionCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FINANCIAL INFLECTION',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 4),
                  Text('MULTIVARIATE YIELD METRICS (30 CYCLES)',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF94A3B8).withOpacity(0.8),
                          letterSpacing: 1)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A))),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Color(0xFFD97706)),
                    SizedBox(width: 6),
                    Text('LIVE SYNC ACTIVE',
                        style: TextStyle(
                            color: Color(0xFFD97706),
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),

          // Chart Placeholder
          Container(
            height: 200,
            alignment: Alignment.center,
            child: Icon(Icons.insights_outlined,
                size: 48, color: const Color(0xFFE2E8F0).withOpacity(0.5)),
          ),

          const Divider(height: 1, color: AppColors.kBorder),
          const SizedBox(height: 24),

          // Footer Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVelocityStat(
                  'AGGREGATE YIELD (₹)', '₹0', const Color(0xFF1E3A8A)),
              _buildVelocityStat('ACTIVE NODES', '0', const Color(0xFF1E3A8A)),
              _buildVelocityStat(
                  'PROTOCOL STATUS', 'OPTIMAL', const Color(0xFFD97706)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFF94A3B8),
                letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: valueColor)),
      ],
    );
  }

  Widget _buildNetNodeYieldCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFC29B38), // Mustard Gold
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFD97706).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.account_tree_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(height: 24),
          const Text('NET NODE YIELD',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('0 Nodes',
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  height: 1)),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.arrow_right, color: Colors.white, size: 14),
              Text('INSTITUTIONAL GRADE',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransmissionsCard() {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB), shape: BoxShape.circle),
            child: const Icon(Icons.hub_outlined,
                color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(height: 24),
          const Text('FINANCIAL VELOCITY',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('0 TRANSMISSIONS',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF1E3A8A))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleExportLedger,
              icon: const Icon(Icons.download, size: 14),
              label: const Text('EXPORT LEDGER',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                      letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionBreakdownCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DEDUCTION BREAKDOWN',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 4),
                    Text('AUTO-COMPUTED TDS + SERVICE CHARGES + NET YIELD LENGTH',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF94A3B8).withOpacity(0.8),
                            letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.trending_down,
                    color: Color(0xFFEF4444), size: 16),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isSmallMobile = screenWidth < 400;
            int crossAxisCount = screenWidth < 600 ? (isSmallMobile ? 1 : 2) : 3;
            
            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: screenWidth < 600 ? (isSmallMobile ? 2.4 : 1.3) : 1.6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                StatCard(
                  label: 'GROSS PAYOUT',
                  value: '₹0',
                  badgeText: 'TOTAL',
                  icon: Icons.account_balance_wallet,
                  color: Color(0xFF1E3A8A),
                  backgroundColor: Color(0xFFF0F7FF),
                  borderColor: Color(0xFFBFDBFE),
                  badgeBackgroundColor: Color(0xFFDBEAFE),
                  badgeTextColor: Color(0xFF1D4ED8),
                ),
                StatCard(
                  label: 'TDS DEDUCTED',
                  value: '₹0',
                  badgeText: 'TAX',
                  icon: Icons.money_off,
                  color: Color(0xFFEF4444),
                  backgroundColor: Color(0xFFFEF2F2),
                  borderColor: Color(0xFFFECACA),
                  badgeBackgroundColor: Color(0xFFFEE2E2),
                  badgeTextColor: Color(0xFFDC2626),
                ),
                StatCard(
                  label: 'SERVICE CHARGE',
                  value: '₹0',
                  badgeText: 'CHARGE',
                  icon: Icons.receipt_long,
                  color: Color(0xFFEF4444),
                  backgroundColor: Color(0xFFFEF2F2),
                  borderColor: Color(0xFFFECACA),
                  badgeBackgroundColor: Color(0xFFFEE2E2),
                  badgeTextColor: Color(0xFFDC2626),
                ),
                StatCard(
                  label: 'NET PAYOUT',
                  value: '₹0',
                  badgeText: 'CREDITED',
                  icon: Icons.check_circle_outline,
                  color: Color(0xFF10B981),
                  backgroundColor: Color(0xFFECFDF5),
                  borderColor: Color(0xFFA7F3D0),
                  badgeBackgroundColor: Color(0xFFD1FAE5),
                  badgeTextColor: Color(0xFF047857),
                ),
                StatCard(
                  label: 'TOTAL DEDUCTIONS',
                  value: '₹0',
                  badgeText: 'DEDUCTIONS',
                  icon: Icons.trending_down,
                  color: Color(0xFFD97706),
                  backgroundColor: AppColors.goldBg,
                  borderColor: AppColors.goldBorder,
                  badgeBackgroundColor: AppColors.goldBadgeBg,
                  badgeTextColor: AppColors.goldColor,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDeductionStat(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildEliteReferrersCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ELITE REFERRERS',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF1E3A8A))),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.workspace_premium_outlined,
                    color: Color(0xFF3B82F6), size: 16),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: const Text(
              'NO ELITE REFERRERS DETECTED IN THIS CYCLE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFFCBD5E1),
                  letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkGrowthVelocityCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A), // Deep Navy
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('NETWORK GROWTH VELOCITY',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.white)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child:
                    const Icon(Icons.bar_chart, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Chart Placeholder
          Container(
            height: 200,
            alignment: Alignment.center,
            // Empty placeholder area
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Metrics rely on real-time node activation rates. An extended flatline indicates low referential vitality. Maintain promotional pressure to keep velocity stable.',
                    style: TextStyle(
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.5),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'VIEW EXTENDED FORECAST',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFFBBF24),
                      decoration: TextDecoration.underline), // Gold text
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProtocolHistoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: LayoutBuilder(builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;

              Widget titleArea = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.history_edu,
                        color: Color(0xFF3B82F6), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PROTOCOL\nHISTORY',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF1E3A8A),
                                height: 1.1)),
                        const SizedBox(height: 4),
                        Text('IMMUTABLE TRANSACTION REGISTRY',
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFF94A3B8).withOpacity(0.8),
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              );

              Widget searchArea = Column(
                children: [
                  SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _registrySearchController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'SEARCH REGISTRY...',
                        hintStyle: const TextStyle(
                            color: AppColors.kTextMuted,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w900),
                        prefixIcon: const Icon(Icons.search,
                            size: 16, color: AppColors.kTextMuted),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.kBorder)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        border: Border.all(color: AppColors.kBorder),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.filter_list,
                            size: 16, color: AppColors.kTextMuted),
                        Text('ALL NODES',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF1E3A8A))),
                        Icon(Icons.arrow_drop_down,
                            size: 16, color: AppColors.kTextMuted),
                      ],
                    ),
                  )
                ],
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleArea,
                    const SizedBox(height: 24),
                    searchArea,
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(flex: 3, child: titleArea),
                  const SizedBox(width: 32),
                  Expanded(flex: 2, child: searchArea),
                ],
              );
            }),
          ),

          const Divider(height: 1, color: AppColors.kBorder),

          // Scrollable Table Header
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 48),
              child: DataTable(
                columnSpacing: 48,
                headingRowHeight: 56,
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                dividerThickness: 0,
                headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF94A3B8),
                    fontSize: 9,
                    letterSpacing: 1.5),
                columns: const [
                  DataColumn(label: Text('ENTITY NODE')),
                  DataColumn(label: Text('PROTOCOL REF')),
                  DataColumn(label: Text('VALIDATE')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('QUANTUM (₹)')),
                ],
                rows: const [], // Empty rows
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.kBorder),

          // Empty State Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
            alignment: Alignment.center,
            child: const Text(
              'NO REGISTRY ENTRIES FOUND',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFFCBD5E1),
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
