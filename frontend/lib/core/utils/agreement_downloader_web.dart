// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import '../../models/auditor_agreement_model.dart';

Future<bool> downloadAgreementHtml(AuditorAgreement agreement) async {
  String escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  final document = '''<!doctype html><html><head><meta charset="utf-8">
<title>Agreement ${escape(agreement.agreementId)}</title>
<style>body{font:15px Arial,sans-serif;color:#1b233a;max-width:760px;margin:48px auto;line-height:1.6}.head{border-bottom:3px solid #b8860b;padding-bottom:18px}.label{color:#8a6d00;font-weight:bold;letter-spacing:1px}.box{background:#f8fafc;padding:18px;margin:18px 0;border-radius:10px}table{width:100%;border-collapse:collapse}td{padding:9px;border-bottom:1px solid #e2e8f0}</style></head><body>
<div class="head"><div class="label">VAMANAN ENTERPRISES</div><h1>Gold Purchase Agreement</h1><p>Agreement ID: <strong>${escape(agreement.agreementId)}</strong></p></div>
<div class="box"><strong>Customer</strong><br>${escape(agreement.customerName)}<br>${escape(agreement.customerEmail)}<br>${escape(agreement.customerAddress)}</div>
<table><tr><td>Agreement type</td><td>${escape(agreement.type)}</td></tr><tr><td>Status</td><td>${escape(agreement.status.toUpperCase())}</td></tr><tr><td>Product</td><td>${escape(agreement.productName)}</td></tr><tr><td>Total value</td><td>₹${agreement.price.toStringAsFixed(2)}</td></tr><tr><td>Weight</td><td>${agreement.weight} g</td></tr></table>
<p>This digital copy was generated from the agreement details returned by Vamanan Enterprises.</p></body></html>''';
  final url =
      html.Url.createObjectUrlFromBlob(html.Blob([document], 'text/html'));
  final filename =
      '${agreement.agreementId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-')}.html';
  final anchor = html.AnchorElement(href: url)..download = filename;
  anchor.click();
  html.Url.revokeObjectUrl(url);
  return true;
}
