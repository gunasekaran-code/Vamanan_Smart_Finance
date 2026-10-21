import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/payout_reconciliation_model.dart';
import '../../models/wallet_account_model.dart' show WalletAccount;
import 'wallet_purchase_history.dart';

/// One cashback payout, opened from the reconciliation STATUS MATRIX.
///
/// Pushed inside the app shell, so the header shows the back arrow and the
/// mobile bottom navigation stays visible. All data comes from the row the
/// matrix already loaded (admin/payout_reports.php).
class PayoutDetailScreen extends StatelessWidget {
  final ReconciliationLedgerRow payout;

  const PayoutDetailScreen({super.key, required this.payout});

  static const Color _navy = Color(0xFF243D8F);
  static const Color _gold = Color(0xFFF7C948);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _border = Color(0xFFEEF2F7);

  /// Opens this payee's Transaction Ledger (also pushed inside the shell).
  static void openLedger(BuildContext context, ReconciliationLedgerRow p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WalletPurchaseHistoryScreen(
          wallet: WalletAccount(
            walletId: '',
            userId: p.investorId,
            // The ledger reads the live balance itself.
            balance: 0,
            totalEarned: 0,
            totalWithdrawn: 0,
            userName: p.investorName,
            userEmail: p.email,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = payout;
    final status = p.status.isEmpty
        ? '—'
        : p.status[0].toUpperCase() + p.status.substring(1);
    final hasBank = (p.bankName ?? '').isNotEmpty;

    final details = <(String, String)>[
      ('AMOUNT', _inr(p.amount)),
      ('STATUS', status),
      ('MONTH', p.monthLabel ?? '—'),
      (
        'PAID ON',
        p.createdAt == null
            ? '—'
            : DateFormat('d/M/yyyy, h:mm:ss a').format(p.createdAt!)
      ),
      ('BANK', hasBank ? p.bankName! : 'Wallet settlement'),
      ('ACCOUNT NO.', p.accountNo ?? '—'),
      ('IFSC', (p.ifscCode ?? '—').toUpperCase()),
      ('CUSTOMER ID', p.investorId.isEmpty ? '—' : p.investorId),
      if (p.isFailed) ('FAILURE REASON', p.failureReason ?? 'Not specified'),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (label, value) in details)
                        _detailRow(label, value),
                      if ((p.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(p.description!,
                              style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  height: 1.45)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: p.investorId.isEmpty
                            ? null
                            : () => openLedger(context, p),
                        icon: const Icon(Icons.history, size: 20),
                        label: const Text('OPEN CUSTOMER LEDGER',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1.6)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
        width: double.infinity,
        color: _navy,
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PAYOUT #${payout.transactionId}',
                style: const TextStyle(
                    color: _gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 3)),
            const SizedBox(height: 6),
            Text(payout.investorName.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.6)),
            if (payout.email != null) ...[
              const SizedBox(height: 6),
              Text(payout.email!,
                  style: const TextStyle(
                      color: Color(0xFFD5DDF2),
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      );

  Widget _detailRow(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _border, width: 1.4)),
        ),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: _navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );

  static String _inr(double v) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: (v * 100).round() % 100 == 0 ? 0 : 2,
      ).format(v);
}
