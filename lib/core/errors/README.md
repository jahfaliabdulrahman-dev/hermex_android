# Error Classification Contract

## Single Source of Truth

**File:** `lib/core/errors/error_classifier.dart`
**Class:** `ErrorClassifier` (static utility — no instantiation needed)

## Purpose

Replaces three divergent error-handling paths with one unified classifier:

| Before (Broken) | After (Fixed) |
|---|---|
| `api_client.dart:59-68` onError interceptor — classifies then DISCARDs | `ErrorClassifier.classifyDioError()` |
| `api_client.dart:169-198` `_classifyError` — correct but private | `ErrorClassifier.classifyDioError()` |
| `task_repository.dart:255-284` `_classifyError` — duplicate | `ErrorClassifier.classifyDioError()` |
| Raw `$e` / `error.toString()` in session/chat/stream providers | `ErrorClassifier.sanitizeMessage()` |

## Classification Logic

### DioExceptionType → ApiException Mapping

| DioExceptionType | Condition | ApiException |
|---|---|---|
| `connectionTimeout` | — | `ConnectionException` |
| `sendTimeout` | — | `ConnectionException` |
| `receiveTimeout` | — | `ConnectionException` |
| `connectionError` | — | `ConnectionException` |
| `badResponse` | message contains "Response body too large" | `PayloadTooLargeException` |
| `badResponse` | statusCode == 401 | `AuthException` |
| `badResponse` | statusCode >= 500 | `ServerException` |
| `badResponse` | other 4xx | `ClientException` |
| `cancel` | — | `ConnectionException` |
| other | — | `ConnectionException` |

## User-Facing Messages

`sanitizeMessage()` returns short, safe strings for UI display. Never exposes:
- Raw server response body
- Stack traces
- API keys
- Internal hostnames/URLs
- Debug technical details

### Message Table

| Exception Type | Status Code | User Message |
|---|---|---|
| `ConnectionException` | any | "Connection failed. Check your network and server URL." |
| `AuthException` | 401 | "Authentication failed. Please check your API key." |
| `ServerException` | 502 | "Server is temporarily unavailable. Please try again." |
| `ServerException` | 503 | "Server is overloaded. Please wait and try again." |
| `ServerException` | other 5xx | "Server error occurred. Please try again later." |
| `ClientException` | 404 | "The requested resource was not found." |
| `ClientException` | 429 | "Too many requests. Please wait before trying again." |
| `ClientException` | other 4xx | "Request failed. Please check your input and try again." |
| `PayloadTooLargeException` | any | "Response was too large to display." |
| `StreamException` | any | "Stream connection was interrupted. Please reconnect." |
| Unknown / non-ApiException | any | "An unexpected error occurred. Please try again." |

## API (Public Interface)

```dart
/// Classify a DioException into a typed ApiException.
static ApiException classifyDioError(DioException error)

/// Convert any exception into a user-safe error message for UI display.
static String sanitizeMessage(Object error)

/// Full diagnostic string for debug logging ONLY. NEVER display to user.
static String toDebugMessage(Object error)

/// Whether the error is potentially retryable.
static bool isRetryable(Object error)
```

## Usage Pattern

### In api_client interceptor (onError):

```dart
onError: (error, handler) {
  final exception = ErrorClassifier.classifyDioError(error);
  if (kDebugMode) {
    debugPrint('=== HERMEX DEBUG: ${ErrorClassifier.toDebugMessage(error)} ===');
  }
  // Return a DioException wrapping the classified exception so that
  // downstream catch blocks can catch AuthException/ConnectionException etc.
  handler.reject(
    DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: error.type,
      message: exception.message,
      error: exception, // Store classified exception on the DioException
    ),
    true,
  );
},
```

### In repository catch blocks:

```dart
try {
  // ... API call ...
} on DioException catch (e) {
  throw ErrorClassifier.classifyDioError(e);
}
```

### In provider catch blocks (UI-facing):

```dart
try {
  // ... repository call ...
} catch (e) {
  state = state.copyWith(
    errorMessage: ErrorClassifier.sanitizeMessage(e),
  );
}
```

## Security Rules

1. `sanitizeMessage()` NEVER returns raw server data
2. All debug output uses `toDebugMessage()` — gated behind `kDebugMode`
3. No raw `$e` interpolation in error messages shown to the user
4. No `error.toString()` used in UI (stream_provider, chat_provider, etc.)

## Migration Path

1. Replace `api_client.dart:169` `_classifyError` → `ErrorClassifier.classifyDioError`
2. Replace `task_repository.dart:255` `_classifyError` → `ErrorClassifier.classifyDioError`
3. Fix `api_client.dart:59-68` onError to REJECT with classified exception
4. Replace raw `$e` interpolation in session_provider → `ErrorClassifier.sanitizeMessage(e)`
5. Replace raw `$e` interpolation in chat_provider → `ErrorClassifier.sanitizeMessage(e)`
6. Replace `error.toString()` in stream_provider → `ErrorClassifier.sanitizeMessage(error)`

## Traceability

- **Feature ID:** HERMEX-008 (RC6 Remediation)
- **Defects:** A.1, A.2, A.3, A.4, A.5
- **Security Rules:** SR-001 (no raw server data in UI), SR-002 (debug-only diagnostics)
- **Decision IDs:** DEC-034 (Anti-Ghost Protocol), DEC-EPIC001 (Error Architecture)
