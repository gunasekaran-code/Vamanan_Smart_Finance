import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/server_text.dart';
import 'package:frontend/models/tally_integration_model.dart';

/// Covers the CSV recovery path behind `TallyIntegrationService.fetchLedger`.
///
/// `data.php` serialises with a bare `json_encode()`, which returns `false` —
/// and so writes an empty HTTP 200 — as soon as a row carries a byte that is
/// not valid UTF-8. The cashback, referral and inventory ledgers all trip that
/// on live data, because some descriptions hold CP-1252 punctuation (`0x97` em
/// dash, `0x95` bullet) rather than UTF-8. The service falls back to
/// `export.php&format=csv`, which echoes the same `build_ledger()` rows as raw
/// bytes, and rebuilds the ledger from it.
///
/// The fixtures below mirror the exact column layout `build_csv()` emits,
/// including the four GST columns it splices in before Status for sales.

/// Non-GST ledgers: Date,Reference,Particulars,Type,Debit,Credit,Status.
const _cashbackCsv = 'Date,Reference,Particulars,Type,Debit,Credit,Status\n'
    '2026-09-19,CB-99,"Test Customer — MANUAL: Monthly Cashback Payout",Dr,73398.60,0.00,completed\n'
    '2026-09-06,CB-97,"Another Customer — Month 1 of 10 — Cycle #54",Dr,31194.41,0.00,completed\n'
    '2026-09-05,CB-95,"Third Customer — Month 1 of 10 — Cycle #55",Dr,11009.78,0.00,pending\n';

/// Sales: CGST,SGST,GST Rate %,Invoice Total sit *before* Status.
const _salesCsv =
    'Date,Reference,Particulars,Type,Debit,Credit,CGST,SGST,"GST Rate %","Invoice Total",Status\n'
    '2026-08-26,SAL-61,"Test Customer — 40 Gram(s) 24K Gold (40.000g)",Cr,0.00,815540.00,12233.10,12233.10,3,840006.20,active\n'
    '2026-08-26,SAL-60,"Another Customer — 8 Gram(s) 24K Gold (8.000g)",Cr,0.00,163108.00,2446.62,2446.62,3,168001.24,active\n';

/// The same rows `data.php` would have returned for [_salesCsv], used to check
/// the two paths agree.
const _salesJson = '''
{"status":"success","ledger":"sales","data":[
  {"date":"2026-08-26","ref":"SAL-61","particulars":"Test Customer — 40 Gram(s) 24K Gold (40.000g)","type":"Cr","debit":0,"credit":815540,"amount":815540,"status":"active",
   "meta":{"taxable":815540,"gst_rate":3,"cgst":12233.1,"sgst":12233.1,"gst":24466.2,"total":840006.2}},
  {"date":"2026-08-26","ref":"SAL-60","particulars":"Another Customer — 8 Gram(s) 24K Gold (8.000g)","type":"Cr","debit":0,"credit":163108,"amount":163108,"status":"active",
   "meta":{"taxable":163108,"gst_rate":3,"cgst":2446.62,"sgst":2446.62,"gst":4893.24,"total":168001.24}}
], "summary":{"count":2,"total":978648,"label":"Net Sales Revenue (excl. GST)",
  "gst_collected":29359.44,"cgst":14679.72,"sgst":14679.72,"gross_invoice":1008007.44}}
''';

void main() {
  group('decodeServerText', () {
    test('reads CP-1252 punctuation mixed into UTF-8', () {
      // 'A — B • C', with the em dash as real UTF-8 (0xE2 0x80 0x94) and the
      // bullet as a bare CP-1252 byte (0x95) — exactly what the live rows hold.
      final bytes = <int>[
        0x41,
        0x20,
        0xE2,
        0x80,
        0x94,
        0x20,
        0x42,
        0x20,
        0x95,
        0x20,
        0x43,
      ];
      expect(decodeServerText(bytes), 'A — B • C');
    });

    test('maps the CP-1252 bytes the ledgers actually carry', () {
      expect(decodeServerText([0x97]), '—'); // em dash
      expect(decodeServerText([0x95]), '•'); // bullet
      expect(decodeServerText([0x92]), '’'); // right single quote
      expect(decodeServerText([0x80]), '€'); // euro
    });

    test('leaves well-formed UTF-8 untouched', () {
      final utf8Bytes = utf8.encode('Gold ₹1,23,456.78 — 24K');
      expect(decodeServerText(utf8Bytes), 'Gold ₹1,23,456.78 — 24K');
    });

    test('never emits a replacement character for these inputs', () {
      expect(decodeServerText([0x97, 0x95, 0x92]), isNot(contains('�')));
    });
  });

  group('TallyLedgerResult.fromCsv', () {
    test('rebuilds a non-GST ledger with its summary', () {
      final result =
          TallyLedgerResult.fromCsv(_cashbackCsv, ledger: TallyLedger.cashback);

      expect(result.rows.length, 3);
      expect(result.summary.count, 3);
      expect(result.summary.label, 'Total Cashback Paid');
      expect(result.summary.total, closeTo(115602.79, 0.001));
      // No GST columns on this ledger, so the strip must stay hidden.
      expect(result.summary.hasGst, isFalse);
      expect(result.summary.gstCollected, isNull);

      final first = result.rows.first;
      expect(first.date, '2026-09-19');
      expect(first.ref, 'CB-99');
      expect(first.type, 'Dr');
      expect(first.debit, 73398.60);
      expect(first.credit, 0);
      // Every build_ledger() row books one side and sets amount to it.
      expect(first.amount, 73398.60);
      expect(first.status, 'completed');
      expect(result.rows.last.status, 'pending');
    });

    test('reads the sales GST columns from the right cells', () {
      final result =
          TallyLedgerResult.fromCsv(_salesCsv, ledger: TallyLedger.sales);

      final first = result.rows.first;
      expect(first.credit, 815540.00);
      expect(first.debit, 0);
      expect(first.amount, 815540.00);
      expect(first.meta['cgst'], 12233.10);
      expect(first.meta['sgst'], 12233.10);
      expect(first.meta['gst'], closeTo(24466.20, 0.001));
      expect(first.meta['gst_rate'], 3);
      expect(first.meta['total'], 840006.20);
      // Status sits after the four GST columns — a fixed index would read
      // the invoice total here instead.
      expect(first.status, 'active');

      expect(result.summary.hasGst, isTrue);
      expect(result.summary.gstCollected, closeTo(29359.44, 0.001));
      expect(result.summary.cgst, closeTo(14679.72, 0.001));
      expect(result.summary.sgst, closeTo(14679.72, 0.001));
      expect(result.summary.grossInvoice, closeTo(1008007.44, 0.001));
      expect(result.summary.total, closeTo(978648.00, 0.001));
    });

    test('agrees with the JSON path row for row', () {
      final fromJson = TallyLedgerResult.fromJson(
        jsonDecode(_salesJson) as Map<String, dynamic>,
        ledger: TallyLedger.sales,
      );
      final fromCsv =
          TallyLedgerResult.fromCsv(_salesCsv, ledger: TallyLedger.sales);

      expect(fromCsv.rows.length, fromJson.rows.length);
      expect(fromCsv.summary.label, fromJson.summary.label);
      // The CSV rounds money to 2dp, so the totals agree to the paisa.
      expect(fromCsv.summary.total, closeTo(fromJson.summary.total, 0.05));
      expect(fromCsv.summary.gstCollected!,
          closeTo(fromJson.summary.gstCollected!, 0.05));
      expect(fromCsv.summary.grossInvoice!,
          closeTo(fromJson.summary.grossInvoice!, 0.05));

      for (var i = 0; i < fromJson.rows.length; i++) {
        final a = fromJson.rows[i];
        final b = fromCsv.rows[i];
        expect(b.ref, a.ref);
        expect(b.date, a.date);
        expect(b.particulars, a.particulars);
        expect(b.type, a.type);
        expect(b.status, a.status);
        expect(b.debit, closeTo(a.debit, 0.01));
        expect(b.credit, closeTo(a.credit, 0.01));
        expect(b.amount, closeTo(a.amount, 0.01));
      }
    });

    test('survives a header-only export', () {
      final result = TallyLedgerResult.fromCsv(
        'Date,Reference,Particulars,Type,Debit,Credit,Status\n',
        ledger: TallyLedger.withdrawal,
      );
      expect(result.rows, isEmpty);
      expect(result.summary.count, 0);
      expect(result.summary.total, 0);
      expect(result.summary.label, 'Total Withdrawn');
    });

    test('survives an empty body', () {
      final result =
          TallyLedgerResult.fromCsv('', ledger: TallyLedger.inventory);
      expect(result.rows, isEmpty);
      expect(result.summary.label, 'Total Stock Value');
    });

    test('keeps embedded commas and dashes in particulars', () {
      final result = TallyLedgerResult.fromCsv(
        'Date,Reference,Particulars,Type,Debit,Credit,Status\n'
        '2026-09-19,VEVP051,"Paint Emulsion (20L), 4 cans — Construction",Dr,3200.00,0.00,active\n',
        ledger: TallyLedger.inventory,
      );
      expect(result.rows.single.particulars,
          'Paint Emulsion (20L), 4 cans — Construction');
      expect(result.rows.single.amount, 3200.00);
    });
  });

  group('TallyLedger', () {
    test('total labels match the backend summary strings', () {
      expect(TallyLedger.sales.totalLabel, 'Net Sales Revenue (excl. GST)');
      expect(TallyLedger.customer.totalLabel, 'Total Payable to Customers');
      expect(TallyLedger.cashback.totalLabel, 'Total Cashback Paid');
      expect(TallyLedger.referral.totalLabel, 'Total Referral Commission');
      expect(TallyLedger.withdrawal.totalLabel, 'Total Withdrawn');
      expect(TallyLedger.inventory.totalLabel, 'Total Stock Value');
    });

    test('resolves every wire name the backend accepts', () {
      for (final ledger in TallyLedger.values) {
        expect(TallyLedger.fromWire(ledger.wire), ledger);
      }
    });
  });
}
