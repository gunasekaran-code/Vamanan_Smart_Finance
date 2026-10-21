import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/network/server_text.dart';
import 'package:frontend/models/tally_integration_model.dart';

/// Talks to `api/admin/tally/`. Reads are GETs against `data.php` keyed by
/// `?resource=`; writes are JSON POSTs to `vouchers.php` keyed by `action`;
/// the gateway push is its own POST to `sync.php`; and file exports are plain
/// URLs (the browser/OS handles the attachment).
class TallyIntegrationService {
  /// Pushing to Tally round-trips to TallyPrime itself over cURL with a 40s
  /// server-side timeout, so the client must wait longer than the usual 20s.
  static const Duration _syncTimeout = Duration(seconds: 50);

  /// Written into the audit trail as the actor for every action.
  final String actor;

  TallyIntegrationService({this.actor = 'admin'});

  // -------------------------------------------------------------------------
  // Reads — data.php
  // -------------------------------------------------------------------------

  Future<TallyDashboard> fetchDashboard(
      {String? startDate, String? endDate}) async {
    final json =
        await _getResource('dashboard', startDate: startDate, endDate: endDate);
    return TallyDashboard.fromJson(_dataMap(json));
  }

  /// Loads one ledger, recovering from `data.php`'s empty-body failure.
  ///
  /// `data.php` serialises through a bare `json_encode()`. That returns `false`
  /// for any row holding a byte that is not valid UTF-8, and the endpoint then
  /// answers HTTP 200 with a zero-length body — today the cashback, referral
  /// and inventory ledgers all do this, so they never render.
  ///
  /// `export.php&format=csv` builds from the same `build_ledger()` rows but
  /// echoes raw bytes, so it still carries the complete ledger. When the JSON
  /// body is empty or unparseable we read the CSV instead and rebuild the rows
  /// from it, which keeps all six ledgers working without a backend change.
  Future<TallyLedgerResult> fetchLedger(
    TallyLedger ledger, {
    String? startDate,
    String? endDate,
  }) async {
    final uri =
        ApiConfig.endpoint(TallyEndpoints.data).replace(queryParameters: {
      'resource': 'ledger',
      'ledger': ledger.wire,
      ..._dateParams(startDate, endDate),
    });
    final response =
        await _send(() => http.get(uri).timeout(ApiConfig.timeout));
    final body = decodeServerText(response.bodyBytes);

    Map<String, dynamic>? json;
    if (body.trim().isNotEmpty) {
      try {
        json = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        json = null;
      }
    }

    if (json == null) {
      return _fetchLedgerFromCsv(ledger,
          startDate: startDate, endDate: endDate);
    }

    final status = json['status']?.toString() ?? '';
    if (status != 'success') {
      throw TallyIntegrationException(
        json['message']?.toString() ??
            'Request failed (HTTP ${response.statusCode}).',
      );
    }
    return TallyLedgerResult.fromJson(json, ledger: ledger);
  }

  /// The CSV recovery path behind [fetchLedger].
  ///
  /// `export.php` writes an audit entry for every call, so the actor is tagged
  /// to keep these recoveries distinguishable from real exports in the trail.
  Future<TallyLedgerResult> _fetchLedgerFromCsv(
    TallyLedger ledger, {
    String? startDate,
    String? endDate,
  }) async {
    final uri =
        ApiConfig.endpoint(TallyEndpoints.export).replace(queryParameters: {
      'resource': 'ledger',
      'ledger': ledger.wire,
      'format': 'csv',
      'actor': '$actor (auto-recovery)',
      ..._dateParams(startDate, endDate),
    });
    final csv = await _getText(uri);
    if (csv.trim().isEmpty) {
      throw TallyIntegrationException(
        'The server returned no data for ${ledger.label}.',
      );
    }
    return TallyLedgerResult.fromCsv(csv, ledger: ledger);
  }

  Future<TallyPnlReport> fetchPnl({String? startDate, String? endDate}) async {
    final json = await _getResource(
      'report',
      extra: {'report': 'pnl'},
      startDate: startDate,
      endDate: endDate,
    );
    return TallyPnlReport.fromJson(_dataMap(json));
  }

  Future<TallyBalanceSheet> fetchBalanceSheet() async {
    // The balance sheet is an as-on-today snapshot; it ignores date filters.
    final json =
        await _getResource('report', extra: {'report': 'balance_sheet'});
    return TallyBalanceSheet.fromJson(_dataMap(json));
  }

  /// `type` / `status` map to the voucher_type and sync_status filters.
  Future<TallyVoucherResult> fetchVouchers(
      {String? type, String? status}) async {
    final json = await _getResource('vouchers', extra: {
      if (type != null && type.isNotEmpty) 'type': type,
      if (status != null && status.isNotEmpty) 'status': status,
    });
    return TallyVoucherResult.fromJson(json);
  }

  Future<List<TallyAuditEntry>> fetchAuditLog({int limit = 200}) async {
    final json = await _getResource('audit', extra: {'limit': '$limit'});
    return _dataList(json).map(TallyAuditEntry.fromJson).toList();
  }

  Future<List<TallySyncLogEntry>> fetchSyncLog() async {
    final json = await _getResource('sync_log');
    return _dataList(json).map(TallySyncLogEntry.fromJson).toList();
  }

  Future<List<TallyReconciliationRow>> fetchReconciliation() async {
    final json = await _getResource('reconciliation');
    return _dataList(json).map(TallyReconciliationRow.fromJson).toList();
  }

  Future<TallySettings> fetchSettings() async {
    final json = await _getResource('settings');
    return TallySettings.fromJson(_dataMap(json));
  }

  // -------------------------------------------------------------------------
  // Exports — export.php
  // -------------------------------------------------------------------------

  /// URL for a ledger download. Hand it to `launchUrl` so the browser/OS saves
  /// the attachment; fetching it here would only buffer bytes we can't write.
  Uri buildLedgerExportUri(
    TallyLedger ledger,
    TallyExportFormat format, {
    String? startDate,
    String? endDate,
  }) {
    return ApiConfig.endpoint(TallyEndpoints.export).replace(queryParameters: {
      'resource': 'ledger',
      'ledger': ledger.wire,
      'format': format.wire,
      'actor': actor,
      ..._dateParams(startDate, endDate),
    });
  }

  /// Same, for every managed voucher.
  Uri buildVoucherExportUri(TallyExportFormat format) {
    return ApiConfig.endpoint(TallyEndpoints.export).replace(queryParameters: {
      'resource': 'vouchers',
      'format': format.wire,
      'actor': actor,
    });
  }

  /// `&mode=preview` returns the generated Tally XML inline as plain text
  /// instead of an attachment, for the preview dialog.
  Future<String> previewLedgerXml(
    TallyLedger ledger, {
    String? startDate,
    String? endDate,
  }) {
    final uri =
        ApiConfig.endpoint(TallyEndpoints.export).replace(queryParameters: {
      'resource': 'ledger',
      'ledger': ledger.wire,
      'format': 'xml',
      'mode': 'preview',
      'actor': actor,
      ..._dateParams(startDate, endDate),
    });
    return _getText(uri);
  }

  Future<String> previewVoucherXml() {
    final uri =
        ApiConfig.endpoint(TallyEndpoints.export).replace(queryParameters: {
      'resource': 'vouchers',
      'format': 'xml',
      'mode': 'preview',
      'actor': actor,
    });
    return _getText(uri);
  }

  // -------------------------------------------------------------------------
  // Sync — sync.php
  // -------------------------------------------------------------------------

  /// Pushes a ledger's vouchers into TallyPrime. A [TallySyncResult] with
  /// `isOffline` means Tally wasn't listening — the caller should offer the
  /// XML download instead of reporting a failure.
  Future<TallySyncResult> syncLedger(TallyLedger ledger, {String? gateway}) {
    return _sync({
      'resource': 'ledger',
      'ledger': ledger.wire,
      if (gateway != null && gateway.isNotEmpty) 'gateway': gateway,
    });
  }

  /// Pushes every draft/posted managed voucher, marking them synced on success.
  Future<TallySyncResult> syncVouchers({String? gateway}) {
    return _sync({
      'resource': 'vouchers',
      if (gateway != null && gateway.isNotEmpty) 'gateway': gateway,
    });
  }

  Future<TallySyncResult> _sync(Map<String, dynamic> body) async {
    final json = await _post(
      TallyEndpoints.sync,
      body,
      timeout: _syncTimeout,
      // 'offline' is a documented, non-fatal outcome, so it must not throw.
      allowStatuses: const {'success', 'offline'},
    );
    return TallySyncResult.fromJson(json);
  }

  // -------------------------------------------------------------------------
  // Writes — vouchers.php
  // -------------------------------------------------------------------------

  /// Creates a voucher and returns its new id.
  Future<int> createVoucher(TallyVoucherDraft draft) async {
    final json = await _post(TallyEndpoints.vouchers, {
      'action': 'create',
      ...draft.toJson()..remove('id'),
    });
    return int.tryParse('${json['id']}') ?? 0;
  }

  Future<void> updateVoucher(TallyVoucherDraft draft) async {
    if (draft.id == null) {
      throw TallyIntegrationException('Cannot update a voucher without an id.');
    }
    await _post(
        TallyEndpoints.vouchers, {'action': 'update', ...draft.toJson()});
  }

  Future<void> deleteVoucher(int id) =>
      _post(TallyEndpoints.vouchers, {'action': 'delete', 'id': id});

  /// Moves a draft voucher to 'posted'.
  Future<void> postVoucher(int id) =>
      _post(TallyEndpoints.vouchers, {'action': 'post', 'id': id});

  /// Builds draft vouchers from a source ledger, skipping references that
  /// already have one. Returns how many were created.
  Future<int> generateVouchers(TallyLedger source) async {
    final json = await _post(
      TallyEndpoints.vouchers,
      {'action': 'generate', 'source': source.wire},
      // Generating walks a whole ledger, so give it more room than a plain write.
      timeout: const Duration(seconds: 45),
    );
    return int.tryParse('${json['created']}') ?? 0;
  }

  /// Persists the integration settings and returns them as stored.
  Future<TallySettings> saveSettings(TallySettings settings) async {
    final json = await _post(TallyEndpoints.vouchers, {
      'action': 'save_settings',
      'settings': settings.toJson(),
    });
    return TallySettings.fromJson(_dataMap(json));
  }

  // -------------------------------------------------------------------------
  // Transport
  // -------------------------------------------------------------------------

  Map<String, String> _dateParams(String? startDate, String? endDate) => {
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      };

  Future<Map<String, dynamic>> _getResource(
    String resource, {
    Map<String, String> extra = const {},
    String? startDate,
    String? endDate,
  }) {
    final uri =
        ApiConfig.endpoint(TallyEndpoints.data).replace(queryParameters: {
      'resource': resource,
      ...extra,
      ..._dateParams(startDate, endDate),
    });
    return _getJson(uri);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response =
        await _send(() => http.get(uri).timeout(ApiConfig.timeout));
    return _decode(decodeServerText(response.bodyBytes), response.statusCode);
  }

  /// Reads a text endpoint (CSV recovery, XML preview). The body is decoded
  /// leniently because the ledger text carries stray CP-1252 bytes that
  /// `http`'s strict UTF-8 decoding would throw on.
  Future<String> _getText(Uri uri) async {
    final response =
        await _send(() => http.get(uri).timeout(ApiConfig.timeout));
    final body = decodeServerText(response.bodyBytes);
    if (response.statusCode != 200) {
      // Errors still come back as JSON even from the file endpoints.
      throw TallyIntegrationException(_errorFrom(body, response.statusCode));
    }
    return body;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = ApiConfig.timeout,
    Set<String> allowStatuses = const {'success'},
  }) async {
    final uri = ApiConfig.endpoint(path);
    final response = await _send(
      () => http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            // The audit trail stamps every write with who did it.
            body: jsonEncode({'actor': actor, ...body}),
          )
          .timeout(timeout),
    );
    return _decode(decodeServerText(response.bodyBytes), response.statusCode,
        allowStatuses: allowStatuses);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on TallyIntegrationException {
      rethrow;
    } catch (e) {
      throw TallyIntegrationException('Could not reach the server: $e');
    }
  }

  /// Every Tally endpoint answers `{"status": ..., "message": ..., "data": ...}`,
  /// and signals failures with a 4xx/5xx *and* `status != success`.
  Map<String, dynamic> _decode(
    String raw,
    int statusCode, {
    Set<String> allowStatuses = const {'success'},
  }) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw TallyIntegrationException(
          'Unexpected response (HTTP $statusCode).');
    }

    final status = json['status']?.toString() ?? '';
    if (!allowStatuses.contains(status)) {
      throw TallyIntegrationException(
        json['message']?.toString() ?? 'Request failed (HTTP $statusCode).',
      );
    }
    return json;
  }

  String _errorFrom(String raw, int statusCode) {
    try {
      final json = jsonDecode(raw);
      if (json is Map && json['message'] != null) {
        return json['message'].toString();
      }
    } catch (_) {}
    return 'Request failed (HTTP $statusCode).';
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> json) =>
      (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};

  List<Map<String, dynamic>> _dataList(Map<String, dynamic> json) =>
      (json['data'] as List? ?? const [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
}
