import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/agreement_downloader.dart';
import 'package:frontend/models/auditor_agreement_model.dart';
import 'package:frontend/services/auditor_agreement_service.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class AuditorAgreementScreen extends StatefulWidget {
  final String userId;
  const AuditorAgreementScreen({super.key, required this.userId});
  @override
  State<AuditorAgreementScreen> createState() => _AuditorAgreementScreenState();
}

class _AuditorAgreementScreenState extends State<AuditorAgreementScreen> {
  final _service = AuditorAgreementService.instance;
  final _money =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _date = DateFormat('d MMMM, y');
  late Future<AuditorAgreement> _future;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _future = _service.fetch(widget.userId);
  }

  void _reload() => setState(() => _future = _service.fetch(widget.userId));

  Future<void> _download(AuditorAgreement agreement) async {
    setState(() => _downloading = true);
    final started = await downloadAgreementHtml(agreement);
    if (!mounted) return;
    setState(() => _downloading = false);
    ToastService.show(
        title: started ? 'Download Started' : 'Could Not Start Download',
        message: started
            ? 'Your agreement file is being downloaded.'
            : 'Please try again in a moment.',
        type: started ? ToastType.success : ToastType.error);
  }

  Future<void> _share(AuditorAgreement a) => SharePlus.instance.share(
        ShareParams(
          text:
              'Vamanan Enterprises agreement ${a.agreementId}\nCustomer: ${a.customerName}\nStatus: ${a.status.toUpperCase()}\nProduct: ${a.productName}',
          subject: 'Agreement ${a.agreementId}',
        ),
      );

@override
  Widget build(BuildContext context) => AppPage(title: null, children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: FutureBuilder<AuditorAgreement>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 120),
                        child: Center(child: AppLoader()));
                  }
                  if (snapshot.hasError) return _error(snapshot.error.toString());
                  return _content(snapshot.data!);
                }),
          ),
        )
      ]);

  Widget _error(String message) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(children: [
        const Icon(Icons.error_outline, size: 42, color: Color(0xFF94A3B8)),
        const SizedBox(height: 12),
        const Text('COULD NOT LOAD AGREEMENT',
            style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: _reload, child: const Text('RETRY')),
      ]));

  Widget _content(AuditorAgreement a) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
       Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: AppColors.goldColor, size: 8),
            const SizedBox(width: 8),
            const Text(
              'LEGAL DOCUMENT',
              style: TextStyle(
                color: AppColors.goldColor,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('AGREEMENT',
            style: TextStyle(
                color: Color(0xFF1B233A),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 4),
        const Text('YOUR DIGITAL GOLD PURCHASE CERTIFICATE',
            style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
              child: OutlinedButton(
                  onPressed: a.hasAgreement ? () => _share(a) : null,
                  child: const Icon(Icons.share_outlined))),
          const SizedBox(width: 16),
          Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                  onPressed: _downloading || !a.hasAgreement
                      ? null
                      : () => _download(a),
                  icon: _downloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded),
                  label: Text(_downloading ? 'PREPARING...' : 'DOWNLOAD'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B233A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16)))),
        ]),
        const SizedBox(height: 32),
        _certificate(a),
        const SizedBox(height: 40),
      ]);

  Widget _certificate(AuditorAgreement a) => Container(
      padding:
          EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 28),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
                color: Color(0x12000000), blurRadius: 24, offset: Offset(0, 8))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.verified, color: AppColors.goldColor, size: 38),
        const SizedBox(height: 12),
        const Text('GOLD PURCHASE AGREEMENT',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF1B233A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 6),
        Text('AGREEMENT ID: ${a.agreementId}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.goldColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3)),
        const SizedBox(height: 20),
        const Divider(thickness: 2),
        const SizedBox(height: 20),
        _notice(
            'THIS AGREEMENT WAS CREATED ON ${a.agreementDate == null ? '—' : _date.format(a.agreementDate!)} AT THE KRISHNAGIRI HUB.'),
        const SizedBox(height: 24),
        _entity('COMPANY (ISSUER)', a.companyName, a.companyOffice,
            Icons.account_balance_outlined),
        const SizedBox(height: 14),
        _entity(
            'CUSTOMER (BUYER)',
            a.customerName,
            '${a.customerEmail.isEmpty ? '' : '${a.customerEmail} • '}${a.customerAddress}',
            Icons.shield_outlined),
        const SizedBox(height: 28),
        _heading('1', 'PURCHASE DETAILS'),
        const SizedBox(height: 12),
        _terms('Agreement type: ${a.type}.'),
        _terms('This agreement is currently ${a.status.toUpperCase()}.'),
        const SizedBox(height: 16),
        _product(a),
        const SizedBox(height: 28),
        _heading('2', 'TERMS & CONDITIONS'),
        const SizedBox(height: 12),
        _terms(
            'Cashback is subject to the plan terms and the 100% purchase-value cap.'),
        _terms(
            'Referral benefits are governed by the active platform referral rules.'),
        _terms(
            'A completed agreement is available to download from this page.'),
        const SizedBox(height: 28),
        _signature(
            'AUTHORIZED CONTROL', a.companyName, Icons.apartment_outlined),
        _signature(
            'YOUR SIGNATURE',
            a.signedAt == null ? 'PENDING' : a.customerName,
            Icons.draw_outlined),
      ]));

  Widget _notice(String value) => Container(
      padding: const EdgeInsets.only(left: 14),
      decoration: const BoxDecoration(
          border:
              Border(left: BorderSide(color: AppColors.goldColor, width: 4))),
      child: Text(value,
          style: const TextStyle(
              color: Color(0xFF1B233A),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.5)));
  Widget _entity(String label, String title, String detail, IconData icon) =>
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: AppColors.goldColor),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                  const SizedBox(height: 5),
                  Text(title,
                      style: const TextStyle(
                          color: Color(0xFF1B233A),
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(detail,
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 10, height: 1.4))
                ]))
          ]));
  Widget _heading(String number, String title) => Row(children: [
        CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF1B233A),
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900))),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  color: Color(0xFF1B233A),
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5)),
        )
      ]);
  Widget _terms(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: const TextStyle(
              color: Color(0xFF475569), fontSize: 11, height: 1.45)));
  Widget _product(AuditorAgreement a) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        _stat('PRODUCT', a.productName),
        _stat('TOTAL VALUE', _money.format(a.price), gold: true),
        _stat('WEIGHT', '${a.weight} g')
      ]));
  Widget _stat(String label, String value, {bool gold = false}) => Expanded(
          child: Column(children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 8,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(value,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: gold ? AppColors.goldColor : const Color(0xFF1B233A),
                fontSize: 11,
                fontWeight: FontWeight.w900))
      ]));
  Widget _signature(String label, String name, IconData icon) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 12),
        // Expanded lets long names (e.g. the company name) wrap instead of
        // running off the card.
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(name,
                style: const TextStyle(
                    color: Color(0xFF1B233A), fontWeight: FontWeight.w900))
          ]),
        )
      ]));
}
