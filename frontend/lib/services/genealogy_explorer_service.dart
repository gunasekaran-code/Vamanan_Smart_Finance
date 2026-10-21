import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../models/genealogy_explorer_model.dart';

/// Thrown for any failure talking to the genealogy backend — network error,
/// non-200 response, or a `{"status":"error", ...}` payload. [message] is
/// safe to show directly to the user.
class GenealogyServiceException implements Exception {
  final String message;
  GenealogyServiceException(this.message);

  @override
  String toString() => message;
}

/// Talks to `api/admin/get_genealogy.php` and the monthly-yield action.
///
/// The backend is read-oriented: genealogy nodes are users created via
/// registration/referral elsewhere in the system, so this service exposes
/// no create/delete for nodes themselves — only:
///   - READ  fetchRootUsers() / fetchDownline()
///   - UPDATE processMonthlyYield() (credits the monthly cashback cycle)
class GenealogyService {
  /// Top-level investors (users with no referrer). Mirrors the backend's
  /// "no user_id" branch.
  Future<List<GenealogyNode>> fetchRootUsers() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.genealogyTree);
    return _fetchList(uri);
  }

  /// Full downline tree (backend caps recursion at 5 levels) for [userId],
  /// including per-node investment/earning stats.
  Future<List<GenealogyNode>> fetchDownline(String userId) async {
    final uri = ApiConfig.endpoint(AdminEndpoints.genealogyTree)
        .replace(queryParameters: {'user_id': userId});
    return _fetchList(uri);
  }

  /// Credits one monthly (10%) cashback installment to every due cycle.
  /// Returns the server's success message.
  ///
  /// NOTE: no endpoint for this action was provided alongside
  /// `get_genealogy.php`. This assumes
  /// `AdminEndpoints.processMonthlyYield` — update that constant (and the
  /// PHP filename) to match whatever your backend actually exposes.
  Future<String> processMonthlyYield() async {
    final uri = ApiConfig.endpoint(AdminEndpoints.processMonthlyYield);
    try {
      final response = await http.post(uri).timeout(ApiConfig.timeout);
      final body = _decode(response);

      if (response.statusCode != 200 || body['status'] != 'success') {
        throw GenealogyServiceException(
          body['message']?.toString() ?? 'Failed to process monthly yield.',
        );
      }
      return body['message']?.toString() ?? 'Monthly yield processed.';
    } on GenealogyServiceException {
      rethrow;
    } catch (_) {
      throw GenealogyServiceException(
        'Could not reach the server. Please try again.',
      );
    }
  }

  Future<List<GenealogyNode>> _fetchList(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(ApiConfig.timeout);
      final body = _decode(response);

      if (response.statusCode != 200 || body['status'] != 'success') {
        throw GenealogyServiceException(
          body['message']?.toString() ?? 'Failed to load genealogy data.',
        );
      }

      final data = body['data'] as List<dynamic>? ?? const [];
      return data
          .map((e) => GenealogyNode.fromJson(e as Map<String, dynamic>))
          .toList();
    } on GenealogyServiceException {
      rethrow;
    } catch (_) {
      throw GenealogyServiceException(
        'Could not reach the server. Please try again.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw GenealogyServiceException('Unexpected response from server.');
    }
  }
}