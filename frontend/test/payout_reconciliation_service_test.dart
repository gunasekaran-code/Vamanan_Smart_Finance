import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/payout_reconciliation_model.dart';
import 'package:frontend/services/payout_reconciliation_service.dart';

void main() {
  final service = PayoutReconciliationService();
  Uint8List b(String s) => Uint8List.fromList(utf8.encode(s));

  test('parses a plain CSV, skipping the header', () {
    final rows = service.parseFile('bank.csv',
        b('Transaction ID,Status,Failure Reason\n38,success,\n39,failed,Invalid IFSC\n'));
    expect(rows.length, 2);
    expect(rows[0].transactionId, '38');
    expect(rows[0].isSuccess, isTrue);
    expect(rows[0].failureReason, isNull);
    expect(rows[1].transactionId, '39');
    expect(rows[1].isSuccess, isFalse);
    expect(rows[1].failureReason, 'Invalid IFSC');
  });

  test('handles CRLF line endings and a UTF-8 BOM', () {
    final rows = service.parseFile('bank.csv',
        b('﻿Transaction ID,Status,Reason\r\n38,success,\r\n'));
    expect(rows.length, 1);
    expect(rows[0].transactionId, '38');
  });

  test('handles quoted fields containing commas', () {
    final rows = service.parseFile('bank.csv',
        b('id,status,reason\n40,failed,"Account closed, contact payee"\n'));
    expect(rows.single.failureReason, 'Account closed, contact payee');
  });

  test('header-only file yields no rows', () {
    expect(service.parseFile('bank.csv', b('id,status,reason\n')), isEmpty);
  });

  test('rejects an unsupported extension', () {
    expect(() => service.parseFile('bank.pdf', b('x')),
        throwsA(isA<ReconciliationException>()));
  });

  test('toJson matches the backend contract', () {
    final rows = service.parseFile('bank.csv',
        b('id,status,reason\n39,FAILED,Invalid IFSC\n'));
    expect(rows.single.toJson(),
        {'transaction_id': '39', 'status': 'failed', 'reason': 'Invalid IFSC'});
  });
}
