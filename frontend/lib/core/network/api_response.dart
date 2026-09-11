/// The shape every endpoint in `api/` replies with:
/// `{"status": "success"|"error", "message": "...", ...payload}`.
///
/// Note the backend answers HTTP 200 even for rejected credentials, so
/// [success] — not the status code — is what callers must branch on.
class ApiResponse<T> {
  final bool success;
  final String message;

  /// The typed payload, produced by the parser passed to [ApiClient.post].
  /// Null on failures, and on successes for endpoints that only return a
  /// message.
  final T? data;

  /// The full decoded body, for the odd field a caller needs that the typed
  /// model doesn't carry.
  final Map<String, dynamic> raw;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.raw = const {},
  });

  factory ApiResponse.failure(String message) =>
      ApiResponse<T>(success: false, message: message);

  /// Builds a response from a decoded body, running [parser] over it only
  /// when the backend reported success.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Map<String, dynamic> json)? parser,
  }) {
    final success = (json['status'] ?? '').toString().toLowerCase() == 'success';
    return ApiResponse<T>(
      success: success,
      message: (json['message'] ?? (success ? 'Success' : 'Something went wrong.'))
          .toString(),
      data: success && parser != null ? parser(json) : null,
      raw: json,
    );
  }
}
