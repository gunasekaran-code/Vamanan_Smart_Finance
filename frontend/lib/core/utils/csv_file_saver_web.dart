// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

/// Web: triggers a browser download of the CSV.
Future<bool> saveCsvFile(String filename, String csv) async {
  final blob = html.Blob([utf8.encode(csv)], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}

/// Web: triggers a browser download of any binary file (e.g. an .xlsx).
Future<bool> saveBinaryFile(
    String filename, List<int> bytes, String mimeType) async {
  final blob = html.Blob([Uint8List.fromList(bytes)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
