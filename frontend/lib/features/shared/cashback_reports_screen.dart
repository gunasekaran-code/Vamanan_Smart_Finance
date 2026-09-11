import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/stat_card.dart'; // Make sure this path points to your provided StatCard widget

class CashbackReportsScreen extends StatefulWidget {
  const CashbackReportsScreen({super.key});

  @override
  State<CashbackReportsScreen> createState() => _CashbackReportsScreenState();
}

class _CashbackReportsScreenState extends State<CashbackReportsScreen> {
  // Search Controller for the Registry
  final TextEditingController _registrySearchController = TextEditingController();
  
  // History Tab State
  String _activeHistoryTab = 'TRANSACTIONS';

  @override
  void dispose() {
    _registrySearchController.dispose();
    super.dispose();
  }

  // --- Handlers ---
  void _handleRefreshProtocol() {
    ToastService.show(
      title: 'Protocol Refreshed',
      message: 'Cashback intelligence data synced with the global node.',
      type: ToastType.success,
    );
  }

  Future<void> _handleExportLedger() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'EXPORT LEDGER',
      message: 'Generate a full data dump of the cashback node registry?',
      confirmLabel: 'EXPORT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );

    if (confirmed == true) {
      ToastService.show(
        title: 'Export Initiated',
        message: 'The cashback ledger is being prepared for download.',
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
                    hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
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
                          Container(width: 32, height: 2, color: const Color(0xFFD97706)),
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
                          Container(width: 32, height: 2, color: const Color(0xFFD97706)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'CASHBACK',
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
                    crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _handleRefreshProtocol,
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text(
                          'REFRESH PROTOCOL',
                          style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFD97706), // Gold text
                          side: const BorderSide(color: Color(0xFFFDE68A)), // Light gold border
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
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

              // --- 3. Transmission Velocity Chart Card ---
              _buildTransmissionVelocityCard(),
              const SizedBox(height: 24),

              // --- 4. Market Trajectory & Data Dump Row ---
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 800;

                  Widget marketCard = _buildMarketTrajectoryCard();
                  Widget dataDumpCard = _buildGlobalDataDumpCard();

                  if (isMobile) {
                    return Column(
                      children: [
                        marketCard,
                        const SizedBox(height: 24),
                        dataDumpCard,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: marketCard),
                      const SizedBox(width: 24),
                      Expanded(child: dataDumpCard),
                    ],
                  );
                }
              ),
              const SizedBox(height: 24),

              // --- 5. 4-Grid Navy Stats Cards ---
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth < 600 ? 1 : (constraints.maxWidth < 1000 ? 2 : 4);
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: constraints.maxWidth < 600 ? 2.5 : 1.8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildNavyStatCard('TOTAL WITHDRAWALS', '₹ 0', Icons.account_balance_wallet_outlined),
                      _buildNavyStatCard('SUCCESSFUL TRANSFERS', '₹ 0', Icons.verified_outlined),
                      _buildNavyStatCard('FAILED PROCESSING', '₹ 0', Icons.cancel_outlined),
                      _buildNavyStatCard('PENDING REQUESTS', '₹ 0', Icons.hourglass_empty),
                    ],
                  );
                }
              ),
              const SizedBox(height: 24),

              // --- 6. Deduction Breakdown (Using StatCard) ---
              _buildDeductionBreakdown(),
              const SizedBox(height: 24),

              // --- 7. Active Yield & Protocol Completion ---
              _buildActiveYieldProtocol(),
              const SizedBox(height: 24),
              _buildProtocolCompletion(),
              const SizedBox(height: 24),

              // --- 8. Protocol History Table (with toggles) ---
              _buildProtocolHistoryCard(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Sub-Components ---

  Widget _buildTransmissionVelocityCard() {
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
                  const Text('TRANSMISSION\nVELOCITY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), height: 1.1)),
                  const SizedBox(height: 4),
                  Text('TEMPORAL YIELD ANALYSIS\n(30 CYCLES)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1, height: 1.3)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
                child: const Text('LIVE NODE\nACTIVE', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFD97706), fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
              ),
            ],
          ),
          // Chart Placeholder
          Container(
            height: 200,
            alignment: Alignment.center,
            child: Icon(Icons.show_chart, size: 48, color: const Color(0xFFE2E8F0).withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          // Footer Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVelocityStat('AGGREGATE\nVALUE', '₹0', const Color(0xFF1E3A8A)),
              _buildVelocityStat('NODE COUNT', '0', const Color(0xFF1E3A8A)),
              _buildVelocityStat('PROTOCOL\nSTATUS', 'OPTIMAL', const Color(0xFFD97706)),
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
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1, height: 1.4)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: valueColor)),
      ],
    );
  }

  Widget _buildMarketTrajectoryCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFC29B38), // Mustard Gold
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFFD97706).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.show_chart, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 24),
          const Text('MARKET TRAJECTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('43.3%', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white, height: 1)),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.arrow_right, color: Colors.white, size: 14),
              Text('INSTITUTIONAL GRADE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.8), letterSpacing: 1.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalDataDumpCard() {
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
            decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
            child: const Icon(Icons.language, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(height: 24),
          const Text('GLOBAL OPERATIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('0 NODE REGISTRY', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleExportLedger,
              icon: const Icon(Icons.download, size: 14),
              label: const Text('EXPORT LEDGER', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavyStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A), // Navy Blue
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF112255), borderRadius: BorderRadius.circular(6)),
              child: const Text('SYSTEM READY', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 7, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.7), letterSpacing: 0.5))),
                ],
              ),
              const SizedBox(height: 16),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionBreakdown() {
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
                  const Text('DEDUCTION BREAKDOWN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 4),
                  Text('AUTO-COMPUTED TDS + SERVICE CHARGES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.trending_down, color: Color(0xFFEF4444), size: 16),
              ),
            ],
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
  builder: (context, constraints) {
    final screenWidth = constraints.maxWidth;
    final isSmallMobile = screenWidth < 380;
    int crossAxisCount = screenWidth < 600 ? 1 : (screenWidth < 900 ? 2 : 3);
    
    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: isSmallMobile ? 8.0 : 16.0,
      mainAxisSpacing: isSmallMobile ? 8.0 : 16.0,
      childAspectRatio: screenWidth < 600 ? (isSmallMobile ? 2.2 : 2.5) : 2.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        StatCard(
          label: 'GROSS INCENTIVE',
          value: '₹0',
          badgeText: 'BEFORE DEDUCTIONS',
          icon: Icons.account_balance_wallet,
          color: Color(0xFF1E3A8A),
          backgroundColor: Color(0xFFF0F7FF),
          borderColor: Color(0xFFBFDBFE),
          badgeBackgroundColor: Color(0xFFDBEAFE),
          badgeTextColor: Color(0xFF1D4ED8),
        ),
        StatCard(
          label: 'TDS WITHHELD',
          value: '₹0',
          badgeText: '0.0% OF GROSS',
          icon: Icons.money_off,
          color: Color(0xFFEF4444),
          backgroundColor: Color(0xFFFEF2F2),
          borderColor: Color(0xFFFECACA),
          badgeBackgroundColor: Color(0xFFFEE2E2),
          badgeTextColor: Color(0xFFDC2626),
        ),
        StatCard(
          label: 'SERVICE CHARGES',
          value: '₹0',
          badgeText: '0.0% OF GROSS',
          icon: Icons.receipt_long,
          color: Color(0xFFEF4444),
          backgroundColor: Color(0xFFFEF2F2),
          borderColor: Color(0xFFFECACA),
          badgeBackgroundColor: Color(0xFFFEE2E2),
          badgeTextColor: Color(0xFFDC2626),
        ),
        StatCard(
          label: 'TOTAL DEDUCTION',
          value: '₹0',
          badgeText: '0.0% WITHHELD',
          icon: Icons.trending_down,
          color: Color(0xFFD97706),
          backgroundColor: AppColors.goldBg,
          borderColor: AppColors.goldBorder,
          badgeBackgroundColor: AppColors.goldBadgeBg,
          badgeTextColor: AppColors.goldColor,
        ),
        StatCard(
          label: 'NET CREDITED',
          value: '₹0',
          badgeText: 'PAID TO WALLETS',
          icon: Icons.check_circle_outline,
          color: Color(0xFF10B981),
          backgroundColor: Color(0xFFECFDF5),
          borderColor: Color(0xFFA7F3D0),
          badgeBackgroundColor: Color(0xFFD1FAE5),
          badgeTextColor: Color(0xFF047857),
        ),
      ],
    );
  },
),

        ],
      ),
    );
  }

  Widget _buildActiveYieldProtocol() {
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
              const Text('ACTIVE YIELD PROTOCOL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.bolt, color: Color(0xFFD97706), size: 16),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('0', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), height: 1)),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('ACTIVE DISBURSING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MONTHLY YIELD / NODE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1)),
                    const SizedBox(height: 8),
                    const Text('₹0', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL DISBURSED (EST.)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1)),
                    const SizedBox(height: 8),
                    const Text('₹ 0 / ₹ 0', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProtocolCompletion() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A), // Navy Blue
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PROTOCOL COMPLETION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('COMPLETED NODES (10/10 CYCLES MET)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('0', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white, height: 1)),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('NODES MATURED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFBBF24), letterSpacing: 1)), // Gold text
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OVERALL COMPLETION RATE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
                      const SizedBox(height: 8),
                      const Text('00.0%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LIFETIME DISBURSED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
                      const SizedBox(height: 8),
                      const Text('₹0', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                    ],
                  ),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 800;
                
                Widget titleArea = Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12)), // Light gold tint
                      child: const Icon(Icons.bolt, color: Color(0xFFD97706), size: 24), // Gold bolt
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PROTOCOL HISTORY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), height: 1.1)),
                          const SizedBox(height: 4),
                          Text('IMMUTABLE TRANSACTION REGISTRY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ],
                );

                Widget toggleArea = Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), // Light gray background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHistoryTab('TRANSACTIONS'),
                      _buildHistoryTab('CYCLES'),
                    ],
                  ),
                );

                Widget searchArea = Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _registrySearchController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'SEARCH IDENTITY...',
                            hintStyle: const TextStyle(color: AppColors.kTextMuted, fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900),
                            prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.kTextMuted),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.kBorder)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.kBorder), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_list, size: 16, color: AppColors.kTextMuted),
                          SizedBox(width: 8),
                          Text('ALL NODES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
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
                      toggleArea,
                      const SizedBox(height: 24),
                      searchArea,
                    ],
                  );
                }
                
                // Desktop row structure mapping to image_e92c81.png
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(flex: 3, child: titleArea),
                    const SizedBox(width: 16),
                    toggleArea,
                    const SizedBox(width: 32),
                    Expanded(flex: 4, child: searchArea),
                  ],
                );
              }
            ),
          ),
          
          const Divider(height: 1, color: AppColors.kBorder),

          // Scrollable Table Header (matches image_e92c81.png)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
              child: DataTable(
                columnSpacing: 48,
                headingRowHeight: 56,
                dataRowMinHeight: 72,
                dataRowMaxHeight: 72,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                dividerThickness: 0,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 9, letterSpacing: 1.5),
                columns: const [
                  DataColumn(label: Text('ENTITY NODE')),
                  DataColumn(label: Text('PROTOCOL REF')),
                  DataColumn(label: Text('VALUE (₹)')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('TIMESTAMP')),
                ],
                rows: const [], // Empty state as per reference image
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

  Widget _buildHistoryTab(String title) {
    bool isActive = _activeHistoryTab == title;
    return InkWell(
      onTap: () => setState(() => _activeHistoryTab = title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD97706) : Colors.transparent, // Gold background if active
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: isActive ? Colors.white : const Color(0xFF64748B),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}