import 'package:flutter/material.dart';
import 'package:frontend/models/wallet_account_model.dart';
import 'package:frontend/models/investment_history_model.dart' hide formatInr;
import 'package:frontend/services/investment_history_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

/// Investor profile opened from the wallet register. It stays inside the
/// application shell, so the mobile bottom navigation remains available.
class WalletViewInvestorScreen extends StatefulWidget {
  final WalletAccount wallet;
  const WalletViewInvestorScreen({super.key, required this.wallet});
  @override
  State<WalletViewInvestorScreen> createState() => _WalletViewInvestorScreenState();
}

class _WalletViewInvestorScreenState extends State<WalletViewInvestorScreen> {
  List<InvestmentHistoryRecord> _purchases = const [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final response = await InvestmentHistoryService.instance.fetchHistory();
    if (!mounted) return;
    setState(() {
      _purchases = (response.data ?? const [])
          .where((row) => row.userId.toString() == widget.wallet.userId).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.wallet;
    final totalPaid = _purchases.fold<double>(0, (sum, p) => sum + p.displayAmount);
    final principal = _purchases.fold<double>(0, (sum, p) => sum + p.cashbackEligibleAmount);
    return Scaffold(backgroundColor: const Color(0xFFF8FAFC), body: SafeArea(child: RefreshIndicator(onRefresh: _load, child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: Column(children: [
      _hero('CUSTOMER PROFILE', Icons.account_circle_outlined),
      Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 10, runSpacing: 10, children: [_chip((w.role ?? 'CUSTOMER').toUpperCase(), const Color(0xFFEFF6FF), const Color(0xFF2563EB)), _chip('ACCOUNT: ACTIVE', const Color(0xFFECFDF5), const Color(0xFF047857)), _chip('KYC: ${(w.kycStatus ?? 'PENDING').toUpperCase()}', const Color(0xFFFFFBEB), const Color(0xFF9A6A14))]),
        const SizedBox(height: 28), _section('CONTACT'),
        _details([['CUSTOMER ID', 'USER-${w.userId}'], ['EMAIL', w.userEmail ?? 'Not provided'], ['PHONE', w.userPhone ?? 'Not provided'], ['LAST PAYOUT', w.lastPayoutLabel]]),
        const SizedBox(height: 28), _section('WALLET & PURCHASES'),
        if (_loading) const Padding(padding: EdgeInsets.all(36), child: Center(child: AppLoader())) else GridView.count(crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 2 : 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.8, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [_stat('WALLET BALANCE', w.formattedBalance, const Color(0xFF243D8F)), _stat('TOTAL EARNED', w.formattedEarned, const Color(0xFFB98D13)), _stat('WITHDRAWN', w.formattedWithdrawn, const Color(0xFFDC2626)), _stat('PURCHASES', '${_purchases.length} (${w.activeCycles} active)', const Color(0xFF243D8F)), _stat('TOTAL PAID (INCL. GST)', formatInr(totalPaid), const Color(0xFF243D8F)), _stat('CASHBACK PRINCIPAL', formatInr(principal), const Color(0xFF243D8F))]),
      ])),
    ])))));
  }

  Widget _hero(String label, IconData icon) => Container(width: double.infinity, color: const Color(0xFF243D8F), padding: const EdgeInsets.fromLTRB(16, 18, 16, 22), child: Row(children: [
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: const Color(0xFFF7C948), size: 30)), const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Color(0xFFF7C948), fontWeight: FontWeight.w900, letterSpacing: 3)), Text(widget.wallet.userName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 25, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900)), Text('USER-${widget.wallet.userId} · ${widget.wallet.userEmail ?? '—'}', style: const TextStyle(color: Color(0xFFB9C5E5), fontSize: 13))]))
  ]));
  Widget _section(String text) => Text(text, style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 15));
  Widget _chip(String t, Color bg, Color fg) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: fg.withValues(alpha: .15))), child: Text(t, style: TextStyle(color: fg, fontWeight: FontWeight.w900, letterSpacing: 1)));
  Widget _details(List<List<String>> xs) => GridView.count(crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 1 : 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 4, children: xs.map((x) => ListTile(contentPadding: EdgeInsets.zero, title: Text(x[0], style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w900)), subtitle: Text(x[1], style: const TextStyle(color: Color(0xFF243D8F), fontSize: 17, fontWeight: FontWeight.w800)))).toList());
  Widget _stat(String a, String b, Color c) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE8EEF6)), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(a, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(b, style: TextStyle(fontSize: 18, color: c, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis)]));
}
