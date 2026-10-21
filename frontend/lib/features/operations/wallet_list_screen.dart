import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/wallet_account_model.dart';
import '../../../services/wallet_account_service.dart';
import 'wallet_adjustment_screen.dart';
import 'wallet_purchase_history.dart';
import 'wallet_view_investor.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class WalletListScreen extends StatefulWidget {
  const WalletListScreen({super.key});

  @override
  State<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends State<WalletListScreen> {
  // Theme Colors matching the images
  static const Color primaryBlue = Color(0xFF273A6C);
  static const Color accentGold = Color(0xFFF5A623);
  static const Color bgLightGrey = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);

  final WalletService _service = WalletService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<WalletAccount> _allWallets = [];
  List<WalletAccount> _visibleWallets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final wallets = await _service.fetchWallets();
      if (!mounted) return;
      setState(() {
        _allWallets = wallets;
        _visibleWallets = _applyFilter(wallets, _searchController.text);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _visibleWallets = _applyFilter(_allWallets, _searchController.text);
      });
    });
  }

  List<WalletAccount> _applyFilter(List<WalletAccount> wallets, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return wallets;
    return wallets.where((w) {
      return w.userName.toLowerCase().contains(q) ||
          (w.userEmail ?? '').toLowerCase().contains(q) ||
          (w.userPhone ?? '').toLowerCase().contains(q);
    }).toList();
  }

  // --- Aggregate stats, computed live from the fetched wallets ---
  double get _totalManagedCapital =>
      _allWallets.fold(0.0, (sum, w) => sum + w.balance);
  double get _totalYieldDispatched =>
      _allWallets.fold(0.0, (sum, w) => sum + w.totalEarned);
  double get _totalOutflow =>
      _allWallets.fold(0.0, (sum, w) => sum + w.totalWithdrawn);
  int get _activeNodeCount => _allWallets.length;

  void _showToastMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ),
        backgroundColor: isError ? const Color(0xFFB91C1C) : primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- Navigation actions, wired to the three destination screens ---

  void _viewPurchaseHistory(WalletAccount wallet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalletPurchaseHistoryScreen(wallet: wallet),
      ),
    );
  }

  void _viewUser(WalletAccount wallet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalletViewInvestorScreen(wallet: wallet),
      ),
    );
  }

  Future<void> _openAdjustment(WalletAccount wallet) async {
    final adjusted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WalletAdjustmentScreen(
          userId: wallet.userId,
          userName: wallet.userName,
          currentBalance: wallet.balance,
        ),
      ),
    );

    // Refresh the list if the adjustment screen reports a successful change.
    if (adjusted == true) {
      _showToastMessage('Wallet updated for ${wallet.userName}');
      _loadWallets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLightGrey,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWallets,
          color: primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. Page Header ---
                  const Text(
                    'INVESTOR WALLETS',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: primaryBlue,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MANAGEMENT PORTAL FOR CAPITAL FLOWS AND NETWORK YIELDS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: textMuted.withOpacity(0.8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- 2. Search & Filter Bar ---
                  LayoutBuilder(builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 640;
                    final searchField = Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: borderLight),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'SEARCH IDENTITY OR PROTOCOL...',
                          hintStyle: const TextStyle(
                            color: textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                          prefixIcon: const Icon(Icons.search,
                              color: textMuted, size: 22),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear,
                                      size: 18, color: textMuted),
                                  onPressed: () => _searchController.clear(),
                                ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    );
                    final ledgerChip = Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderLight),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'GLOBAL LEDGER',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.unfold_more,
                              size: 16, color: Colors.black54),
                        ],
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          searchField,
                          const SizedBox(height: 12),
                          ledgerChip,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(flex: 3, child: searchField),
                        const SizedBox(width: 16),
                        Expanded(flex: 1, child: ledgerChip),
                      ],
                    );
                  }),
                  const SizedBox(height: 32),

                  // --- 3. Stats Grid (computed live from fetched wallets) ---
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double cardWidth = (constraints.maxWidth - 48) / 4;
                      if (constraints.maxWidth < 800) {
                        cardWidth = (constraints.maxWidth - 16) / 2;
                      }
                      if (constraints.maxWidth < 420) {
                        cardWidth = constraints.maxWidth;
                      }

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildStatCard(
                              'TOTAL MANAGED CAPITAL',
                              formatInr(_totalManagedCapital),
                              Icons.attach_money,
                              const Color(0xFFFFF7ED),
                              const Color(0xFFF59E0B),
                              cardWidth),
                          _buildStatCard(
                              'TOTAL YIELD DISPATCHED',
                              formatInr(_totalYieldDispatched),
                              Icons.trending_up,
                              const Color(0xFFFFF7ED),
                              const Color(0xFFF59E0B),
                              cardWidth),
                          _buildStatCard(
                              'ACTIVE INSTITUTIONAL NODES',
                              '$_activeNodeCount',
                              Icons.account_balance_wallet_outlined,
                              const Color(0xFFEFF6FF),
                              const Color(0xFF3B82F6),
                              cardWidth),
                          _buildStatCard(
                              'TOTAL OUTFLOW (LIQUIDATION)',
                              formatInr(_totalOutflow),
                              Icons.arrow_outward,
                              const Color(0xFFEFF6FF),
                              const Color(0xFF3B82F6),
                              cardWidth),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // --- 4. Content: loading / error / empty / table ---
                  _buildContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: AppLoader()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWallets,
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              child: const Text('RETRY', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_visibleWallets.isEmpty) {
      final hasQuery = _searchController.text.trim().isNotEmpty;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text(
            hasQuery
                ? 'No wallets match your search.'
                : 'No investor wallets found.',
            style:
                const TextStyle(color: textMuted, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // --- Scrollable Table Container ---
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTableHeader(),
                const Divider(height: 1, color: borderLight),
                ..._visibleWallets.map((wallet) => _buildTableRow(wallet)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildStatCard(String title, String value, IconData icon,
      Color iconBgColor, Color iconColor, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration:
                BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: textMuted,
                letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: primaryBlue),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: bgLightGrey.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _headerCell('CUSTOMER', 320),
          _headerCell('WALLET BALANCE', 200, align: Alignment.centerRight),
          _headerCell('ACTIVE PURCHASES', 180, align: Alignment.center),
          _headerCell('LAST YIELD', 150, align: Alignment.center),
          _headerCell('INTERVENTION', 200, align: Alignment.centerRight),
        ],
      ),
    );
  }

  Widget _headerCell(String title, double width,
      {Alignment align = Alignment.centerLeft}) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: align,
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: textMuted,
              letterSpacing: 1.5),
        ),
      ),
    );
  }

  Widget _buildTableRow(WalletAccount wallet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: borderLight, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Customer Column
          SizedBox(
            width: 320,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(
                    wallet.userName.isNotEmpty
                        ? wallet.userName.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: accentGold,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              wallet.userName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: primaryBlue,
                                  fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (wallet.isKycVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.shield_outlined,
                                size: 14, color: accentGold),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        wallet.userEmail ?? '—',
                        style: const TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildBadge(
                              (wallet.kycStatus ?? 'UNKNOWN').toUpperCase(),
                              const Color(0xFFFFFBEB),
                              const Color(0xFFD97706)),
                          _buildBadge((wallet.role ?? 'CUSTOMER').toUpperCase(),
                              const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Wallet Balance Column
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  wallet.formattedBalance,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: primaryBlue),
                ),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    Text('EARNED: ',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: accentGold.withOpacity(0.8))),
                    Text(wallet.formattedEarned,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: accentGold)),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text('|',
                            style: TextStyle(color: textMuted, fontSize: 9))),
                    Text('WITHDRAWN: ',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue.withOpacity(0.8))),
                    Text(wallet.formattedWithdrawn,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                  ],
                ),
              ],
            ),
          ),

          // 3. Active Purchases Column
          SizedBox(
            width: 180,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: bgLightGrey,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${wallet.activeCycles}',
                        style: const TextStyle(
                            color: accentGold,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            fontSize: 14)),
                    const SizedBox(width: 6),
                    const Text('ACTIVE CYCLES',
                        style: TextStyle(
                            color: textMuted,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            fontSize: 9)),
                  ],
                ),
              ),
            ),
          ),

          // 4. Last Yield Column
          SizedBox(
            width: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  wallet.lastPayoutLabel,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: primaryBlue),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _viewPurchaseHistory(wallet),
                  child: const Text('PAYOUT DETAILS',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: textMuted,
                          decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),

          // 5. Intervention Column
          SizedBox(
            width: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionIcon(Icons.person_outline, 'View investor',
                    () => _viewUser(wallet)),
                const SizedBox(width: 8),
                _buildActionIcon(Icons.history, 'Purchase history',
                    () => _viewPurchaseHistory(wallet)),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _openAdjustment(wallet),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.account_balance_wallet_outlined,
                      size: 16, color: Colors.white),
                  label: const Text(
                    'ADJUST',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: textColor,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: borderLight),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: textMuted),
        ),
      ),
    );
  }
}
