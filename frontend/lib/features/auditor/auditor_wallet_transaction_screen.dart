import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import '../../models/auditor_wallet_model.dart';
import '../../services/auditor_wallet_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class AuditorWalletTransactionScreen extends StatefulWidget {
  final String userId;

  const AuditorWalletTransactionScreen({super.key, required this.userId});

  @override
  State<AuditorWalletTransactionScreen> createState() => _AuditorWalletTransactionScreenState();
}

const List<String> _kCategoryFilters = ['ALL TYPES', 'CASHBACK', 'REFERRAL', 'WITHDRAWAL', 'PURCHASE'];

class _AuditorWalletTransactionScreenState extends State<AuditorWalletTransactionScreen> {
  final _currency = NumberFormat('#,##0.00', 'en_IN');
  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _searchCtrl = TextEditingController();

  WalletOverview _overview = WalletOverview.empty();
  List<WalletTransactionRecord> _all = [];
  List<WalletTransactionRecord> _filtered = [];

  String _categoryFilter = 'ALL TYPES';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applySearch);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview = await AuditorWalletService.instance.fetchOverview(widget.userId);
      final category = _categoryFilter == 'ALL TYPES' ? null : _categoryFilter.toLowerCase();
      final txns = await AuditorWalletService.instance.fetchTransactions(
        widget.userId,
        category: category,
        limit: 100,
      );
      setState(() {
        _overview = overview;
        _all = txns;
        _loading = false;
      });
      _applySearch();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all
              .where((t) =>
                  t.id.toLowerCase().contains(q) ||
                  t.category.toLowerCase().contains(q) ||
                  t.status.toLowerCase().contains(q))
              .toList();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() => _categoryFilter = category);
    _load();
  }

  String _money(double v) => '₹${_currency.format(v)}';

  @override
  Widget build(BuildContext context) {
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
                          _buildBalanceCard(),
                          const SizedBox(height: 24),
                          _buildStatCard('TOTAL CASHBACK', _money(_overview.cashbackEarnings)),
                          const SizedBox(height: 24),
                          _buildStatCard('REFERRAL REWARDS', _money(_overview.referralEarnings)),
                          const SizedBox(height: 24),
                          _buildSearchAndFilterSection(),
                          const SizedBox(height: 24),
                          _buildTransactionTable(context),
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
          const Icon(Icons.error_outline, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text('COULD NOT LOAD TRANSACTIONS', style: TextStyle(color: AppColors.kPrimaryDark, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _load, child: const Text('RETRY')),
        ],
      ),
    );
  }

  // ==========================================================================
  // 1. BALANCE CARD
  // ==========================================================================
  Widget _buildBalanceCard() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.kPrimaryDark,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppColors.kPrimaryDark.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.account_balance_wallet, size: 160, color: Colors.white.withOpacity(0.05)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('AVAILABLE BALANCE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(_money(_overview.balance), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 2. STAT CARDS
  // ==========================================================================
  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(color: AppColors.kPrimaryDark, fontSize: 36, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0)),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 3. SEARCH AND FILTER SECTION
  // ==========================================================================
  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.kPrimaryDark, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'SEARCH TRANSACTIONS...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 0.5),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kPrimaryDark, width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                    child: DropdownButton<String>(
                      value: _categoryFilter,
                      isExpanded: true,
                      icon: const Icon(Icons.filter_alt_outlined, color: Color(0xFF94A3B8), size: 16),
                      style: const TextStyle(color: AppColors.kTextDark, fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5),
                      items: _kCategoryFilters
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _onCategoryChanged(v);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: _load,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimaryDark,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.kPrimaryDark.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.sync, color: AppColors.goldColor, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 4. TRANSACTIONS TABLE
  // ==========================================================================
  /// Below this width the table becomes a list of cards; the old fixed-width
  /// columns (570px + padding) overflowed every phone.
  static const double _kTableMinWidth = 560;

  Widget _buildTransactionTable(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < _kTableMinWidth;

          if (_filtered.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!compact) _buildHeaderRow(),
                _buildEmptyState(),
              ],
            );
          }

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _filtered.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
                  _buildCompactRow(_filtered[i]),
                ],
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderRow(),
              ..._filtered.map(_buildDataRow),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  // Column flex weights shared by the header and data rows.
  static const _kFlexId = 2, _kFlexDetails = 3, _kFlexAmount = 3, _kFlexStatus = 2, _kFlexDate = 2;

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          _buildHeaderCell('ID', flex: _kFlexId),
          _buildHeaderCell('DETAILS', flex: _kFlexDetails),
          _buildHeaderCell('AMOUNT', flex: _kFlexAmount),
          _buildHeaderCell('STATUS', flex: _kFlexStatus),
          _buildHeaderCell('DATE', flex: _kFlexDate),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
    );
  }

  Widget _cell(int flex, Widget child) => Expanded(
        flex: flex,
        child: Padding(padding: const EdgeInsets.only(right: 8), child: child),
      );

  Widget _buildDataRow(WalletTransactionRecord txn) {
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              _cell(_kFlexId, Text(txn.id, maxLines: 1, overflow: TextOverflow.ellipsis, style: _dataStyle(color: AppColors.kPrimaryDark))),
              _cell(_kFlexDetails, Text(_categoryLabel(txn), maxLines: 2, overflow: TextOverflow.ellipsis, style: _dataStyle())),
              _cell(
                _kFlexAmount,
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(_money(txn.amount), style: _dataStyle(color: AppColors.kPrimaryDark, size: 14)),
                ),
              ),
              _cell(_kFlexStatus, _buildStatusBadge(txn.status)),
              _cell(_kFlexDate, Text(_dateText(txn), maxLines: 2, style: _dataStyle(color: const Color(0xFF94A3B8), size: 10))),
            ],
          ),
        ),
      ],
    );
  }

  /// Phone layout: ID, type and date on the left; amount and status on the
  /// right.
  Widget _buildCompactRow(WalletTransactionRecord txn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_categoryLabel(txn), maxLines: 2, overflow: TextOverflow.ellipsis, style: _dataStyle()),
                const SizedBox(height: 6),
                Text('#${txn.id} · ${_dateText(txn)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: _dataStyle(color: const Color(0xFF94A3B8), size: 10)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(_money(txn.amount), style: _dataStyle(color: AppColors.kPrimaryDark, size: 14)),
                ),
                const SizedBox(height: 8),
                _buildStatusBadge(txn.status, alignment: Alignment.centerRight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(WalletTransactionRecord txn) => txn.category.replaceAll('_', ' ').toUpperCase();

  String _dateText(WalletTransactionRecord txn) => txn.date != null ? _dateFmt.format(txn.date!) : '-';

  TextStyle _dataStyle({Color color = AppColors.kTextDark, double size = 12}) {
    return TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: size, color: color);
  }

  Widget _buildStatusBadge(String status, {Alignment alignment = Alignment.centerLeft}) {
    Color bg = AppColors.goldBadgeBg;
    Color text = AppColors.goldColor;

    if (status == 'CREDITED' || status == 'COMPLETED') {
      bg = const Color(0xFFF0FDF4); text = const Color(0xFF16A34A);
    } else if (status == 'PENDING') {
      bg = const Color(0xFFFFFBEB); text = AppColors.goldColor;
    }

    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: text, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 9, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SizedBox(
      width: double.infinity,
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart_rounded, size: 64, color: Color(0xFFE2E8F0)),
          SizedBox(height: 16),
          Text(
            'NO TRANSACTIONS YET',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }
}