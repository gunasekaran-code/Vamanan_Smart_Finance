import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/network/api_response.dart';
import 'package:frontend/models/gst_filing_model.dart';

class GstFilingEndpoints {
  GstFilingEndpoints._();
  static const String report = 'admin/gst_filing.php';
}

class GstFilingService {
  GstFilingService._();
  static final GstFilingService instance = GstFilingService._();

  final http.Client _client = http.Client();

  /// READ — the full GST filing report. Pass [month] as 'YYYY-MM' to filter
  /// to a single period; omit it for all-time.
  ///
  /// gst_filing.php only allows GET (its CORS preflight rejects POST on web).
  Future<ApiResponse<GstFilingReport>> fetchReport({String? month}) async {
    final uri = ApiConfig.endpoint(GstFilingEndpoints.report).replace(
      queryParameters:
          (month != null && month.isNotEmpty) ? {'month': month} : null,
    );

    late final http.Response response;
    try {
      response = await _client.get(uri, headers: const {
        'Accept': 'application/json',
      }).timeout(ApiConfig.timeout);
    } catch (_) {
      return ApiResponse<GstFilingReport>.failure(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    final body = _decode(response.body);
    if (body == null) {
      return ApiResponse<GstFilingReport>.failure(
        'The server returned an unexpected response.',
      );
    }
    return ApiResponse<GstFilingReport>.fromJson(
      body,
      parser: (json) => GstFilingReport.fromJson(json),
    );
  }

  /// Tolerates PHP notices printed ahead of the JSON envelope by retrying on
  /// the substring between the first `{` and the last `}`.
  Map<String, dynamic>? _decode(String raw) {
    Map<String, dynamic>? tryDecode(String source) {
      try {
        final value = jsonDecode(source);
        return value is Map<String, dynamic> ? value : null;
      } catch (_) {
        return null;
      }
    }

    final parsed = tryDecode(raw);
    if (parsed != null) return parsed;
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    return (start != -1 && end > start)
        ? tryDecode(raw.substring(start, end + 1))
        : null;
  }
}
