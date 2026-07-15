import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../constants/app_strings.dart';
import '../constants/security_limits.dart';

/// SINGLE SOURCE OF TRUTH for error classification.
///
/// Replaces:
/// - Duplicate `_classifyError` in api_client.dart:169-198
/// - Duplicate `_classifyError` in task_repository.dart:255-284
/// - Raw exception leakage in session_provider, chat_provider, stream_provider
///
/// CONTRACT (see README.md):
/// 1. All DioException objects pass through [classifyDioError]
/// 2. All user-facing error messages pass through [sanitizeMessage]
/// 3. [isRetryable] determines whether the caller should retry
///
/// SECURITY: [sanitizeMessage] NEVER exposes raw server data.
/// Use [toDebugMessage] for debug logging (debug-mode only).
class ErrorClassifier {
  ErrorClassifier._();

  // ─── Classification ───

  /// Classify a DioException into a typed [ApiException].
  ///
  /// This is the single entry point for all API error handling.
  /// Every catch block that catches DioException MUST call this.
  ///
  /// Returns the appropriate [ApiException] subtype:
  /// - [ConnectionException] — network/timeout errors
  /// - [AuthException] — 401 Unauthorized
  /// - [ServerException] — 5xx server errors
  /// - [ClientException] — 4xx client errors (except 401)
  /// - [PayloadTooLargeException] — response exceeds size limit
  /// - [StreamException] — SSE stream errors
  static ApiException classifyDioError(DioException error) {
    final message = error.message ?? 'Unknown error';
    final statusCode = error.response?.statusCode;
    final body = error.response?.data?.toString();

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ConnectionException(message,
            statusCode: statusCode, responseBody: body);

      case DioExceptionType.badResponse:
        // Check for payload-too-large first (rejected by _SizeLimitInterceptor).
        if (message.contains('Response body too large')) {
          return PayloadTooLargeException(
            maxAllowedBytes: SecurityLimits.maxJsonResponseSize,
            actualBytes: body?.length ?? 0,
          );
        }

        if (statusCode == 401) {
          return AuthException(message,
              statusCode: statusCode, responseBody: body);
        }
        if (statusCode != null && statusCode >= 500) {
          return ServerException(message,
              statusCode: statusCode, responseBody: body);
        }
        return ClientException(message,
            statusCode: statusCode, responseBody: body);

      default:
        return ConnectionException(message,
            statusCode: statusCode, responseBody: body);
    }
  }

  // ─── User-Facing Sanitization ───

  /// Convert any exception into a user-safe error message.
  ///
  /// NEVER exposes raw server data, stack traces, or API keys to the user.
  /// Use this for ALL error messages shown in the UI (toasts, error states,
  /// chat bubbles).
  ///
  /// Returns a short, localized-ready string suitable for UI display.
  static String sanitizeMessage(Object error) {
    if (error is ApiException) {
      return _sanitizeApiException(error);
    }

    if (error is DioException) {
      final classified = classifyDioError(error);
      return _sanitizeApiException(classified);
    }

    // Catch-all for unknown exceptions — generic, safe message.
    if (kDebugMode) {
      debugPrint(
        '=== HERMEX DEBUG: ErrorClassifier.sanitizeMessage — unknown type: ${error.runtimeType} ===');
    }
    return AppStrings.unexpectedError;
  }

  /// Sanitize a typed [ApiException] to a user-safe message.
  static String _sanitizeApiException(ApiException exception) {
    switch (exception) {
      case ConnectionException():
        return AppStrings.connectionFailedWithHint;
      case AuthException():
        return AppStrings.authFailed;
      case ServerException():
        final code = exception.statusCode;
        if (code == 502) {
          return AppStrings.serverTemporarilyUnavailable;
        }
        if (code == 503) {
          return AppStrings.serverOverloaded;
        }
        return AppStrings.serverErrorGeneric;
      case ClientException():
        final code = exception.statusCode;
        if (code == 404) {
          return AppStrings.resourceNotFound;
        }
        if (code == 429) {
          return AppStrings.tooManyRequests;
        }
        return AppStrings.requestFailed;
      case PayloadTooLargeException():
        return AppStrings.responseTooLarge;
      case StreamException():
        return AppStrings.streamInterrupted;
      case ContentTruncatedException():
        return AppStrings.contentTruncatedForSafety;
      default:
        return AppStrings.unexpectedError;
    }
  }

  // ─── Debug Message ───

  /// Full diagnostic string for debug logging ONLY.
  /// INCLUDES status codes and error types — NEVER display to user.
  static String toDebugMessage(Object error) {
    if (error is ApiException) {
      return error.toDebugString();
    }
    if (error is DioException) {
      final classified = classifyDioError(error);
      return classified.toDebugString();
    }
    return '$error';
  }

  // ─── Retryability ───

  /// Whether the given error is potentially retryable.
  ///
  /// Retryable: timeouts, server errors (5xx), rate limiting (429).
  /// Not retryable: auth errors (401), client errors (4xx), payload too large.
  static bool isRetryable(Object error) {
    if (error is ApiException) {
      return error is ConnectionException || error is ServerException;
    }
    if (error is DioException) {
      return isRetryable(classifyDioError(error));
    }
    return false;
  }
}
