import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_toast.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  void _onExportSelected(String type) {
      ToastService.show(
        title: 'Export Started',
        message: 'Exporting $type to CSV format...',
        type: ToastType.success,
        duration: const Duration(seconds: 3),
      );
    }

    void _onPrintExportPressed() {
    ToastService.show(
      title: 'Preparing Document',
      message: 'Generating executive report for printing...',
      type: ToastType.info,
      duration: const Duration(seconds: 3),
    );
  }

PopupMenuItem<String> _buildExportMenuItem({
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.kTextDark,
            ),
          ),
        ],
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Executive Reports',
      subtitle: 'Visible to Super Admin and Admin only.',
      children: [
        // Action Buttons Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Export / Print Button
ElevatedButton.icon(
                onPressed: _onPrintExportPressed, // Calls ToastService.show
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2937),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),

             // Export CSV Dropdown
              PopupMenuButton<String>(
                onSelected: _onExportSelected, // Calls ToastService.show
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                color: AppColors.kSurface,
                itemBuilder: (context) => [
                  _buildExportMenuItem(
                    value: 'Member Ledger',
                    label: 'Member Ledger',
                    icon: Icons.people_outline,
                    iconColor: AppColors.kPrimary,
                  ),
                  _buildExportMenuItem(
                    value: 'Chit Transaction Feed',
                    label: 'Chit Transaction Feed',
                    icon: Icons.payments_outlined,
                    iconColor: Colors.blue,
                  ),
                  _buildExportMenuItem(
                    value: 'Loan Transaction Feed',
                    label: 'Loan Transaction Feed',
                    icon: Icons.account_balance_outlined,
                    iconColor: Colors.cyan,
                  ),
                  _buildExportMenuItem(
                    value: 'Security Logs',
                    label: 'Security Logs',
                    icon: Icons.shield_outlined,
                    iconColor: Colors.amber.shade700,
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.file_download_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Export CSV',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // KPI Summary Cards
        _buildKpiCard(
          title: 'TOTAL OUTSTANDING ARREARS',
          value: '₹92827.81',
          bgColor: const Color(0xFFFFF1F2),
          valueColor: AppColors.kDanger,
          badges: const [
            BadgeData(label: 'Chit: ₹0', color: AppColors.kDanger),
            BadgeData(label: 'Loan: ₹92827.81', color: AppColors.kDanger),
          ],
        ),
        const SizedBox(height: 12),

        _buildKpiCard(
          title: 'TOTAL COLLECTIONS (LTM / YTD)',
          value: '₹20078.14',
          bgColor: const Color(0xFFF0FDF4),
          valueColor: AppColors.kPrimary,
          subtitle: 'Consolidated collections across all accounts',
        ),
        const SizedBox(height: 12),

        _buildKpiCard(
          title: 'PORTFOLIO EFFICIENCY',
          value: '20076.1%',
          bgColor: const Color(0xFFEFF6FF),
          valueColor: Colors.blue.shade700,
          subtitle: 'Recovery Rate',
          showProgressBar: true,
        ),
        const SizedBox(height: 16),

        // Combined Recovery Cards
        _buildMetricTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'COMBINED RECOVERY (TODAY)',
          amount: '₹0.00',
          subLeft: 'Chit: ₹0',
          subRight: 'Loan: ₹0',
        ),
        const SizedBox(height: 10),

        _buildMetricTile(
          icon: Icons.calendar_today_outlined,
          title: 'COMBINED RECOVERY (YTD)',
          amount: '₹2063.00',
          subLeft: 'Chit: ₹0',
          subRight: 'Loan: ₹2063.00',
          badgeText: 'Monthly Collections',
          badgeColor: AppColors.kPrimaryLight,
          badgeTextColor: AppColors.kPrimary,
        ),
        const SizedBox(height: 10),

        _buildMetricTile(
          icon: Icons.today_outlined,
          title: 'COMBINED RECOVERY (TOD)',
          amount: '₹2063.00',
          subLeft: 'Chit: ₹0',
          subRight: 'Loan: ₹2063.00',
          badgeText: 'Monthly Collections',
          badgeColor: Colors.blue.shade50,
          badgeTextColor: Colors.blue.shade700,
        ),
        const SizedBox(height: 16),

        // Unified Branch Performance Table Card
        _buildSectionCard(
          icon: Icons.bar_chart_rounded,
          iconBg: AppColors.kPrimaryLight,
          iconColor: AppColors.kPrimary,
          title: 'Unified Branch Performance',
          subtitle: 'Consolidated financial recovery across all regional branch sites.',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowHeight: 40,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 48,
              columns: const [
                DataColumn(label: Text('BRANCH NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('MEMBERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('CHIT REVENUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('LOAN REVENUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              ],
              rows: const [
                DataRow(cells: [
                  DataCell(Text('Main Office', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  DataCell(Text('1')),
                  DataCell(Text('₹1000.00', style: TextStyle(color: Colors.blue))),
                  DataCell(Text('₹1250.00', style: TextStyle(color: Colors.blue))),
                ]),
                DataRow(cells: [
                  DataCell(Text("Teacher's Colony Branch", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  DataCell(Text('2')),
                  DataCell(Text('₹2000.00', style: TextStyle(color: Colors.blue))),
                  DataCell(Text('₹13828.14', style: TextStyle(color: Colors.blue))),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Chit Defaulters
        _buildSectionCard(
          icon: Icons.warning_amber_rounded,
          iconBg: const Color(0xFFFEE2E2),
          iconColor: AppColors.kDanger,
          title: 'Chit Defaulters',
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'NO DEFAULTERS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.kTextMuted),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Loan Overdue (EMI)
        _buildSectionCard(
          icon: Icons.account_balance_wallet_outlined,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: AppColors.kWarning,
          title: 'Loan Overdue (EMI)',
          child: Column(
            children: [
              _buildListRow('VEERASAMY.K', 'Loan LN-2026-0005', '₹90000.00', isOverdue: true),
              _buildListRow('Varshini', 'Loan LN-2026-0003', '₹2088.33', isOverdue: true),
              _buildListRow('Goki', 'Loan LN-2026-0002', '₹2015.00', isOverdue: true),
              _buildListRow('Varshini', 'Loan LN-2026-0006', '₹2000.00', isOverdue: true),
              _buildListRow('Roki', 'Loan LN-2026-0001', '₹1063.81', isOverdue: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Chit Collections
        _buildSectionCard(
          icon: Icons.collections_bookmark_outlined,
          iconBg: Colors.blue.shade50,
          iconColor: Colors.blue,
          title: 'Chit Collections',
          child: Column(
            children: [
              _buildListRow('Jessica', '10 Jul, 2026', '₹1000.00'),
              _buildListRow('Varshini', '20 Apr, 2026', '₹1000.00'),
              _buildListRow('Roki', '15 Apr, 2026', '₹1000.00'),
              _buildListRow('Jessica', '15 Apr, 2026', '₹1000.00'),
              _buildListRow('Goki', '10 Apr, 2026', '₹1000.00'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Loan Collections
        _buildSectionCard(
          icon: Icons.account_balance_outlined,
          iconBg: Colors.cyan.shade50,
          iconColor: Colors.cyan.shade700,
          title: 'Loan Collections',
          child: Column(
            children: [
              _buildListRow('Roki', '10 Aug, 2026', '₹2063.00'),
              _buildListRow('Jessica', '10 Jul, 2026', '₹1250.00'),
              _buildListRow('Jenni', '10 Jul, 2026', '₹1250.00'),
              _buildListRow('Jessica', '10 Jul, 2026', '₹2500.00'),
              _buildListRow('Varshini', '10 Jul, 2026', '₹1250.00'),
            ],
          ),
        ),
      ],
    );
  }

  // Helper Widgets
  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color bgColor,
    required Color valueColor,
    String? subtitle,
    List<BadgeData>? badges,
    bool showProgressBar = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.kTextMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
            ),
          ],
          if (badges != null) ...[
            const SizedBox(height: 8),
            Row(
              children: badges.map((b) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: b.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    b.label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: b.color),
                  ),
                );
              }).toList(),
            ),
          ],
          if (showProgressBar) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1.0,
                minHeight: 6,
                backgroundColor: Colors.blue.shade100,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String amount,
    required String subLeft,
    required String subRight,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: AppColors.kTextDark),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeTextColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.kTextMuted),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.kTextDark),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subLeft, style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
              Text(subRight, style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (subtitle != null)
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildListRow(String title, String subtitle, String amount, {bool isOverdue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
            ],
          ),
          Container(
            padding: isOverdue ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4) : EdgeInsets.zero,
            decoration: isOverdue
                ? BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6))
                : null,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isOverdue ? AppColors.kWarning : Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BadgeData {
  final String label;
  final Color color;

  const BadgeData({required this.label, required this.color});
}