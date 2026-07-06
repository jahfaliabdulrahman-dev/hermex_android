import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/stream_event.dart';
import '../constants/security_limits.dart';
import 'api_exception.dart';

/// Raw HTTP SSE (Server-Sent Events) streaming client for Hermes Agent API Server.
///
/// Uses dart:io HttpClient for low-level streaming control.
/// Parses SSE format: "data: {...}\n\n" and emits [StreamEvent] objects.
///
/// Usage:
/// ```dart
/// final sseClient = SseClient(baseUrl: 'http://192.168.1.100:8642');
/// final subscription = sseClient
///     .connect('/api/sessions/abc/chat/stream', apiKey: 'sk-...')
///     .listen((event) { ... });
/// // Later: subscription.cancel();
/// ```
class SseClient {
  final String baseUrl;

  HttpClient? _httpClient;
  bool _isDisposed = false;

  SseClient({required this.baseUrl});

  /// Connect to an SSE endpoint and return a [Stream] of [StreamEvent] objects.
  ///
  /// [path] — API path (e.g., "/api/sessions/{id}/chat/stream")
  /// [apiKey] — Bearer token for Authorization header
  /// [body] — optional JSON request body (for POST-based SSE)
  Stream<StreamEvent> connect(
    String path, {
    required String apiKey,
    Map<String, dynamic>? body,
  }) async* {
    if (_isDisposed) {
      throw StreamException('SseClient has been disposed');
    }

    _httpClient = HttpClient();
    final uri = Uri.parse('$baseUrl$path');

    try {
      final request = await _httpClient!.openUrl(
        body != null ? 'POST' : 'GET',
        uri,
      );

      request.headers.set('Authorization', 'Bearer $apiKey');
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');

      if (body != null) {
        request.headers.set('Content-Type', 'application/json');
        request.write(jsonEncode(body));
      }

      final response = await request.close();

      if (response.statusCode != 200) {
        final errorBody = await response.transform(utf8.decoder).join();
        if (kDebugMode) {
          debugPrint(
              '=== HERMEX DEBUG: SSE connection failed — ${response.statusCode}: $errorBody ===');
        }
        throw StreamException(
          'SSE connection failed with status ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: errorBody,
        );
      }
      if (kDebugMode) {
        debugPrint(
            '=== HERMEX DEBUG: SSE connected to $path ===');
      }
      // Parse SSE stream line by line.
      final lines =
          response.transform(utf8.decoder).transform(const LineSplitter());

      String currentData = '';

      await for (final line in lines) {
        if (_isDisposed) break;

        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') {
            yield const StreamEvent.done();
            currentData = '';
            continue;
          }
          currentData = data;
        } else if (line.isEmpty && currentData.isNotEmpty) {
          // Empty line = end of event block. Parse and emit.
          final event = _parseEvent(currentData);
          if (event != null) yield event;
          currentData = '';
        }
        // Other lines (event:, id:, retry:) are ignored for now.
      }
    } on StreamException {
      rethrow;
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint('=== HERMEX DEBUG: SSE socket error — $e ===');
      }
      throw StreamException('Connection lost: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('=== HERMEX DEBUG: SSE unexpected error — $e ===');
      }
      throw StreamException('Unexpected SSE error: $e');
    } finally {
      _httpClient?.close();
      _httpClient = null;
    }
  }

  /// Cancel an active SSE connection.
  void cancel() {
    if (kDebugMode) {
      debugPrint('=== HERMEX DEBUG: SSE cancel requested ===');
    }
    _isDisposed = true;
    _httpClient?.close(force: true);
    _httpClient = null;
  }

  /// Dispose the client — cancel all connections and release resources.
  void dispose() {
    cancel();
  }

  // ─── SSE Parsing ───

  StreamEvent? _parseEvent(String data) {
    // AUD-006: Reject oversized SSE events before parsing.
    if (data.length > SecurityLimits.maxSseEventSize) {
      if (kDebugMode) {
        debugPrint(
            '=== HERMEX DEBUG: SSE event rejected — size ${data.length} exceeds '
            'limit ${SecurityLimits.maxSseEventSize} ===');
      }
      return const StreamEvent.error(
        message: 'SSE event too large',
        code: 'PAYLOAD_TOO_LARGE',
      );
    }

    try {
      final json = jsonDecode(data) as Map<String, dynamic>;

      // Chat Completions format: choices[0].delta.content
      if (json.containsKey('choices')) {
        final choices = json['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final delta = choices[0]['delta'] as Map<String, dynamic>?;
          if (delta != null && delta.containsKey('content')) {
            final content = delta['content'] as String?;
            if (content != null && content.isNotEmpty) {
              return StreamEvent.textDelta(text: content);
            }
          }
        }
        return null; // skip empty deltas (finish_reason, etc.)
      }

      // Responses API format: response.output_text.delta
      if (json.containsKey('response')) {
        final response = json['response'] as Map<String, dynamic>?;
        final outputText = response?['output_text'] as Map<String, dynamic>?;
        final delta = outputText?['delta'] as String?;
        if (delta != null && delta.isNotEmpty) {
          return StreamEvent.textDelta(text: delta);
        }
        return null;
      }

      // Tool progress events
      if (json.containsKey('tool')) {
        return StreamEvent.toolProgress(
          toolName: json['tool'] as String? ?? 'unknown',
          status: json['status'] as String? ?? 'started',
        );
      }

      // Unknown event format — log and skip.
      if (kDebugMode) {
        debugPrint(
            '=== HERMEX DEBUG: Unknown SSE event format — $data ===');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '=== HERMEX DEBUG: SSE parse error — $e (data: $data) ===');
      }
      return null; // Malformed JSON — skip this event, don't crash the stream
    }
  }
}
