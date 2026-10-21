import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/wallet_account_model.dart';
import '../../services/wallet_account_service.dart';

/// Capital Correction Protocol — manual credit / debit on one investor wallet,
/// with the investor's live cashback plan alongside it.
///
/// The plan block (monthly installment gross / TDS / charges / net, months
/// paid, remaining cap) comes from `admin/get_user_daily_payout.php` and is
/// re-read whenever the target customer changes or a payout lands. When the
/// amount is a whole number of monthly installments, PAY OUT posts each month
/// to `admin/adjust_wallet.php` as a `cashback` credit with its gross / TDS /
/// charges breakdown, so the ledger and the cycle's months-paid counter move
/// exactly like an engine payout. Any other amount is a plain manual
/// adjustment.
class WalletAdjustmentScreen extends StatefulWidget {
  /// Optional target pre-selection, supplied when this screen is opened for one
  /// investor from the wallet list. When omitted the screen still works
  /// standalone (as a router destination) and defaults to the first wallet.
  final String? userId;
  final String? userName;
  final double? currentBalance;

  const WalletAdjustmentScreen({
    super.key,
    this.userId,
    this.userName,
    this.currentBalance,
  });

  @override
  State<WalletAdjustmentScreen> createState() => _WalletAdjustmentScreenState();
}

class _WalletAdjustmentScreenState extends State<WalletAdjustmentScreen> {
  static const String _creditLabel = 'INJECT CAPITAL (CREDIT +)';
  static const String _debitLabel = 'DEDUCT CAPITAL (DEBIT -)';
  static const List<String> _directions = [_creditLabel, _debitLabel];
  static const String _cashbackRationale =
      'Monthly Cashback Payout (net of TDS + charges)';

  // Palette
  static const Color _navy = Color(0xFF1E3A8A);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _gold = Color(0xFFB8901F);
  static const Color _cream = Color(0xFFFBF8EF);
  static const Color _creamBorder = Color(0xFFF3E6BF);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _red = Color(0xFFEF4444);
  static const Color _surface = Color(0xFFF8FAFC);

  final WalletService _service = WalletService();
  final TextEditingController _amountController =
      TextEditingController(text: '0.00');
  final TextEditingController _rationaleController = TextEditingController();

  // Form State
  List<WalletAccount> _wallets = [];
  String? _selectedUserId;
  String _selectedDirection = _creditLabel;
  int _months = 1;

  WalletPayoutPlan? _plan;
  bool _planLoading = false;
  String? _planError;
  int _planRequest = 0;

  bool _loading = true;
  String? _loadError;
  bool _submitting = false;
  bool _processingYield = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _loadWallets();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rationaleController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // DATA
  // --------------------------------------------------------------------------

  WalletAccount? get _selected {
    for (final w in _wallets) {
      if (w.userId == _selectedUserId) return w;
    }
    return null;
  }

  bool get _isCredit => _selectedDirection == _creditLabel;

  double? get _amount =>
      double.tryParse(_amountController.text.trim().replaceAll(',', ''));

  /// The number of whole monthly installments the entered amount equals, or
  /// null when it's a plain manual adjustment.
  int? get _cashbackMonths {
    final plan = _plan;
    final amount = _amount;
    if (!_isCredit || plan == null || !plan.hasActivePlan) return null;
    if (amount == null || amount <= 0) return null;
    final k = (amount / plan.monthlyNet).round();
    if (k < 1 || k > plan.maxPayableMonths) return null;
    return (amount - k * plan.monthlyNet).abs() <= 0.01 * k ? k : null;
  }

  List<WalletAccount> _fallbackWallets() {
    final id = widget.userId?.trim() ?? '';
    if (id.isEmpty) return const [];
    return [
      WalletAccount(
        walletId: '',
        userId: id,
        balance: widget.currentBalance ?? 0,
        totalEarned: 0,
        totalWithdrawn: 0,
        userName: widget.userName ?? 'Selected investor',
      ),
    ];
  }

  String? _resolveSelection(List<WalletAccount> wallets) {
    if (wallets.isEmpty) return null;
    if (_selectedUserId != null) {
      for (final w in wallets) {
        if (w.userId == _selectedUserId) return w.userId;
      }
    }
    final wanted = widget.userId?.trim();
    if (wanted != null && wanted.isNotEmpty) {
      for (final w in wallets) {
        if (w.userId == wanted) return w.userId;
      }
    }
    return wallets.first.userId;
  }

  Future<void> _loadWallets({bool prefill = true}) async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final wallets = await _service.fetchWallets();
      if (!mounted) return;
      setState(() {
        _wallets = wallets;
        _selectedUserId = _resolveSelection(wallets);
        _loading = false;
      });
    } on WalletServiceException catch (e) {
      if (!mounted) return;
      final fallback = _fallbackWallets();
      setState(() {
        _wallets = fallback;
        _selectedUserId = _resolveSelection(fallback);
        _loadError = e.message;
        _loading = false;
      });
    }
    await _loadPlan(prefill: prefill);
  }

  /// Reads the selected investor's plan. A request counter drops responses
  /// for a customer the admin has already switched away from.
  Future<void> _loadPlan({bool prefill = true}) async {
    final userId = _selectedUserId;
    if (userId == null) return;
    final request = ++_planRequest;
    setState(() {
      _planLoading = true;
      _planError = null;
    });
    try {
      final plan = await _service.fetchPayoutPlan(userId);
      if (!mounted || request != _planRequest) return;
      setState(() {
        _plan = plan;
        _planLoading = false;
        _months = _months
            .clamp(1, plan.maxPayableMonths < 1 ? 1 : plan.maxPayableMonths)
            .toInt();
      });
      // Start from one month's net payout — but never overwrite an amount the
      // admin has already typed (e.g. on pull-to-refresh).
      if (prefill && (_amount ?? 0) <= 0) _prefillMonths(1);
    } on WalletServiceException catch (e) {
      if (!mounted || request != _planRequest) return;
      setState(() {
        _plan = null;
        _planLoading = false;
        _planError = e.message;
      });
    }
  }

  void _onSelectCustomer(String? userId) {
    if (userId == null || userId == _selectedUserId) return;
    setState(() {
      _selectedUserId = userId;
      _plan = null;
      _months = 1;
    });
    _amountController.text = '0.00';
    _rationaleController.clear();
    _loadPlan();
  }

  void _onAmountChanged() {
    if (!mounted) return;
    final months = _cashbackMonths;
    setState(() {
      if (months != null) _months = months;
    });
  }

  /// Fills the form with [months] whole installments of the net payout.
  void _prefillMonths(int months) {
    final plan = _plan;
    if (plan == null || plan.maxPayableMonths < 1) return;
    final m = months.clamp(1, plan.maxPayableMonths).toInt();
    setState(() {
      _selectedDirection = _creditLabel;
      _months = m;
    });
    _amountController.text = (plan.monthlyNet * m).toStringAsFixed(2);
    if (_rationaleController.text.trim().isEmpty ||
        _rationaleController.text.trim() == _cashbackRationale) {
      _rationaleController.text = _cashbackRationale;
    }
  }

  void _stepAmount(int direction) {
    final plan = _plan;
    final current = _amount ?? 0;
    final step = (_isCredit && plan != null && plan.hasActivePlan)
        ? plan.monthlyNet
        : 100.0;
    final next = (current + step * direction).clamp(0, double.infinity);
    _amountController.text = next.toStringAsFixed(2);
  }

  // --------------------------------------------------------------------------
  // ACTIONS
  // --------------------------------------------------------------------------

  Future<void> _handleProcessYield() async {
    if (_processingYield) return;

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'PROCESS MONTHLY YIELD',
      message:
          "Process this month's cashback? This credits one monthly installment (10%) to every cycle that is due, and can only run ONCE per calendar month.",
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: _navy,
    );
    if (confirmed != true) return;

    setState(() => _processingYield = true);
    try {
      final message = await _service.processMonthlyYield();
      if (!mounted) return;
      ToastService.show(
          title: 'Success', message: message, type: ToastType.success);
      await _loadWallets();
    } on WalletServiceException catch (e) {
      if (!mounted) return;
      ToastService.show(
          title: 'Yield Run Failed', message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _processingYield = false);
    }
  }

  Future<void> _handlePayout() async {
    if (_submitting) return;

    final wallet = _selected;
    if (wallet == null) {
      ToastService.show(
          title: 'Validation Error',
          message: 'Select a target customer first.',
          type: ToastType.error);
      return;
    }

    final amount = _amount;
    if (amount == null || amount <= 0) {
      ToastService.show(
          title: 'Validation Error',
          message: 'Enter an injection quantity greater than zero.',
          type: ToastType.error);
      return;
    }

    final reason = _rationaleController.text.trim();
    if (reason.isEmpty) {
      ToastService.show(
          title: 'Validation Error',
          message: 'Please specify an authorization rationale.',
          type: ToastType.error);
      return;
    }

    final plan = _plan;
    final months = _cashbackMonths;
    final balance = plan?.walletBalance ?? wallet.balance;
    final projected = _isCredit ? balance + amount : balance - amount;

    final String message;
    if (months != null) {
      message = 'Pay $months monthly cashback installment${months == 1 ? '' : 's'} '
          'to ${wallet.userName}?\n\n'
          'Gross ${_inr(plan!.monthlyGross * months)} − TDS ${_inr(plan.monthlyTds * months)} '
          '− Charges ${_inr(plan.monthlyCharges * months)} = Net ${_inr(amount)}.\n\n'
          'Wallet balance moves from ${_inr(balance)} to ${_inr(projected)}.';
    } else {
      message = '${_isCredit ? 'Credit' : 'Debit'} ${_inr(amount)} '
          '${_isCredit ? 'to' : 'from'} ${wallet.userName}?\n\n'
          'Wallet balance moves from ${_inr(balance)} to ${_inr(projected)}.'
          '${projected < 0 ? '\n\nWARNING: this leaves the wallet with a negative balance.' : ''}';
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: months != null
          ? 'CONFIRM CASHBACK PAYOUT'
          : (_isCredit
              ? 'CONFIRM CAPITAL INJECTION'
              : 'CONFIRM CAPITAL DEDUCTION'),
      message: message,
      confirmLabel: 'CONFIRM',
      cancelLabel: 'CANCEL',
      confirmButtonColor: _navy,
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    var paid = 0;
    try {
      String serverMessage;
      if (months != null) {
        // One request per installment, so the cycle's months-paid counter
        // advances by exactly one each time (as the yield engine does).
        serverMessage = '';
        for (var i = 0; i < months; i++) {
          final month = plan!.monthsCompleted + i + 1;
          serverMessage = await _service.adjustWallet(
            userId: wallet.userId,
            amount: plan.monthlyNet,
            type: 'credit',
            category: 'cashback',
            reason: '$reason · month $month of ${plan.planMonths}',
            grossAmount: plan.monthlyGross,
            tdsAmount: plan.monthlyTds,
            chargesAmount: plan.monthlyCharges,
            deduction: plan.monthlyTds + plan.monthlyCharges,
          );
          paid++;
        }
        serverMessage = '$paid month${paid == 1 ? '' : 's'} paid · '
            '${_inr(plan!.monthlyNet * paid)} credited.';
      } else {
        serverMessage = await _service.adjustWallet(
          userId: wallet.userId,
          amount: amount,
          type: _isCredit ? 'credit' : 'debit',
          reason: reason,
        );
      }
      if (!mounted) return;

      ToastService.show(
          title: 'Protocol Executed',
          message: serverMessage,
          type: ToastType.success);
      _amountController.text = '0.00';
      _rationaleController.clear();

      await _loadWallets(prefill: false);
      if (!mounted) return;
      setState(() => _submitting = false);
      if (Navigator.canPop(context)) Navigator.pop(context, true);
    } on WalletServiceException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ToastService.show(
        title: 'Adjustment Failed',
        message: paid > 0
            ? '$paid of $months months were paid before this error: ${e.message}'
            : e.message,
        type: ToastType.error,
      );
      if (paid > 0) _loadWallets(prefill: false);
    }
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 600;
          return RefreshIndicator(
            onRefresh: _loadWallets,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _yieldButton(isMobile),
                      const SizedBox(height: 16),
                      _mainCard(isMobile),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _yieldButton(bool isMobile) {
    return Align(
      alignment: isMobile ? Alignment.center : Alignment.centerRight,
      child: SizedBox(
        width: isMobile ? double.infinity : null,
        child: ElevatedButton.icon(
          onPressed: _processingYield ? null : _handleProcessYield,
          icon: _processingYield
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.bolt, size: 16),
          label: Text(
            _processingYield ? 'PROCESSING...' : 'PROCESS MONTHLY YIELD',
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: 12,
                letterSpacing: 0.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _mainCard(bool isMobile) {
    final selected = _selected;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(isMobile),
          const SizedBox(height: 26),
          if (_loadError != null) ...[
            _errorBanner(_loadError!, _loadWallets),
            const SizedBox(height: 20),
          ],
          if (isMobile) ...[
            _buildCustomerDropdown(),
            const SizedBox(height: 16),
            _directionDropdown(),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCustomerDropdown()),
                const SizedBox(width: 20),
                Expanded(child: _directionDropdown()),
              ],
            ),
          const SizedBox(height: 24),
          if (_planError != null) ...[
            _errorBanner(_planError!, _loadPlan),
            const SizedBox(height: 16),
          ],
          _planStats(selected, isMobile),
          const SizedBox(height: 24),
          if (_isCredit && (_plan?.hasActivePlan ?? false)) ...[
            _nextPayoutCard(isMobile),
            const SizedBox(height: 28),
          ] else if (_plan != null && !_plan!.hasActivePlan) ...[
            _noPlanNote(),
            const SizedBox(height: 24),
          ],
          _amountField(),
          if (_isCredit && (_plan?.hasActivePlan ?? false)) ...[
            const SizedBox(height: 12),
            Text(
              'CASHBACK IS PAID IN WHOLE MONTHS: ${_inr(_plan!.monthlyNet)} NET PER MONTH — '
              'E.G. ${_inr(_plan!.monthlyNet * 3)} = 3 MONTHS. MAX ${_inr(_plan!.remaining)}.',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: _gold,
                  letterSpacing: 0.8,
                  height: 1.5),
            ),
          ],
          const SizedBox(height: 24),
          _rationaleField(),
          const SizedBox(height: 28),
          _finalAmountCard(isMobile),
          const SizedBox(height: 24),
          _payOutButton(selected),
        ],
      ),
    );
  }

  Widget _header(bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: isMobile ? 48 : 60,
          height: isMobile ? 48 : 60,
          decoration: BoxDecoration(
            color: _navy,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(Icons.credit_card_rounded,
              color: const Color(0xFFFBBF24), size: isMobile ? 22 : 26),
        ),
        SizedBox(width: isMobile ? 14 : 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CAPITAL CORRECTION PROTOCOL',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: _navy,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'MANUAL INTERVENTION LAYER FOR INVESTOR WALLET ADJUSTMENT',
                style: TextStyle(
                  fontSize: isMobile ? 9 : 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: _muted,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String message, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFB91C1C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB91C1C)),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
            child: const Text('RETRY',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFB91C1C))),
          ),
        ],
      ),
    );
  }

  // --- Plan stats -----------------------------------------------------------

  Widget _planStats(WalletAccount? selected, bool isMobile) {
    final plan = _plan;
    String money(double? v) =>
        _planLoading && plan == null ? '…' : (v == null ? '—' : _inr(v));

    final monthsLabel = plan == null
        ? (_planLoading ? '…' : '—')
        : '${plan.monthsCompleted}';

    return Column(
      children: [
        _statStrip(
          isMobile: isMobile,
          background: _cream,
          border: _creamBorder,
          items: [
            _StatData(
              'MONTHLY PAYOUT',
              money(plan?.monthlyGross),
              labelColor: _gold,
              valueColor: _navy,
              sub: plan == null
                  ? null
                  : '● GROSS · ${_pct(plan.monthlyRatePct)}% MONTHLY INSTALLMENT',
              subColor: _gold,
            ),
            _StatData(
              'REMAINING (NET)',
              money(plan?.remaining),
              labelColor: _blue,
              valueColor: _blue,
              sub: plan == null
                  ? null
                  : '${_pct(plan.cashbackPct)}% OF ${_inr(plan.totalEligible)} LIMIT',
            ),
            _StatData(
              'TOTAL INVESTED',
              money(plan?.totalInvested),
              valueColor: _navy,
              sub: plan == null || plan.assetLabel.isEmpty
                  ? null
                  : plan.assetLabel,
              subColor: _gold,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _statStrip(
          isMobile: isMobile,
          background: _surface,
          border: AppColors.kBorder,
          items: [
            _StatData(
              'WALLET BALANCE',
              money(plan?.walletBalance ?? selected?.balance),
              labelColor: _gold,
              valueColor: _gold,
            ),
            _StatData(
              'TOTAL EARNED (NET)',
              money(plan?.totalEarned ?? selected?.totalEarned),
              valueColor: _navy,
            ),
            _StatData(
              'MONTHS PROGRESS',
              monthsLabel,
              labelColor: _blue,
              valueColor: _navy,
              suffix: plan == null ? null : '/${plan.planMonths}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _statStrip({
    required bool isMobile,
    required Color background,
    required Color border,
    required List<_StatData> items,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 6 : 16, vertical: isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(isMobile ? 26 : 32),
        border: Border.all(color: border, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: border.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                    width: 1, thickness: 1, color: border, indent: 4, endIndent: 4),
              Expanded(child: _statColumn(items[i], isMobile)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statColumn(_StatData d, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            d.label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: isMobile ? 7.5 : 9,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: d.labelColor ?? _muted,
                letterSpacing: 1.6),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: d.value),
                if (d.suffix != null)
                  TextSpan(
                      text: d.suffix,
                      style: const TextStyle(color: Color(0xFFCBD5E1))),
              ]),
              style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.6,
                  color: d.valueColor ?? _navy),
            ),
          ),
          if (d.sub != null) ...[
            const SizedBox(height: 6),
            Text(
              d.sub!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: isMobile ? 6.5 : 8,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: d.subColor ?? _muted,
                  letterSpacing: 0.4),
            ),
          ],
        ],
      ),
    );
  }

  // --- Next payout ----------------------------------------------------------

  Widget _nextPayoutCard(bool isMobile) {
    final plan = _plan!;
    final maxMonths = plan.maxPayableMonths;
    final nextMonth = (plan.monthsCompleted + 1).clamp(1, plan.planMonths);
    final stacked = isMobile;

    const spaced = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: _gold,
        letterSpacing: 3.5,
        height: 1.6);

    final details = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 68,
          decoration: BoxDecoration(
            color: _gold,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.bolt_outlined, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEXT MONTHLY PAYOUT (GROSS) · MONTH $nextMonth OF ${plan.planMonths}',
                style: spaced,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(_inr(plan.monthlyGross),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.8,
                        color: _navy)),
              ),
              const SizedBox(height: 4),
              Text(
                'ACROSS ${plan.activeCycles} ACTIVE CYCLE${plan.activeCycles == 1 ? '' : 'S'} · '
                '${plan.monthsLeft} PAYOUT${plan.monthsLeft == 1 ? '' : 'S'} LEFT',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: _muted,
                    height: 1.4),
              ),
              const SizedBox(height: 8),
              _breakLine('– TDS ${_inr(plan.monthlyTds)}', _red),
              _breakLine('– CHARGES ${_inr(plan.monthlyCharges)}', _red),
              _breakLine('= NET ${_inr(plan.monthlyNet)}', _gold),
            ],
          ),
        ),
      ],
    );

    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _creamBorder),
          ),
          child: Row(
            children: [
              const Text('MONTHS',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: _muted,
                      letterSpacing: 1)),
              const SizedBox(width: 10),
              _stepButton(Icons.remove, _months > 1,
                  () => setState(() => _months--)),
              SizedBox(
                width: 36,
                child: Text('$_months',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: _navy)),
              ),
              _stepButton(Icons.add, _months < maxMonths,
                  () => setState(() => _months++)),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text('= ${_inr(plan.monthlyNet * _months)} net',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: _gold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: maxMonths < 1 || _submitting
              ? null
              : () => _prefillMonths(_months),
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: Text(
            maxMonths < 1
                ? 'PLAN CAP REACHED'
                : 'PAY $_months MONTH${_months == 1 ? '' : 'S'} (NET)',
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: 13,
                letterSpacing: 3),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _gold.withValues(alpha: 0.4),
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            elevation: 6,
            shadowColor: _gold.withValues(alpha: 0.4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(isMobile ? 26 : 32),
        border: Border.all(color: _creamBorder, width: 1.4),
      ),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, const SizedBox(height: 22), controls],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 11, child: details),
                const SizedBox(width: 24),
                Expanded(flex: 9, child: controls),
              ],
            ),
    );
  }

  Widget _breakLine(String text, Color color) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.6,
                color: color)),
      );

  Widget _stepButton(IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: enabled ? const Color(0xFFCBD5E1) : AppColors.kBorder),
        ),
        child: Icon(icon,
            size: 16, color: enabled ? _navy : const Color(0xFFCBD5E1)),
      ),
    );
  }

  Widget _noPlanNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: _muted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'NO ACTIVE CASHBACK CYCLE — ONLY MANUAL ADJUSTMENTS ARE AVAILABLE.',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: _muted,
                  letterSpacing: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // --- Inputs ---------------------------------------------------------------

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: _muted,
                letterSpacing: 1.6)),
      );

  InputDecoration _boxDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.kTextMuted,
            fontWeight: FontWeight.normal,
            fontSize: 13),
        fillColor: _surface,
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: AppColors.kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: AppColors.kBorder, width: 1.4)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: _navy, width: 1.4)),
      );

  Widget _amountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(_isCredit ? 'INJECTION QUANTITY (₹)' : 'DEDUCTION QUANTITY (₹)'),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _navy,
              letterSpacing: -0.6),
          decoration: _boxDecoration().copyWith(
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 24, right: 12),
              child: Text('₹',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFCBD5E1))),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _stepAmount(1),
                      child: const Icon(Icons.keyboard_arrow_up,
                          size: 18, color: Color(0xFF334155)),
                    ),
                    InkWell(
                      onTap: () => _stepAmount(-1),
                      child: const Icon(Icons.keyboard_arrow_down,
                          size: 18, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
            ),
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
      ],
    );
  }

  Widget _rationaleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('AUTHORIZATION RATIONALE'),
        TextFormField(
          controller: _rationaleController,
          maxLines: 3,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          decoration: _boxDecoration(
              hint: 'Specify the precise reason for this manual intervention...'),
        ),
      ],
    );
  }

  // --- Final amount ---------------------------------------------------------

  Widget _finalAmountCard(bool isMobile) {
    final amount = _amount ?? 0;
    final months = _cashbackMonths;
    final plan = _plan;
    final credit = _isCredit;

    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          credit
              ? 'FINAL AMOUNT CREDITED TO CUSTOMER'
              : 'FINAL AMOUNT DEBITED FROM CUSTOMER',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: credit ? _gold : _red,
              letterSpacing: 3.2,
              height: 1.5),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('${credit ? '+' : '−'}${_inr(amount)}',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -1,
                  color: credit ? _navy : _red)),
        ),
        const SizedBox(height: 6),
        Text(
          months != null
              ? 'THIS IS THE EXACT AMOUNT THAT REACHES THE WALLET · $months MONTH${months == 1 ? '' : 'S'} OF CASHBACK'
              : 'THIS IS THE EXACT AMOUNT THAT ${credit ? 'REACHES' : 'LEAVES'} THE WALLET · MANUAL ADJUSTMENT',
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: _muted,
              letterSpacing: 1.4,
              height: 1.5),
        ),
      ],
    );

    Widget? breakdown;
    if (months != null && plan != null) {
      breakdown = Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _creamBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _breakdownRow('GROSS', _inr(plan.monthlyGross * months), _muted,
                _navy),
            _breakdownRow(
                'TDS', '− ${_inr(plan.monthlyTds * months)}', _red, _red),
            _breakdownRow('CHARGES', '− ${_inr(plan.monthlyCharges * months)}',
                _red, _red),
            const Divider(height: 18, color: AppColors.kBorder),
            _breakdownRow('NET', _inr(amount), _gold, _gold),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: credit ? _cream : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(isMobile ? 26 : 32),
        border: Border.all(
            color: credit ? _creamBorder : const Color(0xFFFECACA),
            width: 1.4),
      ),
      child: breakdown == null
          ? summary
          : isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [summary, const SizedBox(height: 18), breakdown],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: summary),
                    const SizedBox(width: 24),
                    SizedBox(width: 260, child: breakdown),
                  ],
                ),
    );
  }

  Widget _breakdownRow(
          String label, String value, Color labelColor, Color valueColor) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.6,
                    color: labelColor)),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1,
                        color: valueColor)),
              ),
            ),
          ],
        ),
      );

  Widget _payOutButton(WalletAccount? selected) {
    final months = _cashbackMonths;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_submitting || selected == null) ? null : _handlePayout,
        icon: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.check_circle_outline, size: 18),
        label: Text(
          _submitting
              ? 'PROCESSING...'
              : (months != null || _isCredit ? 'PAY OUT' : 'DEDUCT'),
          style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              fontSize: 14,
              letterSpacing: 4),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCredit ? _navy : const Color(0xFFB91C1C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 22),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          elevation: 8,
          shadowColor: _navy.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DROPDOWNS
  // --------------------------------------------------------------------------

  String _customerLabel(WalletAccount w) {
    final email = (w.userEmail ?? '').trim();
    final name =
        w.userName.trim().isEmpty ? 'UNNAMED' : w.userName.toUpperCase();
    return email.isEmpty ? name : '$name [${email.toUpperCase()}]';
  }

  InputDecoration get _dropdownDecoration => InputDecoration(
        fillColor: Colors.white,
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.kBorder, width: 1.4)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _navy, width: 1.4)),
      );

  static const TextStyle _dropdownText = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: Color(0xFF0F172A));

  Widget _buildCustomerDropdown() {
    Widget field;
    if (_loading && _wallets.isEmpty) {
      field = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.kBorder, width: 1.4),
        ),
        child: const Row(
          children: [
            SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: _navy)),
            SizedBox(width: 10),
            Text('LOADING WALLETS...',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kTextMuted)),
          ],
        ),
      );
    } else if (_wallets.isEmpty) {
      field = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.kBorder, width: 1.4),
        ),
        child: const Text('NO INVESTOR WALLETS AVAILABLE',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.kTextMuted)),
      );
    } else {
      field = DropdownButtonFormField<String>(
        // Keyed so a programmatic selection change re-seeds the field.
        key: ValueKey(_selectedUserId),
        initialValue: _selectedUserId,
        onChanged: _submitting ? null : _onSelectCustomer,
        icon: const Icon(Icons.unfold_more, color: Color(0xFF0F172A), size: 18),
        isExpanded: true,
        style: _dropdownText,
        decoration: _dropdownDecoration,
        items: _wallets
            .map((w) => DropdownMenuItem(
                  value: w.userId,
                  child: Text(_customerLabel(w),
                      overflow: TextOverflow.ellipsis),
                ))
            .toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_label('TARGET CUSTOMER'), field],
    );
  }

  Widget _directionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('CORRECTION DIRECTION'),
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedDirection),
          initialValue: _selectedDirection,
          onChanged: _submitting
              ? null
              : (val) => setState(() => _selectedDirection = val ?? _creditLabel),
          icon: const Icon(Icons.unfold_more, color: Color(0xFF0F172A), size: 18),
          isExpanded: true,
          style: _dropdownText,
          decoration: _dropdownDecoration,
          items: _directions
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // FORMATTING
  // --------------------------------------------------------------------------

  /// ₹ with Indian digit grouping; paise only when there are any.
  static String _inr(double value) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: (value * 100).round() % 100 == 0 ? 0 : 2,
      ).format(value);

  static String _pct(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _StatData {
  final String label;
  final String value;
  final String? suffix;
  final String? sub;
  final Color? labelColor;
  final Color? valueColor;
  final Color? subColor;

  const _StatData(
    this.label,
    this.value, {
    this.suffix,
    this.sub,
    this.labelColor,
    this.valueColor,
    this.subColor,
  });
}
