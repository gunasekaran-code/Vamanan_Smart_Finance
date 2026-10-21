import 'dart:convert';

/// Decodes a response body that is *mostly* UTF-8 but carries stray CP-1252
/// bytes.
///
/// Some rows in the database hold Windows-1252 punctuation written as single
/// high bytes — `0x97` (—), `0x95` (•), `0x92` (’) — mixed in with properly
/// encoded UTF-8 text. Those bytes are what make `json_encode()` return `false`
/// on the Tally ledger endpoints, and `utf8.decode` throws on them as well.
///
/// Strict UTF-8 is tried first, so well-formed responses cost nothing. When it
/// fails, the bytes are walked one sequence at a time: valid UTF-8 is decoded
/// as UTF-8, and any byte that cannot start or continue a sequence is read as
/// CP-1252. That keeps the punctuation intact instead of replacing it with
/// U+FFFD the way `allowMalformed: true` would.
String decodeServerText(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return _decodeMixed(bytes);
  }
}

String _decodeMixed(List<int> bytes) {
  final buffer = StringBuffer();
  var i = 0;

  while (i < bytes.length) {
    final lead = bytes[i];

    if (lead < 0x80) {
      buffer.writeCharCode(lead);
      i++;
      continue;
    }

    final length = _sequenceLength(lead);
    if (length > 1 && _isValidSequence(bytes, i, length)) {
      buffer.write(utf8.decode(bytes.sublist(i, i + length)));
      i += length;
      continue;
    }

    // Not valid UTF-8 — read the byte as CP-1252. Above 0x9F that codepage is
    // identical to Latin-1, which maps straight onto the Unicode codepoint.
    buffer.writeCharCode(_cp1252High[lead - 0x80] ?? lead);
    i++;
  }

  return buffer.toString();
}

/// Bytes a UTF-8 sequence occupies, from its lead byte. 1 means "not a lead".
int _sequenceLength(int lead) {
  if (lead >= 0xC2 && lead <= 0xDF) return 2;
  if (lead >= 0xE0 && lead <= 0xEF) return 3;
  if (lead >= 0xF0 && lead <= 0xF4) return 4;
  return 1;
}

bool _isValidSequence(List<int> bytes, int start, int length) {
  if (start + length > bytes.length) return false;
  for (var i = start + 1; i < start + length; i++) {
    if (bytes[i] < 0x80 || bytes[i] > 0xBF) return false;
  }
  return true;
}

/// CP-1252's 0x80–0x9F block, the only range where it differs from Latin-1.
/// A null is an unassigned byte, which falls back to its Latin-1 codepoint.
const Map<int, int> _cp1252High = {
  0x00: 0x20AC, // €
  0x02: 0x201A, // ‚
  0x03: 0x0192, // ƒ
  0x04: 0x201E, // „
  0x05: 0x2026, // …
  0x06: 0x2020, // †
  0x07: 0x2021, // ‡
  0x08: 0x02C6, // ˆ
  0x09: 0x2030, // ‰
  0x0A: 0x0160, // Š
  0x0B: 0x2039, // ‹
  0x0C: 0x0152, // Œ
  0x0E: 0x017D, // Ž
  0x11: 0x2018, // ‘
  0x12: 0x2019, // ’
  0x13: 0x201C, // “
  0x14: 0x201D, // ”
  0x15: 0x2022, // •
  0x16: 0x2013, // –
  0x17: 0x2014, // —
  0x18: 0x02DC, // ˜
  0x19: 0x2122, // ™
  0x1A: 0x0161, // š
  0x1B: 0x203A, // ›
  0x1C: 0x0153, // œ
  0x1E: 0x017E, // ž
  0x1F: 0x0178, // Ÿ
};
