import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/auditor_wallet_model.dart';
import '../../services/auditor_wallet_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class AuditorWalletScreen extends StatefulWidget {
  // Wire this to however your app currently identifies the logged-in user.
  final String userId;

  const AuditorWalletScreen({super.key, required this.userId});

  @override
  State<AuditorWalletScreen> createState() => _AuditorWalletScreenState();
}

class _AuditorWalletScreenState extends State<AuditorWalletScreen> {
  final Color _navyBlue = const Color(0xFF1B233A);
  final Color _lightBorder = const Color(0xFFF1F5F9);
  final Color _slateText = const Color(0xFF94A3B8);

  final _currency = NumberFormat('#,##0', 'en_IN');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  WalletOverview _overview = WalletOverview.empty();
  List<WalletTransactionRecord> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview = await AuditorWalletService.instance.fetchOverview(widget.userId);
      final txns = await AuditorWalletService.instance.fetchTransactions(widget.userId, limit: 5);
      setState(() {
        _overview = overview;
        _transactions = txns;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _money(double v) => '₹${_currency.format(v)}';

  // --- ACTIONS ---
  /// Opens the disbursement hub, where the amount and bank details are
  /// entered. Pushed rather than switched so BACK TO WALLET returns here.
  void _handleWithdraw() => context.push('/auditor-withdrawals');

  /// Routes the action tiles that have a real destination. Anything without
  /// one still falls through to the placeholder toast.
  void _handleAction(String actionName) {
    switch (actionName) {
      case 'BUY GOLD':
        context.push('/auditor-buy');
        return;
      case 'TRANSACTION HISTORY':
      case 'View All Transactions':
        context.push('/auditor-transaction');
        return;
      case 'VIEW AGREEMENT':
        context.push('/auditor-agreements');
        return;
      case 'REFERRAL LINK':
        context.push('/auditor-referral');
        return;
      default:
        ToastService.show(
          title: actionName,
          message: 'Routing to $actionName module...',
          type: ToastType.info,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return AppPage(
      title: null,
      children: [
        Center(
          child: Container(
                        constraints: const BoxConstraints(maxWidth: 800), 
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 120),
                    child: Center(child: AppLoader()),
                  )
                : _error != null
                    ? _buildErrorState(_error!)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLiveBalanceCard(),
                          const SizedBox(height: 24),
                          _buildStatCardsList(),
                          const SizedBox(height: 24),
                          _buildActionGrid(isMobile),
                          const SizedBox(height: 24),
                          _buildRecentTransactionsTable(),
                          const SizedBox(height: 40),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 40, color: _slateText),
          const SizedBox(height: 12),
          Text('COULD NOT LOAD WALLET', style: TextStyle(color: _navyBlue, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          Text(message, style: TextStyle(color: _slateText, fontSize: 11), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _load, child: const Text('RETRY')),
        ],
      ),
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
        boxShadow: [BoxShadow(color: _navyBlue.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: const [
                    Icon(Icons.star, color: AppColors.goldColor, size: 8),
                    SizedBox(width: 8),
                    Text('LIVE BALANCE', style: TextStyle(color: AppColors.goldColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.credit_card, color: AppColors.goldColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('AVAILABLE BALANCE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_money(_overview.balance), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0)),
              const SizedBox(width: 8),
              const Text('INR', style: TextStyle(color: AppColors.goldColor, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
            ],
          ),
          const SizedBox(height: 40),
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
                onPressed: () => _handleAction('BUY GOLD'),
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
        _buildListStatCard('TOTAL INVESTED', _money(_overview.totalInvested), Icons.track_changes, AppColors.goldBadgeBg, AppColors.goldColor),
        const SizedBox(height: 12),
        _buildListStatCard('CASHBACK EARNED', _money(_overview.cashbackEarnings), Icons.bolt, AppColors.goldBadgeBg, AppColors.goldColor),
        const SizedBox(height: 12),
        _buildListStatCard('REFERRAL REWARDS', _money(_overview.referralEarnings), Icons.military_tech_outlined, const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
        const SizedBox(height: 12),
        _buildListStatCard('PENDING PAYOUTS', _money(_overview.pendingPayouts), Icons.access_time, const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
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
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: _navyBlue, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
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
                          DataCell(Text('NO TRANSACTIONS YET', style: TextStyle(color: Color(0xFFCBD5E1), fontStyle: FontStyle.italic, fontWeight: FontWeight.w900, fontSize: 10))),
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

  DataRow _buildTransactionRow(WalletTransactionRecord txn) {
    return DataRow(
      cells: [
        DataCell(Text(txn.id, style: TextStyle(color: _navyBlue, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12))),
        DataCell(Text(txn.category.toUpperCase(), style: TextStyle(color: _slateText, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 0.5))),
        DataCell(Text(_money(txn.amount), style: TextStyle(color: _navyBlue, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13))),
        DataCell(_buildStatusBadge(txn.status)),
        DataCell(Text(txn.date != null ? _dateFmt.format(txn.date!) : '-', style: TextStyle(color: _slateText, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11))),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.goldBadgeBg;
    Color text = AppColors.goldColor;

    if (status == 'CREDITED' || status == 'COMPLETED') {
      bg = const Color(0xFFF0FDF4); text = const Color(0xFF16A34A);
    } else if (status == 'PENDING') {
      bg = const Color(0xFFFFFBEB); text = AppColors.goldColor;
    } else if (status == 'FAILED' || status == 'REJECTED') {
      bg = const Color(0xFFFEF2F2); text = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: text, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 9, letterSpacing: 0.5)),
    );
  }
}