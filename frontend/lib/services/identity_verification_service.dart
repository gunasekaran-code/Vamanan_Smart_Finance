import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';

import '../models/identity_verification_model.dart';

/// Backs the manager's Identity Verification register.
///
/// The screen used to call `admin/kyc_requests.php` and
/// `admin/update_kyc_status.php`; neither is deployed (both 404), which is why
/// nothing ever loaded. KYC is stored on the `users` table, so every operation
/// here goes through endpoints that do exist — see [KycEndpoints].
///
///   READ   list    GET  admin/all_users.php
///   READ   detail  GET  customer/kyc.php?user_id=N
///   CREATE/UPDATE  POST customer/kyc.php          (multipart, + document)
///   UPDATE status  POST admin/update_user.php     ({id, kyc_status})
///   DELETE         — reopening a decision is `kyc_status` back to 'pending';
///                    see [reopen]. Nothing on the server erases a KYC record.
class IdentityVerificationService {
  IdentityVerificationService._();
  static final IdentityVerificationService instance =
      IdentityVerificationService._();

  // ---------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------

  /// Every user that has a KYC state, newest first.
  ///
  /// `all_users.php` has no status parameter, so [filter] is applied here.
  /// The unfiltered list is what the screen counts its tabs from, so it asks
  /// for [IdentityFilter.all] and slices the result itself.
  Future<List<IdentityRequest>> fetchRequests({
    IdentityFilter filter = IdentityFilter.all,
  }) async {
    final body = await _getJson(ApiConfig.endpoint(KycEndpoints.list));

    final rows = (body['data'] ?? body['users'] ?? const []) as List<dynamic>;
    final all = rows
        .map((e) =>
            IdentityRequest.fromListJson((e as Map).cast<String, dynamic>()))
        .toList();

    // Newest submission first; rows without a date sort last.
    all.sort((a, b) {
      final x = a.submittedAt;
      final y = b.submittedAt;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return y.compareTo(x);
    });

    return all.where(filter.matches).toList();
  }

  /// The KYC detail fields for one user, folded onto [request].
  ///
  /// `all_users.php` carries only the status and the document path, so the
  /// Aadhaar, PAN, address and bank fields have to be read per user — which is
  /// why the review sheet used to show 'N/A' for all of them.
  Future<IdentityRequest> fetchDetails(IdentityRequest request) async {
    final uri = ApiConfig.endpoint(KycEndpoints.details)
        .replace(queryParameters: {'user_id': request.id});
    final body = await _getJson(uri);
    final data = (body['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    return request.withDetails(data);
  }

  // ---------------------------------------------------------------------
  // Update — verification decisions
  // ---------------------------------------------------------------------

  Future<void> approve(String userId) => updateStatus(userId, 'verified');

  Future<void> reject(String userId) => updateStatus(userId, 'rejected');

  /// Puts a decided request back in the queue. This is as close to a delete as
  /// the server offers: no endpoint clears `kyc_document` or the KYC columns.
  Future<void> reopen(String userId) => updateStatus(userId, 'pending');

  /// POST `admin/update_user.php` — the only endpoint that can set
  /// `kyc_status` without also rewriting the user's KYC details.
  Future<void> updateStatus(String userId, String status) async {
    final response = await _send(
      () => http
          .post(
            ApiConfig.endpoint(KycEndpoints.updateStatus),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'id': userId, 'kyc_status': status}),
          )
          .timeout(ApiConfig.timeout),
    );
    _decode(response, 'Failed to update the verification status.');
  }

  // ---------------------------------------------------------------------
  // Create / update — the KYC record itself
  // ---------------------------------------------------------------------

  /// Writes a user's KYC details, with an optional document.
  ///
  /// `customer/kyc.php` takes multipart form fields (not JSON) and always
  /// resets `kyc_status` to 'pending', so saving details re-queues the user
  /// for review. It writes whatever it is given, so callers should pass the
  /// current values for fields they are not changing — a blank string clears
  /// the column.
  ///
  /// [documentBytes]/[documentFilename] attach the file the endpoint stores
  /// under `uploads/kyc/` and records in `kyc_document`.
  Future<IdentityRequest> saveDetails({
    required IdentityRequest request,
    String? phone,
    String? address,
    String? aadharNo,
    String? panNo,
    String? bankName,
    String? accountNo,
    String? ifscCode,
    String? branchName,
    List<int>? documentBytes,
    String? documentFilename,
  }) async {
    final multipart =
        http.MultipartRequest('POST', ApiConfig.endpoint(KycEndpoints.details))
          ..fields.addAll({
            'user_id': request.id,
            'phone': phone ?? request.phone ?? '',
            'address': address ?? request.address ?? '',
            'aadhar_no': aadharNo ?? request.aadharNo ?? '',
            'pan_no': panNo ?? request.panNo ?? '',
            'bank_name': bankName ?? request.bankName ?? '',
            'account_no': accountNo ?? request.accountNo ?? '',
            'ifsc_code': ifscCode ?? request.ifscCode ?? '',
            'branch_name': branchName ?? request.branchName ?? '',
          });

    if (documentBytes != null && documentBytes.isNotEmpty) {
      multipart.files.add(http.MultipartFile.fromBytes(
        'document',
        documentBytes,
        filename: documentFilename ?? 'kyc_${request.id}.jpg',
      ));
    }

    final response = await _send(() async {
      final streamed = await multipart.send().timeout(ApiConfig.timeout);
      return http.Response.fromStream(streamed);
    });

    final body = _decode(response, 'Failed to save the KYC details.');
    final data = (body['data'] as Map?)?.cast<String, dynamic>();
    // The endpoint echoes the stored row back, so the caller gets what the
    // server actually kept rather than what was sent.
    return data == null ? request : request.withDetails(data);
  }

  // ---------------------------------------------------------------------
  // Transport
  // ---------------------------------------------------------------------

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response =
        await _send(() => http.get(uri).timeout(ApiConfig.timeout));
    return _decode(response, 'Failed to load the verification register.');
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on IdentityVerificationException {
      rethrow;
    } catch (e) {
      throw IdentityVerificationException('Could not reach the server: $e');
    }
  }

  /// These endpoints answer `{"status": ..., "message": ..., "data": ...}`.
  /// A 404 arrives as an HTML error page, so the decode failure is reported
  /// with the URL — that is what made the old dead endpoints so hard to read.
  Map<String, dynamic> _decode(http.Response response, String fallback) {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      if (response.statusCode == 404) {
        throw IdentityVerificationException(
          'Endpoint not found on the server (HTTP 404): '
          '${response.request?.url}',
        );
      }
      throw IdentityVerificationException(
        'Unexpected response (HTTP ${response.statusCode}).',
      );
    }

    if (body['status'] != 'success') {
      throw IdentityVerificationException(
        body['message']?.toString() ?? fallback,
      );
    }
    return body;
  }
}
