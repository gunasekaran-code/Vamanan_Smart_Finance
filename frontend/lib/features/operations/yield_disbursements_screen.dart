import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/stat_card.dart'; // Ensure this points to your StatCard file

class YieldDisbursementsScreen extends StatefulWidget {
  const YieldDisbursementsScreen({super.key});

  @override
  State<YieldDisbursementsScreen> createState() => _YieldDisbursementsScreenState();
}

class _YieldDisbursementsScreenState extends State<YieldDisbursementsScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 380;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light crisp background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header Section ---
              const Text(
                'YIELD DISBURSEMENTS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF1E3A8A), // Dark Navy Blue
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TRACK AND PROCESS THE DAILY 2% CASHBACK PLAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF94A3B8).withOpacity(0.9),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // --- Search and Export Action Row ---
              LayoutBuilder(
                builder: (context, constraints) {
                  // Stack on narrow mobile screens, row on wider screens
                  if (constraints.maxWidth < 450) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                        _buildExportButton(),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: _buildSearchBar()),
                      const SizedBox(width: 16),
                      _buildExportButton(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: isSmallMobile ? 8.0 : 16.0,
                crossAxisSpacing: isSmallMobile ? 8.0 : 16.0,
                childAspectRatio: isSmallMobile ? 0.82 : 0.9,
                children: const [
                  StatCard(
                    label: 'YIELD DISPATCHED TODAY',
                    value: '₹0',
                    icon: Icons.bolt,
                    color: Color(0xFFD97706),
                    badgeText: 'TODAY',
                    backgroundColor: AppColors.goldBg,
                    borderColor: AppColors.goldBorder,
                    badgeBackgroundColor: AppColors.goldBadgeBg,
                    badgeTextColor: AppColors.goldColor,
                  ),
                  StatCard(
                    label: 'CURRENT MONTH TOTAL',
                    value: '₹0',
                    icon: Icons.attach_money,
                    color: Color(0xFFD97706),
                    badgeText: 'MONTHLY',
                    backgroundColor: AppColors.goldBg,
                    borderColor: AppColors.goldBorder,
                    badgeBackgroundColor: AppColors.goldBadgeBg,
                    badgeTextColor: AppColors.goldColor,
                  ),
                  StatCard(
                    label: 'ACTIVE YIELD CYCLES',
                    value: '0',
                    icon: Icons.sync,
                    color: Color(0xFF3B82F6),
                    badgeText: 'ACTIVE',
                    backgroundColor: Color(0xFFF0F7FF),
                    borderColor: Color(0xFFBFDBFE),
                    badgeBackgroundColor: Color(0xFFDBEAFE),
                    badgeTextColor: Color(0xFF1D4ED8),
                  ),
                  StatCard(
                    label: 'TOTAL CUMULATIVE YIELD',
                    value: '₹0',
                    icon: Icons.call_made,
                    color: Color(0xFF3B82F6),
                    badgeText: 'TOTAL',
                    backgroundColor: Color(0xFFF0F7FF),
                    borderColor: Color(0xFFBFDBFE),
                    badgeBackgroundColor: Color(0xFFDBEAFE),
                    badgeTextColor: Color(0xFF1D4ED8),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- Data Table with Empty State ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Horizontal Scroll for Table Headers to prevent pixel overflow
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width - 48, // Matches padding
                        ),
                        child: DataTable(
                          columnSpacing: 48,
                          headingRowHeight: 56,
                          dividerThickness: 1,
                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                          columns: const [
                            DataColumn(label: Text('CUSTOMER')),
                            DataColumn(label: Text('YIELD DETAILS')),
                            DataColumn(label: Text('SETTLEMENT TARGET (BANK)')),
                            DataColumn(label: Text('DISPATCH STATUS')),
                            DataColumn(label: Text('ACTIONS')),
                          ],
                          rows: const [], // Empty rows array
                        ),
                      ),
                    ),
                    
                    // Empty State Graphic and Text
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 80),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 48,
                            color: const Color(0xFFCBD5E1).withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'NO DISBURSEMENTS FOUND IN HISTORICAL LEDGER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFFCBD5E1),
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32), // Pill shape
        border: Border.all(color: AppColors.kBorder),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'SEARCH INVESTOR IDENTITIES...',
          hintStyle: TextStyle(
            color: AppColors.kTextMuted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
          prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return OutlinedButton.icon(
      onPressed: () {
        // Export logic
      },
      icon: const Icon(Icons.download_outlined, size: 18),
      label: const Text(
        'EXPORT EXCEL',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          fontSize: 11,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF94A3B8),
        side: const BorderSide(color: AppColors.kBorder),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32), // Pill shape
        ),
      ),
    );
  }
}