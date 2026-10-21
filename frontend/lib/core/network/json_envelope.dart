import 'dart:convert';

import 'package:http/http.dart' as http;

import 'server_text.dart';

/// Thrown when a reply cannot be read as a JSON object at all. [snippet]
/// carries the start of what the server actually sent, which is usually the
/// PHP notice that broke the parse.
class ServerEnvelopeException implements Exception {
  final String message;
  final String snippet;
  final int statusCode;

  const ServerEnvelopeException(this.message, this.snippet, this.statusCode);

  @override
  String toString() => snippet.isEmpty ? message : '$message — $snippet';
}

/// Reads a PHP endpoint's reply into a decoded JSON map, tolerating the two
/// ways these endpoints routinely produce bodies that a plain
/// `jsonDecode(response.body)` chokes on:
///
///  1. **Leading noise.** `api/config.php` runs a block of self-healing DDL on
///     every single request, so any notice, warning or deprecation it emits is
///     printed *ahead* of the JSON. `ApiClient` has always tolerated this; the
///     hand-rolled services did not, and surfaced it as the useless
///     "Could not parse server response".
///  2. **Stray CP-1252 bytes.** `http.Response.body` decodes as latin1 unless
///     the server names a charset, which mangles anything non-ASCII. Going
///     through [decodeServerText] on the raw bytes keeps `—`, `•` and `’`
///     intact.
///
/// The HTTP status is deliberately *not* checked here: several endpoints
/// answer 400/500 with a perfectly good `{"status":"error","message":...}`
/// body, and that message is far more useful to show than the status code.
Map<String, dynamic> decodeJsonEnvelope(http.Response response) {
  final body = decodeServerText(response.bodyBytes);

  final parsed = _tryDecode(body) ?? _tryDecode(_extractObject(body));
  if (parsed != null) return parsed;

  throw ServerEnvelopeException(
    'The server did not return readable JSON (HTTP ${response.statusCode})',
    _snippet(body),
    response.statusCode,
  );
}

/// The substring from the first `{` to the last `}` — the actual envelope,
/// once whatever PHP printed in front of it is dropped.
String? _extractObject(String body) {
  final start = body.indexOf('{');
  final end = body.lastIndexOf('}');
  if (start == -1 || end <= start) return null;
  return body.substring(start, end + 1);
}

Map<String, dynamic>? _tryDecode(String? source) {
  if (source == null || source.isEmpty) return null;
  try {
    final value = jsonDecode(source);
    return value is Map<String, dynamic> ? value : null;
  } catch (_) {
    return null;
  }
}

/// A short, single-line preview of the body for the error message.
String _snippet(String body) {
  final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (flat.isEmpty) return 'the response was empty';
  return flat.length <= 160 ? flat : '${flat.substring(0, 160)}…';
}
