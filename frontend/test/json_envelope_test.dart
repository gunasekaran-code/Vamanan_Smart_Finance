import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/json_envelope.dart';
import 'package:http/http.dart' as http;

http.Response _res(String body, {int status = 200}) =>
    http.Response.bytes(utf8.encode(body), status);

void main() {
  group('decodeJsonEnvelope', () {
    test('reads a clean envelope', () {
      final decoded = _res('{"status":"success","data":[]}');
      expect(decodeJsonEnvelope(decoded)['status'], 'success');
    });

    test('survives a PHP notice printed ahead of the JSON', () {
      // config.php runs self-healing DDL on every request; anything it emits
      // lands in front of the body. This is what produced "Could not parse
      // server response" on the Buy screen.
      final body =
          '<br />\n<b>Warning</b>:  Undefined array key "gst_rate" in '
          '<b>/home/api/config.php</b> on line <b>412</b><br />\n'
          '{"status":"success","data":[{"id":"1","name":"22K Gold Coin"}]}';

      final decoded = decodeJsonEnvelope(_res(body));
      expect(decoded['status'], 'success');
      expect((decoded['data'] as List), hasLength(1));
    });

    test('survives a trailing notice too', () {
      final body = '{"status":"success","data":[]}\n'
          '<br /><b>Deprecated</b>: bar in <b>db.php</b> on line <b>9</b>';
      expect(decodeJsonEnvelope(_res(body))['status'], 'success');
    });

    test('keeps CP-1252 punctuation intact', () {
      // http.Response.body would decode these bytes as latin1 and mangle them.
      final bytes = <int>[
        ...utf8.encode('{"status":"success","message":"Rolex 40mm '),
        0x97, // em dash, written as a single CP-1252 byte
        ...utf8.encode(' ok"}'),
      ];
      final decoded = decodeJsonEnvelope(http.Response.bytes(bytes, 200));
      expect(decoded['message'], contains('—'));
    });

    test('reads the error body behind a 500 rather than hiding it', () {
      final decoded = decodeJsonEnvelope(
        _res('{"status":"error","message":"user_id required"}', status: 500),
      );
      expect(decoded['status'], 'error');
      expect(decoded['message'], 'user_id required');
    });

    test('throws with a snippet when there is no JSON at all', () {
      try {
        decodeJsonEnvelope(_res('<html><body>502 Bad Gateway</body></html>',
            status: 502));
        fail('expected ServerEnvelopeException');
      } on ServerEnvelopeException catch (e) {
        expect(e.statusCode, 502);
        // The snippet is the point: it shows what actually came back.
        expect(e.toString(), contains('502 Bad Gateway'));
      }
    });

    test('reports an empty body clearly', () {
      try {
        decodeJsonEnvelope(_res(''));
        fail('expected ServerEnvelopeException');
      } on ServerEnvelopeException catch (e) {
        expect(e.toString(), contains('empty'));
      }
    });

    test('rejects a bare JSON array, which is not an envelope', () {
      expect(
        () => decodeJsonEnvelope(_res('[1,2,3]')),
        throwsA(isA<ServerEnvelopeException>()),
      );
    });
  });
}
