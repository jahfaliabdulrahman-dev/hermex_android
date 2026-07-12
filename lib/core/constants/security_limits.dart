/// Centralized security limits for input injection protection.
///
/// AUD-006: Prevents OOM and unbounded resource consumption from
/// oversized payloads in SSE streams, JSON responses, and text deltas.
abstract class SecurityLimits {
  SecurityLimits._();

  /// Maximum size in bytes for a single SSE event before parsing.
  /// Events exceeding this are rejected with an error event.
  /// 5 MB accommodates large tool call responses (file reads, code exec).
  static const int maxSseEventSize = 5 * 1024 * 1024; // 5 MB

  /// Maximum size in bytes for a JSON HTTP response body.
  /// Responses exceeding this are rejected with [PayloadTooLargeException].
  /// 10 MB covers all legitimate API responses.
  static const int maxJsonResponseSize = 10 * 1024 * 1024; // 10 MB

  /// Maximum length in characters for a single TextDelta content string.
  /// Deltas exceeding this are truncated before reaching the UI layer.
  /// 50 KB is far beyond any reasonable single delta.
  static const int maxTextDeltaSize = 50 * 1024; // 50 KB
}
