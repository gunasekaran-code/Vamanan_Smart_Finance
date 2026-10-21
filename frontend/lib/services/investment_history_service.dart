import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/network/api_response.dart';
import 'package:frontend/models/investment_history_model.dart';

class InvestmentHistoryEndpoints {
  InvestmentHistoryEndpoints._();

  static const String history = 'admin/investment_history.php';

  /// NOTE: this endpoint does not exist in the backend yet — add
  /// api/admin/delete_investment_history.php (DELETE the cashback_cycles
  /// row, or soft-delete it) for the delete button to actually persist.
  static const String delete = 'admin/delete_investment_history.php';
}

class InvestmentHistoryService {
  InvestmentHistoryService._();
  static final InvestmentHistoryService instance = InvestmentHistoryService._();

  final ApiClient _client = ApiClient.instance;

  /// READ — all processed (non-pending) cashback cycles.
  Future<ApiResponse<List<InvestmentHistoryRecord>>> fetchHistory() async {
    try {
      return await _client.post<List<InvestmentHistoryRecord>>(
        InvestmentHistoryEndpoints.history,
        body: const {},
        parser: (json) {
          final rows = (json['data'] as List?) ?? const [];
          return rows
              .map(
                (e) => InvestmentHistoryRecord.fromJson(
                  (e as Map).cast<String, dynamic>(),
                ),
              )
              .toList();
        },
      );
    } on ApiException catch (e) {
      return ApiResponse<List<InvestmentHistoryRecord>>.failure(e.message);
    }
  }

  /// DELETE — removes an audit record. Requires the backend endpoint
  /// noted above; until it exists this will return a failure response.
  Future<ApiResponse<void>> deleteRecord(int cycleId) async {
    try {
      return await _client.post<void>(
        InvestmentHistoryEndpoints.delete,
        body: {'cycle_id': cycleId},
      );
    } on ApiException catch (e) {
      return ApiResponse<void>.failure(e.message);
    }
  }
}