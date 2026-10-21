import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Mobile/desktop: hands the CSV to the system share sheet so it can be saved
/// to Files/Drive or sent on. share_plus writes the bytes to a temp file.
/// Returns false when the user dismisses the sheet.
Future<bool> saveCsvFile(String filename, String csv) async {
  final bytes = Uint8List.fromList(utf8.encode(csv));
  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'text/csv', name: filename)],
      fileNameOverrides: [filename],
      subject: filename,
    ),
  );
  return result.status != ShareResultStatus.dismissed;
}

/// Mobile/desktop: hands any binary file (e.g. an .xlsx) to the share sheet.
/// Returns false when the user dismisses the sheet.
Future<bool> saveBinaryFile(
    String filename, List<int> bytes, String mimeType) async {
  final result = await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(Uint8List.fromList(bytes),
            mimeType: mimeType, name: filename)
      ],
      fileNameOverrides: [filename],
      subject: filename,
    ),
  );
  return result.status != ShareResultStatus.dismissed;
}
