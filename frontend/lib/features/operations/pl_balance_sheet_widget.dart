import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/tally_integration_model.dart';
import 'package:frontend/services/tally_integration_service.dart';
import 'package:frontend/shared/widgets/stat_card.dart';
import 'tally_state_views.dart';

/// Profit & Loss and Balance Sheet, from `?resource=report&report=pnl` and
/// `&report=balance_sheet`. Each report is fetched once, the first time its
/// tab is opened.
class PlBalanceSheetWidget extends StatefulWidget {
  const PlBalanceSheetWidget({super.key});

  @override
  State<PlBalanceSheetWidget> createState() => _PlBalanceSheetWidgetState();
}

class _PlBalanceSheetWidgetState extends State<PlBalanceSheetWidget> {
  final TallyIntegrationService _service = TallyIntegrationService();

  String _activeSubTab = 'PROFIT & LOSS';

  TallyPnlReport? _pnl;
  TallyBalanceSheet? _balanceSheet;
  bool _isLoading = true;
  String? _error;

  bool get _isPnlTab => _activeSubTab == 'PROFIT & LOSS';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_isPnlTab) {
        final pnl = await _service.fetchPnl();
        if (!mounted) return;
        setState(() => _pnl = pnl);
      } else {
        final sheet = await _service.fetchBalanceSheet();
        if (!mounted) return;
        setState(() => _balanceSheet = sheet);
      }
    } on TallyIntegrationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectTab(String label) {
    if (label == _activeSubTab) return;
    setState(() {
      _activeSubTab = label;
      _error = null;
    });
    // Each report is cached after its first fetch; re-opening a tab is instant.
    final alreadyLoaded = _isPnlTab ? _pnl != null : _balanceSheet != null;
    if (!alreadyLoaded) _load();
  }

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
        _buildBody(),
      ],
    );
  }

  Widget _buildBody() {
    final report = _isPnlTab ? _pnl : _balanceSheet;
    if (_isLoading && report == null) {
      return TallyLoadingCard(label: 'LOADING $_activeSubTab');
    }
    if (_error != null && report == null) {
      return TallyErrorCard(message: _error!, onRetry: _load);
    }
    return _isPnlTab ? _buildPnl(_pnl!) : _buildBalanceSheet(_balanceSheet!);
  }

  // --- Profit & Loss ---

  Widget _buildPnl(TallyPnlReport pnl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;
          return GridView.count(
            crossAxisCount: isMobile ? 1 : 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isMobile ? 2.5 : 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatCard(
                label: 'TOTAL INCOME',
                value: formatInr(pnl.totalIncome),
                icon: Icons.arrow_downward,
                color: kTallyGold,
                backgroundColor: Colors.white,
              ),
              StatCard(
                label: 'TOTAL EXPENSE',
                value: formatInr(pnl.totalExpense),
                icon: Icons.arrow_upward,
                color: const Color(0xFF3B82F6),
                backgroundColor: Colors.white,
              ),
              StatCard(
                label: pnl.netProfitLabel,
                value: formatInr(pnl.netProfit),
                icon: Icons.account_balance_wallet_outlined,
                // A loss reads in red rather than the usual gold.
                color: pnl.netProfit < 0 ? AppColors.kDanger : kTallyGold,
                backgroundColor: Colors.white,
              ),
            ],
          );
        }),
        const SizedBox(height: 32),

        _buildFinancialTable(
          title: 'INCOME',
          items: pnl.income,
          totalLabel: 'TOTAL INCOME',
          totalValue: formatInr(pnl.totalIncome),
          totalColor: kTallyGold,
        ),
        const SizedBox(height: 24),

        _buildFinancialTable(
          title: 'EXPENSES',
          items: pnl.expenses,
          totalLabel: 'TOTAL EXPENSES',
          totalValue: formatInr(pnl.totalExpense),
          totalColor: const Color(0xFF3B82F6),
        ),

        // Output GST is a liability, not income — the backend reports it apart
        // from the P&L lines, and so does this strip.
        if (pnl.gstCollected > 0) ...[
          const SizedBox(height: 24),
          _buildFinancialTable(
            title: 'OUTPUT GST (LIABILITY — NOT INCOME)',
            items: [
              TallyReportLine(particulars: 'CGST Collected', amount: pnl.gstCgst),
              TallyReportLine(particulars: 'SGST Collected', amount: pnl.gstSgst),
            ],
            totalLabel: 'TOTAL GST PAYABLE',
            totalValue: formatInr(pnl.gstCollected),
            totalColor: kTallyNavy,
          ),
        ],

        if (pnl.periodStart.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'PERIOD · ${pnl.periodStart} → ${pnl.periodEnd}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: kTallyMuted,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  // --- Balance Sheet ---

  Widget _buildBalanceSheet(TallyBalanceSheet sheet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFinancialTable(
          title: 'ASSETS',
          items: sheet.assets,
          totalLabel: 'TOTAL ASSETS',
          totalValue: formatInr(sheet.totalAssets),
          totalColor: kTallyGold,
        ),
        const SizedBox(height: 24),
        _buildFinancialTable(
          title: 'LIABILITIES & EQUITY',
          items: sheet.liabilities,
          totalLabel: 'TOTAL LIABILITIES & EQUITY',
          totalValue: formatInr(sheet.totalLiabilities),
          totalColor: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 16),
        Text(
          'AS ON ${sheet.asOn}${sheet.balanced ? ' · BALANCED' : ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: kTallyMuted,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // --- Sub-Tab Builder ---
  Widget _buildSubTab(String label, IconData icon) {
    bool isActive = _activeSubTab == label;
    return InkWell(
      onTap: () => _selectTab(label),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? kTallyNavy : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? kTallyNavy : AppColors.kBorder),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: kTallyNavy.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? kTallyAmber : AppColors.kTextMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: isActive ? Colors.white : kTallyNavy,
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
    required List<TallyReportLine> items,
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
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: kTallyNavy,
                letterSpacing: 2,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.kBorder),

          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Text(
                'NO ENTRIES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: kTallyMuted,
                  letterSpacing: 1.5,
                ),
              ),
            )
          else
            ...items.map((item) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.particulars,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: kTallySlate,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            item.amountDisplay,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: kTallyNavy,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.kBorder),
                  ],
                )),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            decoration: const BoxDecoration(
              color: kTallyTint,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    totalLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: kTallyNavy,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
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
