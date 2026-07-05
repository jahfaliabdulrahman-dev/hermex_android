import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/sse_client.dart';
import '../../../core/constants/security_limits.dart';
import '../../../models/stream_event.dart';

/// Manages an active SSE stream connection, wrapping [SseClient] with a
/// [StreamController] for broadcast-style event distribution.
///
/// Lifecycle:
/// 1. [connect] — start streaming from a path, emits events to controller
/// 2. [cancel] — cancel active stream, close controller
/// 3. [dispose] — release all resources
///
/// The [eventStream] can be listened to by multiple consumers (broadcast).
/// Only one active connection is supported at a time per instance.
class StreamManager {
  final SseClient _sseClient;

  StreamController<StreamEvent>? _controller;
  StreamSubscription<StreamEvent>? _subscription;

  StreamManager({required SseClient sseClient}) : _sseClient = sseClient;

  /// Broadcast stream of SSE events. Available after [connect] is called.
  Stream<StreamEvent>? get eventStream => _controller?.stream;

  /// Whether a stream is currently active.
  bool get isActive => _controller != null && !_controller!.isClosed;

  /// Connect to an SSE endpoint and start emitting events.
  ///
  /// [path] — API path (e.g., "/v1/chat/completions")
  /// [apiKey] — Bearer token
  /// [body] — optional JSON request body for POST-based SSE
  ///
  /// Cancels any previously active stream before connecting.
  Stream<StreamEvent> connect({
    required String path,
    required String apiKey,
    Map<String, dynamic>? body,
  }) {
    // Cancel any existing connection.
    cancel();

    debugPrint(
        '=== HERMEX DEBUG: StreamManager.connect — path=$path ===');

    _controller = StreamController<StreamEvent>.broadcast(
      onCancel: () {
        debugPrint(
            '=== HERMEX DEBUG: StreamManager — all listeners cancelled ===');
      },
    );

    // Forward events from SseClient to the broadcast controller.
    final sourceStream = _sseClient.connect(
      path,
      apiKey: apiKey,
      body: body,
    );

    _subscription = sourceStream.listen(
      (event) {
        if (_controller != null && !_controller!.isClosed) {
          // AUD-006: Truncate oversized TextDelta content before UI emission.
          final safeEvent = _sanitizeEvent(event);
          _controller!.add(safeEvent);
        }
      },
      onError: (error) {
        debugPrint(
            '=== HERMEX DEBUG: StreamManager stream error — $error ===');
        if (_controller != null && !_controller!.isClosed) {
          _controller!.add(StreamEvent.error(
            message: error.toString(),
          ));
        }
      },
      onDone: () {
        debugPrint('=== HERMEX DEBUG: StreamManager stream done ===');
        if (_controller != null && !_controller!.isClosed) {
          _controller!.add(const StreamEvent.done());
        }
      },
      cancelOnError: false,
    );

    return _controller!.stream;
  }

  /// Cancel the active stream and close the controller.
  void cancel() {
    debugPrint('=== HERMEX DEBUG: StreamManager.cancel ===');

    _subscription?.cancel();
    _subscription = null;
    _sseClient.cancel();

    if (_controller != null && !_controller!.isClosed) {
      _controller!.close();
      _controller = null;
    }
  }

  /// Dispose all resources.
  void dispose() {
    cancel();
    _sseClient.dispose();
  }

  // ─── Input Sanitization (AUD-006) ───

  /// Sanitize an incoming event — truncate oversized [TextDelta] content
  /// to [SecurityLimits.maxTextDeltaSize] before forwarding to UI.
  StreamEvent _sanitizeEvent(StreamEvent event) {
    if (event is TextDelta && event.text.length > SecurityLimits.maxTextDeltaSize) {
      debugPrint(
          '=== HERMEX DEBUG: TextDelta truncated — '
          '${event.text.length} chars -> ${SecurityLimits.maxTextDeltaSize} chars ===');
      return StreamEvent.textDelta(
        text: event.text.substring(0, SecurityLimits.maxTextDeltaSize),
      );
    }
    return event;
  }
}
