import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/wallet_account_model.dart';
import 'package:frontend/services/wallet_account_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

/// One investor's transaction ledger.
///
/// Rows and totals: `auditor/ledger.php?user_id=N`. Wallet balance:
/// `admin/get_user_daily_payout.php` (a cheap single-user read). Both are
/// re-polled every [_refreshInterval] while the page is open.
class WalletPurchaseHistoryScreen extends StatefulWidget {
  final WalletAccount wallet;
  const WalletPurchaseHistoryScreen({super.key, required this.wallet});
  @override
  State<WalletPurchaseHistoryScreen> createState() =>
      _WalletPurchaseHistoryScreenState();
}

class _WalletPurchaseHistoryScreenState
    extends State<WalletPurchaseHistoryScreen> {
  static const Duration _refreshInterval = Duration(seconds: 15);

  static const Color _navy = Color(0xFF243D8F);
  static const Color _gold = Color(0xFFF7C948);
  static const Color _goldText = Color(0xFFB98D13);
  static const Color _green = Color(0xFF3F8F65);
  static const Color _red = Color(0xFFDC2626);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _border = Color(0xFFE8EEF6);

  /// Filter chips — label → categories it covers (null = everything).
  static const Map<String, List<String>?> _baseFilters = {
    'ALL': null,
    'CASHBACK': ['cashback'],
    'REFERRAL': ['referral'],
    'PURCHASE REQUEST': ['purchase_request', 'purchase'],
  };

  final _service = WalletService();
  WalletLedger? _ledger;
  double? _balance;
  String _filter = 'ALL';
  String? _error;
  bool _refreshing = false;
  DateTime? _updatedAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(_refreshInterval, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      if (!silent) _error = null;
    });
    final userId = widget.wallet.userId;
    final balanceFuture = _service
        .fetchPayoutPlan(userId)
        .then<double?>((p) => p.walletBalance, onError: (Object _) => null);
    try {
      final data = await _service.fetchLedger(userId);
      final balance = await balanceFuture;
      if (!mounted) return;
      setState(() {
        _ledger = data;
        if (balance != null) _balance = balance;
        _error = null;
        _updatedAt = DateTime.now();
      });
    } catch (e) {
      // A failed background poll keeps the rows already on screen.
      if (mounted && (!silent || _ledger == null)) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// Base chips plus one for any other category present (e.g. WITHDRAWAL).
  Map<String, List<String>?> _filters(WalletLedger l) {
    final known = _baseFilters.values.whereType<List<String>>().expand((c) => c);
    final extra = {
      for (final e in l.entries)
        if (!known.contains(e.category.toLowerCase()) && e.category.isNotEmpty)
          e.category.toLowerCase(),
    };
    return {
      ..._baseFilters,
      for (final c in extra) c.replaceAll('_', ' ').toUpperCase(): [c],
    };
  }

  @override
  Widget build(BuildContext context) {
    final ledger = _ledger;
    final filters = ledger == null ? _baseFilters : _filters(ledger);
    final cats = filters[_filter];
    final rows = ledger?.entries
            .where((e) => cats == null || cats.contains(e.category.toLowerCase()))
            .toList() ??
        const <WalletLedgerEntry>[];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        _hero(ledger),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: ledger == null
                        ? Padding(
                            padding: const EdgeInsets.all(60),
                            child: _error == null
                                ? const Center(child: AppLoader())
                                : Center(
                                    child: Column(children: [
                                    Text(_error!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: _red)),
                                    const SizedBox(height: 12),
                                    OutlinedButton(
                                        onPressed: _load,
                                        child: const Text('RETRY')),
                                  ])),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _summary(ledger),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final label in filters.keys)
                                    _chip(
                                        label == 'ALL'
                                            ? 'ALL (${ledger.entries.length})'
                                            : label,
                                        label),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (rows.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 48),
                                  child: Center(
                                    child: Text('NO TRANSACTIONS IN THIS VIEW',
                                        style: TextStyle(
                                            color: _muted,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                            fontSize: 12)),
                                  ),
                                )
                              else
                                ...rows.map(_row),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _footer(),
      ]),
    );
  }

  Widget _hero(WalletLedger? ledger) {
    final id = (ledger?.customerId ?? '').isNotEmpty
        ? ledger!.customerId
        : 'USER-${widget.wallet.userId}';
    return Container(
      width: double.infinity,
      color: _navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 24),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.history, color: _gold, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TRANSACTION LEDGER',
                        style: TextStyle(
                            color: _gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3)),
                    const SizedBox(height: 4),
                    Text(widget.wallet.userName.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 6),
                    Text('$id · ${widget.wallet.userEmail ?? '—'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFFB9C5E5), fontSize: 13)),
                  ]),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refreshing ? null : () => _load(),
              icon: _refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync, color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _summary(WalletLedger l) {
    final cards = [
      _card('WALLET BALANCE', formatInr(_balance ?? widget.wallet.balance),
          _navy),
      _card('CREDITS', formatInr(l.credits), _green),
      _card('DEBITS', formatInr(l.debits), _red),
      _card('TDS + CHARGES', formatInr(l.tds + l.charges), _goldText),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth < 320 ? 1 : 2;
      final w = (c.maxWidth - 14 * (cols - 1)) / cols;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [for (final card in cards) SizedBox(width: w, child: card)],
      );
    });
  }

  Widget _card(String label, String value, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                fontSize: 11)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic)),
        ),
      ]));

  Widget _chip(String text, String key) {
    final selected = _filter == key;
    return InkWell(
      onTap: () => setState(() => _filter = key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _navy : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _navy : _border, width: 1.4),
        ),
        child: Text(text,
            style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.6)),
      ),
    );
  }

  Widget _row(WalletLedgerEntry e) {
    final color = e.isCredit ? _green : _red;
    final hasBreakdown = e.tds > 0 || e.charges > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          border: Border.all(color: _border, width: 1.2),
          borderRadius: BorderRadius.circular(22)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(e.isCredit ? Icons.south_west : Icons.north_east,
              color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(e.category.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        fontSize: 13)),
                if (e.status.isNotEmpty)
                  Text(e.status.toUpperCase(),
                      style: const TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 11)),
              ],
            ),
            if (e.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(e.description,
                  style: const TextStyle(
                      color: Color(0xFF64748B), fontSize: 13, height: 1.45)),
            ],
            if (hasBreakdown) ...[
              const SizedBox(height: 6),
              Text(
                  'Gross ${formatInr(e.gross > 0 ? e.gross : e.amount)} – '
                  'TDS ${formatInr(e.tds)} – charges ${formatInr(e.charges)}',
                  style: const TextStyle(color: _muted, fontSize: 11)),
            ],
            const SizedBox(height: 6),
            Text(
                e.createdAt == null
                    ? '—'
                    : DateFormat("dd MMM yyyy 'at' hh:mm a").format(e.createdAt!),
                style: const TextStyle(
                    color: _muted, fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 12),
        Text('${e.isCredit ? '+' : '−'}${_inr(e.amount)}',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: 17)),
      ]),
    );
  }

  Widget _footer() => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Color(0xFF22C55E), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                    'Live · refreshes every ${_refreshInterval.inSeconds}s',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Text(
                  _updatedAt == null
                      ? 'Updating…'
                      : 'Updated ${DateFormat('h:mm:ss a').format(_updatedAt!)}',
                  style: const TextStyle(
                      color: _muted, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );

  /// ₹ with Indian grouping; paise only when there are any (+₹76,676).
  static String _inr(double v) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: (v * 100).round() % 100 == 0 ? 0 : 2,
      ).format(v);
}
