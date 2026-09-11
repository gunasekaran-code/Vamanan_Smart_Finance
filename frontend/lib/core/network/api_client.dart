import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpException, SocketException;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/network/api_response.dart';

/// Thin JSON transport over the PHP backend.
///
/// It owns exactly three concerns — encoding the request body, decoding the
/// reply, and turning transport failures into [ApiException] — so services
/// above it only deal in [ApiResponse].
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Overridable so tests can inject a MockClient.
  @visibleForTesting
  http.Client client = http.Client();

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// POSTs [body] as JSON to `<baseUrl>/<path>` and decodes the envelope.
  ///
  /// [parser] maps the decoded body to a typed payload and only runs when the
  /// backend reports `status: success`.
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic> body = const {},
    T Function(Map<String, dynamic> json)? parser,
  }) async {
    final uri = ApiConfig.endpoint(path);
    try {
      final response = await client
          .post(uri, headers: _jsonHeaders, body: jsonEncode(body))
          .timeout(ApiConfig.timeout);

      final decoded = _decode(response.body, response.statusCode);
      return ApiResponse<T>.fromJson(decoded, parser: parser);
    } on TimeoutException {
      throw ApiException.timeout();
    } on SocketException {
      throw ApiException.network();
    } on HttpException {
      throw ApiException.network();
    } on http.ClientException {
      // Thrown on web instead of SocketException (CORS, refused connection).
      throw ApiException.network();
    }
  }

  /// Decodes a reply, tolerating the PHP notices/warnings that the
  /// self-healing `config.php` can print ahead of the JSON body: if a plain
  /// decode fails we retry on the substring from the first `{` to the last
  /// `}`, which is the actual envelope.
  Map<String, dynamic> _decode(String body, int statusCode) {
    Map<String, dynamic>? parsed = _tryDecode(body);

    if (parsed == null) {
      final start = body.indexOf('{');
      final end = body.lastIndexOf('}');
      if (start != -1 && end > start) {
        parsed = _tryDecode(body.substring(start, end + 1));
      }
    }

    if (parsed == null) {
      debugPrint('ApiClient: non-JSON reply ($statusCode): '
          '${body.length > 500 ? '${body.substring(0, 500)}…' : body}');
      throw ApiException.badResponse(statusCode: statusCode, body: body);
    }
    return parsed;
  }

  Map<String, dynamic>? _tryDecode(String source) {
    try {
      final value = jsonDecode(source);
      return value is Map<String, dynamic> ? value : null;
    } catch (_) {
      return null;
    }
  }
}
