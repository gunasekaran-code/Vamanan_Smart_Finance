import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/auditor_wallet_model.dart';
import '../../services/auditor_wallet_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

/// The disbursement hub — request a withdrawal and see past ones.
///
/// Reached from the WITHDRAW MONEY button on [AuditorWalletScreen], and from
/// the WALLETS > Withdraw History menu entry. Shared by the auditor and
/// customer roles; both read the same `user_id`-scoped endpoints:
///   * `customer/wallet.php`            — balance and locked funds
///   * `admin/withdrawals.php?user_id=` — this user's history only
///   * `customer/request_withdrawal.php` — the submit
class AuditorWalletWithdrawScreen extends StatefulWidget {
  final String userId;

  const AuditorWalletWithdrawScreen({super.key, required this.userId});

  @override
  State<AuditorWalletWithdrawScreen> createState() =>
      _AuditorWalletWithdrawScreenState();
}

class _AuditorWalletWithdrawScreenState
    extends State<AuditorWalletWithdrawScreen> {
  /// The backend has no minimum of its own; this is the product rule the
  /// form advertises under the amount field.
  static const double _minWithdrawal = 100;

  static const Color _navy = Color(0xFF1B233A);
  static const Color _royal = AppColors.kPrimary;
  static const Color _slate = Color(0xFF94A3B8);
  static const Color _label = Color(0xFFCBD5E1);
  static const Color _hairline = Color(0xFFF1F5F9);

  final _amountCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accNumCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  final _currency = NumberFormat('#,##0.##', 'en_IN');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  WalletOverview _overview = WalletOverview.empty();
  List<WithdrawalRecord> _withdrawals = [];
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
    // MAX and the submit button both depend on the typed amount.
    _amountCtrl.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_onAmountChanged);
    _amountCtrl.dispose();
    _bankNameCtrl.dispose();
    _accNumCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  void _onAmountChanged() => setState(() {});

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview =
          await AuditorWalletService.instance.fetchOverview(widget.userId);
      final withdrawals =
          await AuditorWalletService.instance.fetchWithdrawals(widget.userId);
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _withdrawals = withdrawals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _money(double v) => '₹${_currency.format(v)}';

  double get _typedAmount =>
      double.tryParse(_amountCtrl.text.trim().replaceAll(',', '')) ?? 0;

  /// Guard the button rather than letting the server reject the request.
  bool get _canSubmit =>
      !_submitting &&
      _overview.balance >= _minWithdrawal &&
      _typedAmount >= _minWithdrawal &&
      _typedAmount <= _overview.balance &&
      _bankNameCtrl.text.trim().isNotEmpty &&
      _accNumCtrl.text.trim().isNotEmpty &&
      _ifscCtrl.text.trim().isNotEmpty;

  void _backToWallet() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/auditor-wallets');
    }
  }

  Future<void> _submit() async {
    final amount = _typedAmount;

    if (amount < _minWithdrawal) {
      ToastService.show(
        title: 'Amount too low',
        message: 'The minimum withdrawal is ${_money(_minWithdrawal)}.',
        type: ToastType.warning,
      );
      return;
    }
    if (amount > _overview.balance) {
      ToastService.show(
        title: 'Insufficient balance',
        message: 'That exceeds your available ${_money(_overview.balance)}.',
        type: ToastType.warning,
      );
      return;
    }
    if (_bankNameCtrl.text.trim().isEmpty ||
        _accNumCtrl.text.trim().isEmpty ||
        _ifscCtrl.text.trim().isEmpty) {
      ToastService.show(
        title: 'Bank details required',
        message: 'Fill in the bank name, account number and IFSC code.',
        type: ToastType.warning,
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Confirm Withdrawal',
      message: 'Request ${_money(amount)} to ${_bankNameCtrl.text.trim()}? '
          'The amount is locked until the request is processed.',
      confirmLabel: 'Request Withdrawal',
      confirmButtonColor: _navy,
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      await AuditorWalletService.instance.submitWithdrawal(
        userId: widget.userId,
        amount: amount,
        bankName: _bankNameCtrl.text.trim(),
        accountNo: _accNumCtrl.text.trim(),
        ifscCode: _ifscCtrl.text.trim().toUpperCase(),
      );

      if (!mounted) return;
      ToastService.show(
        title: 'Withdrawal requested',
        message: 'Your request has been submitted and is pending review.',
        type: ToastType.success,
      );
      _amountCtrl.clear();
      _bankNameCtrl.clear();
      _accNumCtrl.clear();
      _ifscCtrl.clear();
      setState(() => _submitting = false);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ToastService.show(
        title: 'Could not submit',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // custom header
      children: [
        Center(
          child: Container(
                                    constraints: const BoxConstraints(maxWidth: 800), 
            child: _body(),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 120),
        child: Center(child: AppLoader()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.kDanger, size: 40),
            const SizedBox(height: 16),
            const Text(
              'COULD NOT LOAD WITHDRAWALS',
              style: TextStyle(
                color: _navy,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _slate, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('RETRY')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const SizedBox(height: 20),
        _backButton(),
        const SizedBox(height: 24),
        _requestCard(),
        const SizedBox(height: 24),
        _reservesCard(),
        const SizedBox(height: 24),
        _historyCard(),
        const SizedBox(height: 40),
      ],
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================

  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: AppColors.goldColor, size: 8),
            SizedBox(width: 8),
            Text(
              'DISBURSEMENT HUB',
              style: TextStyle(
                color: _slate,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'WITHDRAWALS',
          style: TextStyle(
            color: _royal,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -1.0,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'WITHDRAW YOUR EARNINGS TO YOUR BANK ACCOUNT',
          style: TextStyle(
            color: _slate,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _backButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: _backToWallet,
        icon: const Icon(Icons.arrow_back_rounded, size: 16),
        label: const Text(
          'BACK TO WALLET',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _navy,
          side: const BorderSide(color: _hairline, width: 2),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // ==========================================================================
  // REQUEST FORM
  // ==========================================================================

  Widget _requestCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _hairline, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Positioned(
                right: 0,
                top: -10,
                child: Icon(
                  Icons.account_balance_rounded,
                  size: 96,
                  color: _hairline.withOpacity(0.9),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _royal,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.credit_card_rounded,
                        color: AppColors.goldColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INITIALIZE DISBURSEMENT',
                          style: TextStyle(
                            color: _royal,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SUBMIT YOUR LIQUIDATION REQUEST FOR PROCESSING',
                          style: TextStyle(
                            color: _slate.withOpacity(0.9),
                            fontSize: 10,
                            height: 1.4,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _fieldLabel('LIQUID QUANTITY (₹)'),
          const SizedBox(height: 10),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: const TextStyle(
              color: _navy,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: const TextStyle(
                color: _label,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 20, right: 12),
                child: Text(
                  '₹',
                  style: TextStyle(
                    color: _label,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              filled: true,
              fillColor: AppColors.kBackground,
              contentPadding: const EdgeInsets.symmetric(vertical: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: _royal, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MIN: ${_money(_minWithdrawal)}',
                style: const TextStyle(
                  color: _slate,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'MAX: ${_money(_overview.balance)}',
                style: const TextStyle(
                  color: AppColors.goldColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _fieldLabel('BANK ACCOUNT'),
          const SizedBox(height: 10),
          // Only one payout rail exists today; it reads as a chosen option
          // rather than pretending there is a choice to make.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.kBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.account_balance_outlined, size: 18, color: _navy),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'EXTERNAL BANK TRANSFER',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(Icons.check_circle_outline_rounded,
                    size: 18, color: AppColors.goldColor),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _textField(
            label: 'BANK NAME',
            controller: _bankNameCtrl,
            hint: 'E.G. STATE BANK OF INDIA',
          ),
          const SizedBox(height: 22),
          _textField(
            label: 'ACCOUNT NUMBER',
            controller: _accNumCtrl,
            hint: '00000000000',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 22),
          _textField(
            label: 'IFSC CODE',
            controller: _ifscCtrl,
            hint: 'SBIN000XXXX',
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 26),
          _securityNotice(),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canSubmit ? _submit : null,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _submitting ? 'SUBMITTING…' : 'SUBMIT WITHDRAWAL REQUEST',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _royal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _royal.withOpacity(0.45),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityNotice() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_outlined, size: 16, color: _royal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SECURITY CHECK ACTIVE',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'WITHDRAWAL REQUESTS ARE USUALLY PROCESSED WITHIN 24-48 '
                  'HOURS. THE REQUESTED AMOUNT WILL BE LOCKED AFTER '
                  'SUBMISSION.',
                  style: TextStyle(
                    color: _royal.withOpacity(0.85),
                    fontSize: 10,
                    height: 1.5,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // RESERVES
  // ==========================================================================

  Widget _reservesCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _royal,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -20,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 120,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LIQUID RESERVES',
                style: TextStyle(
                  color: AppColors.goldColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _money(_overview.balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'AVAILABLE FOR DISBURSEMENT',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'LOCKED FUNDS',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    // Debits still sitting at status='pending' — already
                    // requested, not yet paid out.
                    Text(
                      _money(_overview.pendingPayouts),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // HISTORY
  // ==========================================================================

  Widget _historyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _hairline, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: AppColors.goldColor),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'RECENT DISBURSEMENTS',
                  style: TextStyle(
                    color: _royal,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_withdrawals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'NO DISBURSEMENT HISTORY',
                  style: TextStyle(
                    color: _label,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            )
          else
            for (final record in _withdrawals) _historyRow(record),
        ],
      ),
    );
  }

  Widget _historyRow(WithdrawalRecord record) {
    final (Color color, String label) = switch (record.status.toUpperCase()) {
      'COMPLETED' || 'APPROVED' || 'PAID' => (AppColors.kSuccess, 'PAID'),
      'REJECTED' || 'FAILED' => (AppColors.kDanger, 'REJECTED'),
      _ => (AppColors.kWarning, 'PENDING'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.kBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _money(record.amount),
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.date == null
                        ? record.bank
                        : '${_dateFmt.format(record.date!)} · ${record.bank}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _slate, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SHARED BITS
  // ==========================================================================

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _slate,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          // The submit button enables only once every field is filled.
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            color: _navy,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: _label,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
            filled: true,
            fillColor: AppColors.kBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _royal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
