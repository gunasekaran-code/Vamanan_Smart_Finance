import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';

import '../../models/advocate_archive_model.dart';

class AdvocateArchiveService {
  static const Duration _timeout = Duration(seconds: 20);

  // Statuses treated as "approved" for the archive. `stats.php` itself
  // counts 'ratified' and 'active' as active_agreements — adjust this set
  // if your actual status values differ (e.g. add 'approved').
  static const Set<String> _approvedStatuses = {
    'ratified',
    'active',
    'approved'
  };

  /// Fetches only the agreements considered "approved" for the archive screen.
  static Future<List<AgreementArchiveItem>> fetchApprovedAgreements() async {
    final all = await _fetchAllAgreements();
    return all
        .where((a) => _approvedStatuses.contains(a.status.toLowerCase()))
        .toList();
  }

  /// Fetches one agreement by its `agreements.id`, or throws if it no
  /// longer exists. stats.php has no single-row endpoint, so this filters
  /// the full list.
  static Future<AgreementArchiveItem> fetchAgreementById(int id) async {
    final all = await _fetchAllAgreements();
    for (final a in all) {
      if (a.id == id) return a;
    }
    throw AdvocateArchiveException('Agreement #$id was not found.');
  }

  /// Fetches every agreement, unfiltered, in case you need it elsewhere.
  static Future<List<AgreementArchiveItem>> fetchAllAgreements() =>
      _fetchAllAgreements();

  static Future<List<AgreementArchiveItem>> _fetchAllAgreements() async {
    final uri = ApiConfig.endpoint(AdvocateEndpoints.dashboardStats);

    late final http.Response response;
    try {
      response = await http.get(uri).timeout(_timeout);
    } catch (e) {
      throw AdvocateArchiveException('Could not reach the server: $e');
    }

    if (response.statusCode != 200) {
      throw AdvocateArchiveException(
          'Server returned HTTP ${response.statusCode}');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw AdvocateArchiveException('Could not parse server response');
    }

    if (decoded['status'] != 'success') {
      throw AdvocateArchiveException(
          (decoded['message'] ?? 'Failed to load agreements').toString());
    }

    final data = decoded['data'] as Map<String, dynamic>?;
    final List<dynamic> agreementsJson =
        (data?['agreements'] as List<dynamic>?) ?? [];

    return agreementsJson
        .map((a) => AgreementArchiveItem.fromJson(a as Map<String, dynamic>))
        .toList();
  }
}

class AdvocateArchiveException implements Exception {
  final String message;
  AdvocateArchiveException(this.message);

  @override
  String toString() => message;
}
