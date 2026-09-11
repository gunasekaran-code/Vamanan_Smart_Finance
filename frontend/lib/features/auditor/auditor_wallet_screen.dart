import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

// --- Dummy Data Model ---
class TransactionItem {
  final String id;
  final String category;
  final double amount;
  final String status;
  final String date;

  TransactionItem({
    required this.id,
    required this.category,
    required this.amount,
    required this.status,
    required this.date,
  });
}

class AuditorWalletScreen extends StatefulWidget {
  const AuditorWalletScreen({super.key});

  @override
  State<AuditorWalletScreen> createState() => _AuditorWalletScreenState();
}

class _AuditorWalletScreenState extends State<AuditorWalletScreen> {
  // Exact Colors from your design
  final Color _navyBlue = const Color(0xFF1B233A);
  final Color _lightBorder = const Color(0xFFF1F5F9);
  final Color _slateText = const Color(0xFF94A3B8);

  // Sample Transaction Data
  final List<TransactionItem> _transactions = [
    TransactionItem(id: 'TXN-001', category: 'CASHBACK', amount: 5000.00, status: 'CREDITED', date: '04/09/2026'),
    TransactionItem(id: 'TXN-002', category: 'REFERRAL', amount: 1000.00, status: 'CREDITED', date: '02/09/2026'),
    TransactionItem(id: 'TXN-003', category: 'WITHDRAWAL', amount: 3000.00, status: 'PENDING', date: '01/09/2026'),
  ];

  // --- ACTIONS ---
  Future<void> _handleWithdraw() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Initiate Withdrawal',
      message: 'Are you sure you want to withdraw your available balance to your registered bank account?',
      confirmLabel: 'Withdraw',
      confirmButtonColor: AppColors.goldColor,
    );

    if (confirmed == true) {
      ToastService.show(
        title: 'Withdrawal Initiated',
        message: 'Your withdrawal request is being processed.',
        type: ToastType.success,
      );
    }
  }

  void _handleAction(String actionName) {
    ToastService.show(
      title: actionName,
      message: 'Routing to $actionName module...',
      type: ToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return AppPage(
      title: null, // Custom layout requires no default header
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. LIVE BALANCE CARD
                _buildLiveBalanceCard(),
                const SizedBox(height: 24),

                // 2. STAT CARDS LIST
                _buildStatCardsList(),
                const SizedBox(height: 24),

                // 3. ACTION GRID
                _buildActionGrid(isMobile),
                const SizedBox(height: 24),

                // 4. RECENT TRANSACTIONS TABLE
                _buildRecentTransactionsTable(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // 1. LIVE BALANCE CARD
  // ==========================================================================
  Widget _buildLiveBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF233876), _navyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: _navyBlue.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 12))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, color: AppColors.goldColor, size: 8),
                    SizedBox(width: 8),
                    Text(
                      'LIVE BALANCE',
                      style: TextStyle(color: AppColors.goldColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.credit_card, color: AppColors.goldColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Balance Amount
          const Text('AVAILABLE BALANCE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: const [
              Text('₹0.00', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0)),
              SizedBox(width: 8),
              Text('INR', style: TextStyle(color: AppColors.goldColor, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
            ],
          ),
          const SizedBox(height: 40),

          // Action Buttons (Stacked like the screenshot)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: _handleWithdraw,
                icon: const Icon(Icons.arrow_outward, size: 16),
                label: const Text('WITHDRAW MONEY', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1.0)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldColor,
                  foregroundColor: _navyBlue,
                  elevation: 10,
                  shadowColor: AppColors.goldColor.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _handleAction('Buy Gold'),
                icon: const Icon(Icons.bolt, size: 16),
                label: const Text('BUY GOLD', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1.0)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 2. STAT CARDS LIST
  // ==========================================================================
  Widget _buildStatCardsList() {
    return Column(
      children: [
        _buildListStatCard('TOTAL INVESTED', '₹0', Icons.track_changes, AppColors.goldBadgeBg, AppColors.goldColor),
        const SizedBox(height: 12),
        _buildListStatCard('CASHBACK EARNED', '₹0', Icons.bolt, AppColors.goldBadgeBg, AppColors.goldColor),
        const SizedBox(height: 12),
        _buildListStatCard('REFERRAL REWARDS', '₹0', Icons.military_tech_outlined, const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
        const SizedBox(height: 12),
        _buildListStatCard('PENDING PAYOUTS', '₹0', Icons.access_time, const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
      ],
    );
  }

  Widget _buildListStatCard(String title, String value, IconData icon, Color iconBg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _lightBorder, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: _slateText, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: _navyBlue, fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 3. ACTION GRID
  // ==========================================================================
  Widget _buildActionGrid(bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildGridActionCard('REFERRAL LINK', Icons.share_outlined, const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
        _buildGridActionCard('VIEW AGREEMENT', Icons.shield_outlined, AppColors.goldBadgeBg, AppColors.goldColor),
        _buildGridActionCard('BUY GOLD', Icons.language, AppColors.goldBadgeBg, AppColors.goldColor),
        _buildGridActionCard('TRANSACTION HISTORY', Icons.history, const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
      ],
    );
  }

  Widget _buildGridActionCard(String title, IconData icon, Color iconBg, Color iconColor) {
    return InkWell(
      onTap: () => _handleAction(title),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _lightBorder, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: _navyBlue, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 4. RECENT TRANSACTIONS TABLE
  // ==========================================================================
  Widget _buildRecentTransactionsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _lightBorder, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.show_chart, color: AppColors.goldColor, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RECENT TRANSACTIONS', style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('YOUR LATEST ACTIVITY', style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _handleAction('View All Transactions'),
                  child: const Text('VIEW ALL >', style: TextStyle(color: AppColors.goldColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                )
              ],
            ),
          ),
          const Divider(height: 1, thickness: 2, color: Color(0xFFF1F5F9)),
          
          // Scrollable Data Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width > 800 ? 800 : MediaQuery.of(context).size.width - 64),
              child: DataTable(
                columnSpacing: 24,
                headingRowHeight: 56,
                dataRowMinHeight: 70,
                dataRowMaxHeight: 70,
                headingTextStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 9, letterSpacing: 1.0),
                columns: const [
                  DataColumn(label: Text('TRANSACTION\nID')),
                  DataColumn(label: Text('CATEGORY')),
                  DataColumn(label: Text('AMOUNT')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('DATE')),
                ],
                rows: _transactions.isEmpty
                    ? [
                        const DataRow(cells: [
                          DataCell(Text('ZERO ACTIVE TRANSMISSIONS DETECTED', style: TextStyle(color: Color(0xFFCBD5E1), fontStyle: FontStyle.italic, fontWeight: FontWeight.w900, fontSize: 10))),
                          DataCell(Text('')), DataCell(Text('')), DataCell(Text('')), DataCell(Text('')),
                        ])
                      ]
                    : _transactions.map((txn) => _buildTransactionRow(txn)).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  DataRow _buildTransactionRow(TransactionItem txn) {
    return DataRow(
      cells: [
        DataCell(Text(txn.id, style: TextStyle(color: _navyBlue, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12))),
        DataCell(Text(txn.category, style: TextStyle(color: _slateText, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 0.5))),
        DataCell(Text('₹${txn.amount.toStringAsFixed(2)}', style: TextStyle(color: _navyBlue, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13))),
        DataCell(_buildStatusBadge(txn.status)),
        DataCell(Text(txn.date, style: TextStyle(color: _slateText, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11))),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.goldBadgeBg;
    Color text = AppColors.goldColor;

    if (status == 'CREDITED') {
      bg = const Color(0xFFF0FDF4); text = const Color(0xFF16A34A);
    } else if (status == 'PENDING') {
      bg = const Color(0xFFFFFBEB); text = AppColors.goldColor;
    } else if (status == 'FAILED') {
      bg = const Color(0xFFFEF2F2); text = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: text, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 9, letterSpacing: 0.5)),
    );
  }
}