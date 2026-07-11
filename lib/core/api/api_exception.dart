/// Typed exceptions for API operations.
/// Catches and categorizes all failure modes from the Hermes Agent API Server.
///
/// SECURITY: [toString()] must NEVER expose [responseBody] or raw server data.
/// Use [toDebugString()] for debug logging (debug-mode only).
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  const ApiException(this.message, {this.statusCode, this.responseBody});

  /// User-safe representation. Returns only status code — never raw server data.
  /// UI error handlers should display this, not [message] or [responseBody].
  @override
  String toString() {
    final code = statusCode;
    if (code != null) {
      return 'Request failed (status: $code)';
    }
    return 'Request failed (no response)';
  }

  /// Full diagnostic string for debug logging only.
  /// INCLUDES [message] and [responseBody] — NEVER display to user.
  String toDebugString() {
    final buf = StringBuffer('$runtimeType: $message');
    if (statusCode != null) {
      buf.write(' (status: $statusCode)');
    }
    if (responseBody != null && responseBody!.isNotEmpty) {
      buf.write(' body: $responseBody');
    }
    return buf.toString();
  }
}

/// Server unreachable — DNS failure, timeout, network error.
class ConnectionException extends ApiException {
  const ConnectionException(super.message, {super.statusCode, super.responseBody});
}

/// Authentication failure — 401 Unauthorized from the API server.
class AuthException extends ApiException {
  const AuthException(super.message, {super.statusCode, super.responseBody});
}

/// Server-side error — 500, 502, 503 from the API server.
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode, super.responseBody});
}

/// Client error — 400 Bad Request, 404 Not Found, etc.
class ClientException extends ApiException {
  const ClientException(super.message, {super.statusCode, super.responseBody});
}

/// SSE stream connection error.
class StreamException extends ApiException {
  const StreamException(super.message, {super.statusCode, super.responseBody});
}

/// Payload too large — response body exceeds configured [SecurityLimits.maxJsonResponseSize].
/// AUD-006: Prevents OOM from oversized server responses.
class PayloadTooLargeException extends ApiException {
  final int maxAllowedBytes;
  final int actualBytes;

  const PayloadTooLargeException({
    required this.maxAllowedBytes,
    required this.actualBytes,
  }) : super(
          'Response body exceeds maximum allowed size '
          '($actualBytes bytes > $maxAllowedBytes bytes limit)',
        );

  @override
  String toString() =>
      'Request failed (payload too large)';

  @override
  String toDebugString() =>
      'PayloadTooLargeException: $message (max: $maxAllowedBytes, actual: $actualBytes)';
}

/// Data too large for UI rendering — content truncated for safety.
/// AUD-006: Prevents rendering oversized text deltas.
class ContentTruncatedException extends ApiException {
  final int maxAllowedCharacters;
  final int actualCharacters;

  const ContentTruncatedException({
    required this.maxAllowedCharacters,
    required this.actualCharacters,
  }) : super(
          'Content truncated from $actualCharacters to $maxAllowedCharacters characters',
        );
}
