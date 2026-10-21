import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/network/api_response.dart';
import 'package:frontend/models/investment_model.dart';

class InvestmentEndpoints {
  InvestmentEndpoints._();

  static const String pending = 'admin/investments.php';
  static const String history = 'admin/investment_history.php';
  static const String approve = 'admin/approve_investment.php';
  static const String reject = 'admin/reject_investment.php';
}

class InvestmentService {
  InvestmentService._();
  static final InvestmentService instance = InvestmentService._();

  final ApiClient _client = ApiClient.instance;

  /// READ — pending gold/asset requests awaiting admin action.
  Future<ApiResponse<List<InvestmentRequest>>> fetchPending() {
    return _fetchList(InvestmentEndpoints.pending);
  }

  /// READ — already-processed (approved/rejected/completed) requests.
  Future<ApiResponse<List<InvestmentRequest>>> fetchHistory() {
    return _fetchList(InvestmentEndpoints.history);
  }

  Future<ApiResponse<List<InvestmentRequest>>> _fetchList(
    String endpoint,
  ) async {
    try {
      return await _client.post<List<InvestmentRequest>>(
        endpoint,
        body: const {},
        parser: (json) {
          final rows = (json['data'] as List?) ?? const [];
          return rows
              .map(
                (e) => InvestmentRequest.fromJson(
                  (e as Map).cast<String, dynamic>(),
                ),
              )
              .toList();
        },
      );
    } on ApiException catch (e) {
      return ApiResponse<List<InvestmentRequest>>.failure(e.message);
    }
  }

  /// UPDATE — authorize/activate a pending request.
  Future<ApiResponse<void>> approve(int cycleId) {
    return _mutate(InvestmentEndpoints.approve, cycleId);
  }

  /// UPDATE — reject a pending request, with an optional reason.
  Future<ApiResponse<void>> reject(int cycleId, {String? reason}) {
    return _mutate(
      InvestmentEndpoints.reject,
      cycleId,
      extra: {
        if (reason != null && reason.trim().isNotEmpty)
          'reason': reason.trim(),
      },
    );
  }

  Future<ApiResponse<void>> _mutate(
    String endpoint,
    int cycleId, {
    Map<String, dynamic>? extra,
  }) async {
    try {
      return await _client.post<void>(
        endpoint,
        body: {
          'cycle_id': cycleId,
          ...?extra,
        },
      );
    } on ApiException catch (e) {
      return ApiResponse<void>.failure(e.message);
    }
  }
}