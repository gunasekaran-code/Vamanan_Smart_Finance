import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/stat_card.dart'; // Make sure this points to your shared StatCard file

class PlBalanceSheetWidget extends StatefulWidget {
  const PlBalanceSheetWidget({super.key});

  @override
  State<PlBalanceSheetWidget> createState() => _PlBalanceSheetWidgetState();
}

class _PlBalanceSheetWidgetState extends State<PlBalanceSheetWidget> {
  String _activeSubTab = 'PROFIT & LOSS';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- 1. Sub-Navigation Toggle ---
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSubTab('PROFIT & LOSS', Icons.trending_up),
            _buildSubTab('BALANCE SHEET', Icons.account_balance_outlined),
          ],
        ),
        const SizedBox(height: 32),

        if (_activeSubTab == 'PROFIT & LOSS') ...[
          // --- 2. Profit & Loss Metrics Grid ---
          LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 600;
            return GridView.count(
              crossAxisCount: isMobile ? 1 : 3, // Stack vertically on mobile, side-by-side on desktop
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 2.5 : 1.4, // Adjust proportions for mobile vs desktop
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                StatCard(
                  label: 'TOTAL INCOME',
                  value: '₹1,89,06,774.50',
                  icon: Icons.arrow_downward, // Income flowing in
                  color: Color(0xFFD97706), // Gold/Amber
                  backgroundColor: Colors.white,
                ),
                StatCard(
                  label: 'TOTAL EXPENSE',
                  value: '₹3,65,414.58',
                  icon: Icons.arrow_upward, // Expenses flowing out
                  color: Color(0xFF3B82F6), // Blue
                  backgroundColor: Colors.white,
                ),
                StatCard(
                  label: 'NET PROFIT (98.07%)',
                  value: '₹1,85,41,359.92',
                  icon: Icons.account_balance_wallet_outlined,
                  color: Color(0xFFD97706), // Gold/Amber
                  backgroundColor: Colors.white,
                ),
              ],
            );
          }),
          const SizedBox(height: 32),

          // --- 3. Income Statement Table ---
          _buildFinancialTable(
            title: 'INCOME',
            items: [
              _FinancialItem('Sales Revenue (excl. GST)', '₹1,89,06,774.50'),
            ],
            totalLabel: 'TOTAL INCOME',
            totalValue: '₹1,89,06,774.50',
            totalColor: const Color(0xFFD97706), // Gold
          ),
          const SizedBox(height: 24),

          // --- 4. Expenses Statement Table ---
          _buildFinancialTable(
            title: 'EXPENSES',
            items: [
              _FinancialItem('Cashback Payouts', '₹3,09,911.16'),
              _FinancialItem('Referral Commissions', '₹55,503.42'),
            ],
            totalLabel: 'TOTAL EXPENSES',
            totalValue: '₹3,65,414.58',
            totalColor: const Color(0xFF3B82F6), // Blue
          ),
        ] else ...[
          // Placeholder for Balance Sheet
          Container(
            padding: const EdgeInsets.symmetric(vertical: 80),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: const Text(
              'BALANCE SHEET REPORTS PENDING SYNC',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.5,
              ),
            ),
          )
        ],
      ],
    );
  }

  // --- Sub-Tab Builder ---
  Widget _buildSubTab(String label, IconData icon) {
    bool isActive = _activeSubTab == label;
    return InkWell(
      onTap: () => setState(() => _activeSubTab = label),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? const Color(0xFF1E3A8A) : AppColors.kBorder),
          boxShadow: isActive
              ? [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? const Color(0xFFFBBF24) : AppColors.kTextMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: isActive ? Colors.white : const Color(0xFF1E3A8A),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Financial Table Builder ---
  Widget _buildFinancialTable({
    required String title,
    required List<_FinancialItem> items,
    required String totalLabel,
    required String totalValue,
    required Color totalColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Title Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1E3A8A),
                letterSpacing: 2,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.kBorder),

          // Items List
          ...items.map((item) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          item.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF1E3A8A),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.kBorder),
                ],
              )),

          // Total Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  totalLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF1E3A8A),
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  totalValue,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: totalColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Simple internal model for table rows
class _FinancialItem {
  final String label;
  final String value;
  _FinancialItem(this.label, this.value);
}