// lib/features/auditor/services/kyc_service.dart
//
// Adjust the import paths below to match your project structure.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:frontend/core/config/api_config.dart';
import '../../models/auditor_kyc_model.dart';

class KycService {
  KycService._();
  static final KycService instance = KycService._();

  /// Fetches the saved KYC details for [userId]. Returns [KycDetails.empty]
  /// shape data if the user hasn't filled anything in yet (the columns will
  /// just come back empty/null from the backend).
  Future<KycDetails> fetchDetails(String userId) async {
    final uri = ApiConfig.endpoint(AuditorEndpoints.kyc)
        .replace(queryParameters: {'user_id': userId});

    final http.Response response;
    try {
      response = await http.get(uri).timeout(ApiConfig.timeout);
    } catch (e) {
      throw KycServiceException('Could not reach the server: $e');
    }

    if (response.statusCode != 200) {
      throw KycServiceException('Server returned ${response.statusCode}');
    }

    late final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw KycServiceException('Unexpected response from server');
    }

    if (body['status'] != 'success') {
      throw KycServiceException((body['message'] ?? 'Unknown error').toString());
    }

    return KycDetails.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Submits personal + bank details, plus an optional new [document].
  /// Pass [document] only when the user picked a new file this session —
  /// the backend keeps the previously uploaded document if none is sent.
  ///
  /// Returns the updated details. Note the backend's POST response doesn't
  /// include kyc_document, so the caller should merge [document]'s presence
  /// into local state itself (the screen below does this via copyWith).
  Future<KycDetails> submitDetails({
    required String userId,
    required String phone,
    required String address,
    required String aadharNo,
    required String panNo,
    required String bankName,
    required String accountNo,
    required String ifscCode,
    required String branchName,
    XFile? document,
  }) async {
    final uri = ApiConfig.endpoint(AuditorEndpoints.kyc);
    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = userId
      ..fields['phone'] = phone
      ..fields['address'] = address
      ..fields['aadhar_no'] = aadharNo
      ..fields['pan_no'] = panNo
      ..fields['bank_name'] = bankName
      ..fields['account_no'] = accountNo
      ..fields['ifsc_code'] = ifscCode
      ..fields['branch_name'] = branchName;

    if (document != null) {
      final bytes = await document.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('document', bytes, filename: document.name),
      );
    }

    final http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(ApiConfig.timeout);
    } catch (e) {
      throw KycServiceException('Could not reach the server: $e');
    }

    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw KycServiceException('Server returned ${response.statusCode}');
    }

    late final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw KycServiceException('Unexpected response from server');
    }

    if (body['status'] != 'success') {
      throw KycServiceException((body['message'] ?? 'Submission failed').toString());
    }

    return KycDetails.fromJson(body['data'] as Map<String, dynamic>);
  }
}

class KycServiceException implements Exception {
  final String message;
  KycServiceException(this.message);

  @override
  String toString() => message;
}