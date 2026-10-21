import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/stat_card.dart';

import '../../models/referral_reports_model.dart';
import '../../services/referral_reports_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class ReferralReportsScreen extends StatefulWidget {
  const ReferralReportsScreen({super.key});

  @override
  State<ReferralReportsScreen> createState() => _ReferralReportsScreenState();
}

class _ReferralReportsScreenState extends State<ReferralReportsScreen> {
  final TextEditingController _registrySearchController = TextEditingController();
  final ReferralService _service = ReferralService();

  ReferralSummary _summary = ReferralSummary.empty();
  List<EliteReferrer> _eliteReferrers = [];
  List<ReferralHistoryEntry> _history = [];

  bool _loading = true;
  String? _error;
  final Set<int> _toggleInFlight = {};

  final NumberFormat _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _registrySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        _service.fetchReport(),
        _service.fetchHistory(),
      ]);
      if (!mounted) return;
      final bundle = results[0] as ReferralReportBundle;
      final history = results[1] as List<ReferralHistoryEntry>;
      setState(() {
        _summary = bundle.summary;
        _eliteReferrers = bundle.eliteReferrers;
        _history = history;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handleRefreshProtocol() async {
    await _loadAll(silent: true);
    if (!mounted) return;
    if (_error == null) {
      ToastService.show(
        title: 'Protocol Refreshed',
        message: 'Referral intelligence data synced with the backend.',
        type: ToastType.success,
      );
    } else {
      ToastService.show(
        title: 'Refresh Failed',
        message: _error!,
        type: ToastType.error,
      );
    }
  }

  Future<void> _handleExportLedger() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'EXPORT LEDGER',
      message: 'Generate a full data dump of the referral network registry?',
      confirmLabel: 'EXPORT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );

    if (confirmed == true) {
      ToastService.show(
        title: 'Export Initiated',
        message: 'The referral ledger is being prepared for download.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _handleToggleReferral(ReferralHistoryEntry entry) async {
    final willActivate = !entry.referralActive;

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: willActivate ? 'RESUME COMMISSIONS' : 'STOP COMMISSIONS',
      message: willActivate
          ? 'Resume referral commissions for ${entry.userName}?'
          : 'Stop referral commissions for ${entry.userName}? Their own daily cashback is unaffected.',
      confirmLabel: willActivate ? 'RESUME' : 'STOP',
      cancelLabel: 'CANCEL',
      confirmButtonColor: willActivate ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
    );
    if (confirmed != true) return;

    setState(() => _toggleInFlight.add(entry.userId));
    try {
      await _service.setReferralActive(userId: entry.userId, active: willActivate);
      if (!mounted) return;
      ToastService.show(
        title: 'Referral Status Updated',
        message: willActivate
            ? '${entry.userName}\'s referral commissions resumed.'
            : '${entry.userName}\'s referral commissions stopped.',
        type: ToastType.success,
      );
      await _loadAll(silent: true);
    } catch (e) {
      if (!mounted) return;
      ToastService.show(title: 'Action Failed', message: e.toString(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _toggleInFlight.remove(entry.userId));
    }
  }

  List<ReferralHistoryEntry> get _filteredHistory {
    final q = _registrySearchController.text.trim().toLowerCase();
    if (q.isEmpty) return _history;
    return _history
        .where((e) =>
            e.userName.toLowerCase().contains(q) ||
            e.userEmail.toLowerCase().contains(q) ||
            (e.protocolRef ?? '').toLowerCase().contains(q))
        .toList();
  }

  // --- Responsive Helpers ---
  bool get _isMobile => MediaQuery.of(context).size.width < 600;
  bool get _isTablet => MediaQuery.of(context).size.width < 900;
  double get _cardPadding => _isMobile ? 20.0 : 32.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadAll(silent: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(_isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGlobalSearch(),
                SizedBox(height: _isMobile ? 24 : 32),
                _buildHeader(),
                SizedBox(height: _isMobile ? 24 : 32),
                if (_error != null) _buildErrorBanner(),
                _buildFinancialInflectionCard(),
                const SizedBox(height: 24),
                
                // Net Node & Transmissions row/col
                if (_isTablet) ...[
                  _buildNetNodeYieldCard(),
                  const SizedBox(height: 24),
                  _buildTransmissionsCard(),
                ] else ...[
                  Row(children: [
                    Expanded(child: _buildNetNodeYieldCard()),
                    const SizedBox(width: 24),
                    Expanded(child: _buildTransmissionsCard()),
                  ]),
                ],
                
                const SizedBox(height: 24),
                _buildDeductionBreakdownCard(),
                const SizedBox(height: 24),
                _buildEliteReferrersCard(),
                const SizedBox(height: 24),
                _buildProtocolHistoryCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Search / Header ---

  Widget _buildGlobalSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: TextField(
        controller: _registrySearchController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search by name, email, or reference...',
          hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    double titleFontSize = _isMobile ? 32.0 : 40.0;
    
    Widget titleContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 32, height: 2, color: const Color(0xFFD97706)),
            const SizedBox(width: 8),
            const Text('ANALYTICAL COMMAND NODE',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706), letterSpacing: 2)),
            const SizedBox(width: 8),
            Container(width: 32, height: 2, color: const Color(0xFFD97706)),
          ],
        ),
        const SizedBox(height: 8),
        Text('REFERRAL', style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF1E3A8A), height: 0.9, letterSpacing: -1)),
        Text('REPORTS', style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFD97706), height: 0.9, letterSpacing: -1)),
        const SizedBox(height: 12),
        Text('HIGH-FIDELITY FISCAL INTELLIGENCE & ASSET OVERSIGHT',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1.5)),
      ],
    );

    Widget actionContent = Column(
      crossAxisAlignment: _isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: _loading ? null : _handleRefreshProtocol,
          icon: _loading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.sync, size: 16),
          label: const Text('REFRESH PROTOCOL', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFD97706),
            side: const BorderSide(color: Color(0xFFFDE68A)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            elevation: 2,
            shadowColor: const Color(0xFFD97706).withOpacity(0.1),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _loading ? 'SYNCING...' : 'LAST UPDATED: JUST NOW',
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.7), letterSpacing: 1),
        ),
      ],
    );

    if (_isMobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titleContent, const SizedBox(height: 24), actionContent]);
    }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: titleContent), actionContent]);
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFCA5A5))),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_error ?? 'Something went wrong.', style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600))),
          TextButton(onPressed: () => _loadAll(), child: const Text('RETRY', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  // --- Report cards ---

  Widget _buildFinancialInflectionCard() {
    return Container(
      padding: EdgeInsets.all(_cardPadding),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FINANCIAL INFLECTION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 4),
                    Text('MULTIVARIATE YIELD METRICS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star, size: 8, color: Color(0xFFD97706)),
                  SizedBox(width: 6),
                  Text('LIVE', style: TextStyle(color: Color(0xFFD97706), fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: AppColors.kBorder),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildVelocityStat('AGGREGATE YIELD', _currency.format(_summary.aggregateYield), const Color(0xFF1E3A8A)),
              _buildVelocityStat('ACTIVE NODES', '${_summary.activeNodes}', const Color(0xFF1E3A8A)),
              _buildVelocityStat('PROTOCOL STATUS', _loading ? 'SYNCING' : 'OPTIMAL', const Color(0xFFD97706)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: valueColor)),
      ],
    );
  }

  Widget _buildNetNodeYieldCard() {
    return Container(
      padding: EdgeInsets.all(_cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFC29B38),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: const Color(0xFFD97706).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.account_tree_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 24),
          const Text('NET NODE YIELD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('${_summary.activeNodes} Nodes', style: TextStyle(fontSize: _isMobile ? 32 : 40, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white, height: 1)),
          const SizedBox(height: 24),
          Row(children: [
            const Icon(Icons.arrow_right, color: Colors.white, size: 14),
            Expanded(child: Text('INSTITUTIONAL GRADE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.8), letterSpacing: 1.5))),
          ]),
        ],
      ),
    );
  }

  Widget _buildTransmissionsCard() {
    return Container(
      padding: EdgeInsets.all(_cardPadding),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
            child: const Icon(Icons.hub_outlined, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(height: 24),
          const Text('FINANCIAL VELOCITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('${_summary.transmissions} TRANSMISSIONS', style: TextStyle(fontSize: _isMobile ? 20 : 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleExportLedger,
              icon: const Icon(Icons.download, size: 14),
              label: const Text('EXPORT LEDGER', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
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

Widget _buildDeductionBreakdownCard() {
    return Container(
      padding: EdgeInsets.all(_cardPadding),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DEDUCTION BREAKDOWN', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 4),
                    Text('AUTO-COMPUTED TDS + SERVICE CHARGES + NET YIELD',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.trending_down, color: Color(0xFFEF4444), size: 16),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            final double width = constraints.maxWidth;
            
            // Determine number of columns based on available width
            int cols = 3; // Default for tablets
            if (width < 380) {
              cols = 1; // 1 column for very small phones
            } else if (width < 700) {
              cols = 2; // 2 columns for standard phones
            }
            
            const double spacing = 16.0;
            // Subtracting 0.5 prevents sub-pixel rounding errors that cause right-side overflows
            final double itemWidth = ((width - (spacing * (cols - 1))) / cols) - 0.5;

            // Helper to wrap each StatCard with the exact calculated width
            Widget wrapCard(Widget card) => SizedBox(width: itemWidth, child: card);

            // Wrap naturally handles dynamic heights, preventing bottom overflows entirely
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                wrapCard(
                  StatCard(
                    label: 'GROSS PAYOUT',
                    value: _currency.format(_summary.grossPayout),
                    badgeText: 'TOTAL',
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFF1E3A8A),
                    backgroundColor: const Color(0xFFF0F7FF),
                    borderColor: const Color(0xFFBFDBFE),
                    badgeBackgroundColor: const Color(0xFFDBEAFE),
                    badgeTextColor: const Color(0xFF1D4ED8),
                  ),
                ),
                wrapCard(
                  StatCard(
                    label: 'TDS DEDUCTED',
                    value: _currency.format(_summary.tdsDeducted),
                    badgeText: 'TAX',
                    icon: Icons.money_off,
                    color: const Color(0xFFEF4444),
                    backgroundColor: const Color(0xFFFEF2F2),
                    borderColor: const Color(0xFFFECACA),
                    badgeBackgroundColor: const Color(0xFFFEE2E2),
                    badgeTextColor: const Color(0xFFDC2626),
                  ),
                ),
                wrapCard(
                  StatCard(
                    label: 'SERVICE CHARGE',
                    value: _currency.format(_summary.serviceCharge),
                    badgeText: 'CHARGE',
                    icon: Icons.receipt_long,
                    color: const Color(0xFFEF4444),
                    backgroundColor: const Color(0xFFFEF2F2),
                    borderColor: const Color(0xFFFECACA),
                    badgeBackgroundColor: const Color(0xFFFEE2E2),
                    badgeTextColor: const Color(0xFFDC2626),
                  ),
                ),
                wrapCard(
                  StatCard(
                    label: 'NET PAYOUT',
                    value: _currency.format(_summary.netPayout),
                    badgeText: 'CREDITED',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF10B981),
                    backgroundColor: const Color(0xFFECFDF5),
                    borderColor: const Color(0xFFA7F3D0),
                    badgeBackgroundColor: const Color(0xFFD1FAE5),
                    badgeTextColor: const Color(0xFF047857),
                  ),
                ),
                wrapCard(
                  StatCard(
                    label: 'TOTAL DEDUCTIONS',
                    value: _currency.format(_summary.totalDeductions),
                    badgeText: 'DEDUCTIONS',
                    icon: Icons.trending_down,
                    color: const Color(0xFFD97706),
                    backgroundColor: AppColors.goldBg,
                    borderColor: AppColors.goldBorder,
                    badgeBackgroundColor: AppColors.goldBadgeBg,
                    badgeTextColor: AppColors.goldColor,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEliteReferrersCard() {
    return Container(
      padding: EdgeInsets.all(_cardPadding),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ELITE REFERRERS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.workspace_premium_outlined, color: Color(0xFF3B82F6), size: 16),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_eliteReferrers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: const Text(
                'NO ELITE REFERRERS DETECTED IN THIS CYCLE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1), letterSpacing: 2),
                textAlign: TextAlign.center,
              ),
            )
          else
            Column(
              children: _eliteReferrers.map((r) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 12)),
                            Text('${r.referralCount} referrals', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                          ],
                        ),
                      ),
                      Text(_currency.format(r.totalEarned), style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- History table ---

  Widget _buildProtocolHistoryCard() {
    final rows = _filteredHistory;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(_cardPadding),
            child: LayoutBuilder(builder: (context, constraints) {
              Widget titleArea = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.history_edu, color: Color(0xFF3B82F6), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PROTOCOL\nHISTORY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), height: 1.1)),
                        const SizedBox(height: 4),
                        Text('IMMUTABLE TRANSACTION REGISTRY',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              );

              Widget searchArea = SizedBox(
                height: 40,
                child: TextField(
                  controller: _registrySearchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'SEARCH REGISTRY...',
                    hintStyle: const TextStyle(color: AppColors.kTextMuted, fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900),
                    prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.kTextMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.kBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
              );

              if (_isMobile) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titleArea, const SizedBox(height: 24), searchArea]);
              }
              return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(flex: 3, child: titleArea),
                const SizedBox(width: 32),
                Expanded(flex: 2, child: searchArea),
              ]);
            }),
          ),
          const Divider(height: 1, color: AppColors.kBorder),
          if (_loading)
            const Padding(padding: EdgeInsets.all(48), child: Center(child: AppLoader()))
          else if (rows.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              alignment: Alignment.center,
              child: const Text(
                'NO REGISTRY ENTRIES FOUND',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1), letterSpacing: 2),
                textAlign: TextAlign.center,
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 32,
                headingRowHeight: 56,
                dataRowMinHeight: 72,
                dataRowMaxHeight: 72,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                dividerThickness: 0,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 9, letterSpacing: 1.5),
                columns: const [
                  DataColumn(label: Text('ENTITY NODE')),
                  DataColumn(label: Text('PROTOCOL REF')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('QUANTUM (₹)')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: rows.map((entry) {
                  final busy = _toggleInFlight.contains(entry.userId);
                  return DataRow(cells: [
                    DataCell(Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(entry.initial, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.userName, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 12)),
                            Text(entry.userEmail, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                          ],
                        ),
                      ],
                    )),
                    DataCell(Text(entry.protocolRef ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Color(0xFF64748B), fontSize: 12))),
                    DataCell(_buildStatusBadge(entry.status)),
                    DataCell(Text(_currency.format(entry.amount), style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13))),
                    DataCell(
                      busy
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : _actionButton(
                              label: entry.referralActive ? 'STOP' : 'RESUME',
                              color: entry.referralActive ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              onTap: () => _handleToggleReferral(entry),
                            ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'active':
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF16A34A);
        break;
      case 'failed':
      case 'rejected':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
    );
  }

  Widget _actionButton({required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
      ),
    );
  }
}