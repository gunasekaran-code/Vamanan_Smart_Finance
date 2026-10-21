import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../models/tally_export_model.dart';

class TallyExportService {
  /// Lists cashback applications — backs the stat cards and the table.
  /// `statusFilter` uses the same values the backend accepts
  /// (pending | approved | rejected); omit for all.
  Future<List<CashbackApplication>> fetchApplications({String? statusFilter}) async {
    final params = <String, String>{};
    if (statusFilter != null && statusFilter.isNotEmpty) {
      params['status'] = statusFilter;
    }
    final uri = ApiConfig.endpoint(AdminEndpoints.cashbackApplications)
        .replace(queryParameters: params.isEmpty ? null : params);

    http.Response response;
    try {
      response = await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw TallyExportException('Could not reach the server: $e');
    }

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw TallyExportException('Unexpected response (HTTP ${response.statusCode}).');
    }

    // Accept either a bare list or {"status":"success","data":[...]}
    List<dynamic> rows;
    if (body is List) {
      rows = body;
    } else if (body is Map<String, dynamic>) {
      if (body['status'] != null && body['status'] != 'success') {
        throw TallyExportException(body['message']?.toString() ?? 'Failed to load applications.');
      }
      rows = (body['data'] ?? body['applications'] ?? []) as List<dynamic>;
    } else {
      throw TallyExportException('Unexpected response shape.');
    }

    return rows.map((e) => CashbackApplication.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Builds the URL for mode=download. Launch this with url_launcher
  /// (or open in a WebView) to trigger the browser/OS file download —
  /// simplest cross-platform way to hand back an attachment response.
  Uri buildDownloadUri(TallyExportSettings settings) {
    return ApiConfig.endpoint(AdminEndpoints.tallyExport)
        .replace(queryParameters: settings.toQueryParams('download'));
  }

  /// mode=preview returns the raw XML as plain text.
  Future<String> previewXml(TallyExportSettings settings) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.tallyExport)
        .replace(queryParameters: settings.toQueryParams('preview'));

    http.Response response;
    try {
      response = await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw TallyExportException('Could not reach the server: $e');
    }
    if (response.statusCode != 200) {
      throw TallyExportException('Preview failed (HTTP ${response.statusCode}).');
    }
    return response.body;
  }

  /// mode=push sends vouchers straight to Tally's HTTP gateway and
  /// returns a JSON result (success / offline fallback / error).
  Future<TallyPushResult> pushToTally(TallyExportSettings settings) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.tallyExport)
        .replace(queryParameters: settings.toQueryParams('push'));

    http.Response response;
    try {
      // Push mode can take longer (it round-trips to Tally itself).
      response = await http.get(uri).timeout(const Duration(seconds: 35));
    } catch (e) {
      throw TallyExportException('Could not reach the server: $e');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw TallyExportException('Unexpected response (HTTP ${response.statusCode}).');
    }

    return TallyPushResult.fromJson(body);
  }
}