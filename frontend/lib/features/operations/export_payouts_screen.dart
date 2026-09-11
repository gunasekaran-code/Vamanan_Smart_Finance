import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/stat_card.dart'; // Make sure this points to your shared StatCard file

class ExportPayoutsScreen extends StatefulWidget {
  const ExportPayoutsScreen({super.key});

  @override
  State<ExportPayoutsScreen> createState() => _ExportPayoutsScreenState();
}

class _ExportPayoutsScreenState extends State<ExportPayoutsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFC), // Light crisp background matching design
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
                  borderRadius: BorderRadius.circular(
                      12), // Matching the softer rounding in this screen
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
              const SizedBox(height: 24),

              // --- 2. Action Header Bar ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: LayoutBuilder(builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;

                  Widget headerText = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description_outlined,
                          color: Color(0xFFFBBF24), size: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EXPORT PAYOUT FILE',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF1E3A8A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'LIVE SYNC ACTIVE · PULSE: 1:46:23 PM',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFF94A3B8).withOpacity(0.8),
                                letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ],
                  );

                  Widget actionButtons = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment:
                        isMobile ? WrapAlignment.start : WrapAlignment.end,
                    children: [
                      // Refresh button
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.kBorder),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.refresh,
                            size: 18, color: AppColors.kTextMuted),
                      ),

                      // Preview Button
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('PREVIEW BATCH',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                fontSize: 11,
                                letterSpacing: 0.5)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF94A3B8),
                          side: const BorderSide(color: AppColors.kBorder),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),

                      // Generate Bulk Transfer Button
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon:
                            const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('GENERATE BULK TRANSFER',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                fontSize: 11,
                                letterSpacing: 0.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                              0xFF8B98C6), // Muted purple/blue from design
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        headerText,
                        const SizedBox(height: 20),
                        actionButtons,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      headerText,
                      actionButtons,
                    ],
                  );
                }),
              ),
              const SizedBox(height: 24),

              // --- 3. Statistics Grid (4 columns on desktop, 2x2 on mobile) ---
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isWide = screenWidth > 800;
                  final isSmallMobile = screenWidth < 380;
                  int crossAxisCount = isWide ? 4 : 2;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: isSmallMobile ? 8.0 : 16.0,
                    mainAxisSpacing: isSmallMobile ? 8.0 : 16.0,
                    childAspectRatio:
                        isWide ? 1.8 : (isSmallMobile ? 0.82 : 1.2),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      StatCard(
                        label: "TODAY'S YIELD",
                        value: '₹0',
                        icon: Icons.attach_money,
                        color: Color(0xFFD97706),
                        badgeText: 'TODAY',
                        backgroundColor: AppColors.goldBg,
                        borderColor: AppColors.goldBorder,
                        badgeBackgroundColor: AppColors.goldBadgeBg,
                        badgeTextColor: AppColors.goldColor,
                      ),
                      StatCard(
                        label: 'ACTIVE CYCLES',
                        value: '0',
                        icon: Icons.people_outline,
                        color: Color(0xFF3B82F6),
                        badgeText: 'ACTIVE',
                        backgroundColor: Color(0xFFF0F7FF),
                        borderColor: Color(0xFFBFDBFE),
                        badgeBackgroundColor: Color(0xFFDBEAFE),
                        badgeTextColor: Color(0xFF1D4ED8),
                      ),
                      StatCard(
                        label: 'TOTAL PAID',
                        value: '₹0',
                        icon: Icons.check_circle_outline,
                        color: Color(0xFFD97706),
                        badgeText: 'PAID',
                        backgroundColor: AppColors.goldBg,
                        borderColor: AppColors.goldBorder,
                        badgeBackgroundColor: AppColors.goldBadgeBg,
                        badgeTextColor: AppColors.goldColor,
                      ),
                      StatCard(
                        label: 'LAST PAYOUT',
                        value: 'Never',
                        icon: Icons.calendar_today_outlined,
                        color: Color(0xFF3B82F6),
                        badgeText: 'HISTORY',
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

              // --- 4. Filters Bar ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                      32), // Pill shape for filter row container
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: LayoutBuilder(builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;

                  Widget searchField = Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.kBorder),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'SEARCH INVESTOR OR ACCOUNT...',
                        hintStyle: TextStyle(
                            color: AppColors.kTextMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic),
                        prefixIcon: Icon(Icons.search,
                            color: AppColors.kTextMuted, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  );

                  Widget filters = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildFilterPill(Icons.account_balance, 'BANK NODE'),
                      _buildFilterPill(Icons.shield_outlined, 'ALL STATUS'),
                      _buildFilterPill(
                          Icons.calendar_today_outlined, '02/09/2026'),
                    ],
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchField,
                        const SizedBox(height: 16),
                        filters,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 2, child: searchField),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: filters),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 24),

              // --- 5. Main Data Table (with Empty State) ---
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
                          minWidth: MediaQuery.of(context).size.width - 48,
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
                            DataColumn(label: Text('BANK DETAILS')),
                            DataColumn(label: Text('PAYOUT VALUE')),
                            DataColumn(label: Text('STATUS')),
                            DataColumn(label: Text('ACTIONS')),
                          ],
                          rows: const [], // Empty rows array
                        ),
                      ),
                    ),

                    // Empty State Text
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 80),
                      alignment: Alignment.center,
                      child: const Text(
                        'NO PENDING TRANSFERS FOUND',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- 6. Export History Header ---
              Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'EXPORT HISTORY',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF1E3A8A),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  // Custom stat card builder to match the specific rounded corner style in the image
  Widget _buildStylizedStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color cornerColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorder),
      ),
      // Using Stack to overlay the top-right colored corner swoop
      child: Stack(
        children: [
          // The top right colored corner shape
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cornerColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomLeft: Radius.circular(100),
                ),
              ),
            ),
          ),

          // The actual content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cornerColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF1E3A8A),
                        letterSpacing: -0.5,
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

  Widget _buildFilterPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.kTextMuted),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
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
