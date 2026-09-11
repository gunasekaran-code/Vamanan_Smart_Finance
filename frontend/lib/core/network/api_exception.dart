/// Raised when a request never produced a usable JSON envelope — no network,
/// a dead host, a timeout, an HTML error page from Apache, a PHP fatal.
///
/// Business-level failures ("Incorrect password") are *not* exceptions: the
/// backend reports those as `{"status":"error"}` with HTTP 200, so they come
/// back as an unsuccessful [ApiResponse] instead.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// The raw body, kept only to make debugging a misbehaving endpoint easier.
  final String? body;

  const ApiException(this.message, {this.statusCode, this.body});

  factory ApiException.network() => const ApiException(
        'Could not reach the server. Check your connection and try again.',
      );

  factory ApiException.timeout() => const ApiException(
        'The server took too long to respond. Please try again.',
      );

  factory ApiException.badResponse({int? statusCode, String? body}) =>
      ApiException(
        'The server returned an unexpected response.',
        statusCode: statusCode,
        body: body,
      );

  @override
  String toString() => 'ApiException($message)';
}
