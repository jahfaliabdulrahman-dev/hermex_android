import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/core/api/sse_client.dart';
import 'package:hermex_android/core/constants/security_limits.dart';
import 'package:hermex_android/features/chat/providers/stream_provider.dart';
import 'package:hermex_android/models/stream_event.dart';

/// Fake SSE client that emits controlled events for testing.
///
/// Uses a fresh [StreamController] per `connect()` call so that
/// reconnection tests work (single-subscription per connect).
class FakeSseClient extends SseClient {
  StreamController<StreamEvent>? _currentController;

  FakeSseClient() : super(baseUrl: 'http://test.local:8642');

  @override
  Stream<StreamEvent> connect(
    String path, {
    required String apiKey,
    Map<String, dynamic>? body,
  }) {
    // Create a fresh controller for this connection.
    _currentController = StreamController<StreamEvent>();
    return _currentController!.stream;
  }

  @override
  void cancel() {
    _currentController?.close();
    _currentController = null;
  }

  @override
  void dispose() {
    _currentController?.close();
    _currentController = null;
  }

  /// Emit an event through the current controller.
  void emit(StreamEvent event) {
    if (_currentController != null && !_currentController!.isClosed) {
      _currentController!.add(event);
    }
  }

  /// Close the current stream (simulates done).
  void emitDone() {
    if (_currentController != null && !_currentController!.isClosed) {
      _currentController!.close();
      _currentController = null;
    }
  }
}

void main() {
  group('StreamManager — lifecycle', () {
    late FakeSseClient fakeSseClient;
    late StreamManager streamManager;

    setUp(() {
      fakeSseClient = FakeSseClient();
      streamManager = StreamManager(sseClient: fakeSseClient);
    });

    tearDown(() {
      streamManager.dispose();
    });

    test('initial state is inactive', () {
      expect(streamManager.isActive, false);
      expect(streamManager.eventStream, isNull);
    });

    test('connect makes stream active', () {
      streamManager.connect(
        path: '/v1/chat/completions',
        apiKey: 'test-key',
        body: {'stream': true},
      );

      expect(streamManager.isActive, true);
      expect(streamManager.eventStream, isNotNull);
    });

    test('receives TextDelta events', () async {
      final stream = streamManager.connect(
        path: '/test',
        apiKey: 'test-key',
      );

      final events = <StreamEvent>[];
      final subscription = stream.listen(events.add);

      fakeSseClient.emit(StreamEvent.textDelta(text: 'Hello'));
      fakeSseClient.emit(StreamEvent.textDelta(text: ' World'));

      // Give time for events to propagate.
      await Future.delayed(const Duration(milliseconds: 100));

      expect(events.length, 2);
      expect(events[0], isA<TextDelta>());
      expect((events[0] as TextDelta).text, 'Hello');
      expect((events[1] as TextDelta).text, ' World');

      await subscription.cancel();
    });

    test('receives ToolProgress events', () async {
      final stream = streamManager.connect(
        path: '/test',
        apiKey: 'test-key',
      );

      final events = <StreamEvent>[];
      final subscription = stream.listen(events.add);

      fakeSseClient.emit(StreamEvent.toolProgress(
        toolName: 'web_search',
        status: 'started',
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(events.length, 1);
      expect(events[0], isA<ToolProgress>());
      expect((events[0] as ToolProgress).toolName, 'web_search');
      expect((events[0] as ToolProgress).status, 'started');

      await subscription.cancel();
    });

    test('receives StreamDone when source closes', () async {
      final stream = streamManager.connect(
        path: '/test',
        apiKey: 'test-key',
      );

      final events = <StreamEvent>[];
      final subscription = stream.listen(events.add);

      fakeSseClient.emitDone();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(events.length, 1);
      expect(events[0], isA<StreamDone>());

      await subscription.cancel();
    });

    test('cancel closes stream and makes inactive', () async {
      final stream = streamManager.connect(
        path: '/test',
        apiKey: 'test-key',
      );

      // Listen to avoid "Stream has no listeners" error on broadcast.
      final subscription = stream.listen((_) {});

      expect(streamManager.isActive, true);

      streamManager.cancel();

      expect(streamManager.isActive, false);

      await subscription.cancel();
    });

    test('re-connecting cancels previous stream', () async {
      final stream1 = streamManager.connect(
        path: '/test1',
        apiKey: 'test-key',
      );
      final sub1 = stream1.listen((_) {});

      final stream2 = streamManager.connect(
        path: '/test2',
        apiKey: 'test-key',
      );
      final sub2 = stream2.listen((_) {});

      // stream1 should have been canceled internally by the second connect.
      expect(streamManager.isActive, true);

      await sub1.cancel();
      await sub2.cancel();
    });
  });

  group('StreamManager — dispose', () {
    test('dispose cleans up all resources', () async {
      final fakeClient = FakeSseClient();
      final manager = StreamManager(sseClient: fakeClient);

      final stream = manager.connect(
        path: '/test',
        apiKey: 'test-key',
      );
      final sub = stream.listen((_) {});

      manager.dispose();

      expect(manager.isActive, false);
      expect(manager.eventStream, isNull);

      await sub.cancel();
    });
  });

  group('StreamManager — TextDelta truncation (AUD-006)', () {
    late FakeSseClient fakeSseClient;
    late StreamManager streamManager;

    setUp(() {
      fakeSseClient = FakeSseClient();
      streamManager = StreamManager(sseClient: fakeSseClient);
    });

    tearDown(() {
      streamManager.dispose();
    });

    test('passes TextDelta within size limit unchanged', () async {
      final stream = streamManager.connect(
        path: '/test',
        apiKey: 'test-key',
      );

      final events = <StreamEvent>[];
      final subscription = stream.listen(events.add);

      fakeSseClient.emit(StreamEvent.textDelta(text: 'Normal text'));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(events.length, 1);
      expect(events[0], isA<TextDelta>());
      expect((events[0] as TextDelta).text, 'Normal text');

      await subscription.cancel();
    });

    test('truncates oversized TextDelta content', () async {
      final stream = streamManager.connect(
        path: '/test',
        apiKey: 'test-key',
      );

      final events = <StreamEvent>[];
      final subscription = stream.listen(events.add);

      final oversizedText = 'A' * (SecurityLimits.maxTextDeltaSize + 1000);
      fakeSseClient.emit(StreamEvent.textDelta(text: oversizedText));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(events.length, 1);
      expect(events[0], isA<TextDelta>());
      final textDelta = events[0] as TextDelta;
      expect(textDelta.text.length, SecurityLimits.maxTextDeltaSize);
      expect(textDelta.text, startsWith('A' * 50)); // truncated but starts correctly

      await subscription.cancel();
    });

    test('does not modify non-TextDelta events', () async {
      final stream = streamManager.connect(
        path: '/test',
        apiKey: 'test-key',
      );

      final events = <StreamEvent>[];
      final subscription = stream.listen(events.add);

      fakeSseClient.emit(StreamEvent.toolProgress(
        toolName: 'test_tool',
        status: 'started',
      ));
      fakeSseClient.emit(const StreamEvent.done());

      await Future.delayed(const Duration(milliseconds: 100));

      expect(events.length, 2);
      expect(events[0], isA<ToolProgress>());
      expect(events[1], isA<StreamDone>());

      await subscription.cancel();
    });

    test('exactly at limit TextDelta passes unchanged', () async {
      final stream = streamManager.connect(
        path: '/test',
        apiKey: 'test-key',
      );

      final events = <StreamEvent>[];
      final subscription = stream.listen(events.add);

      final exactText = 'B' * SecurityLimits.maxTextDeltaSize;
      fakeSseClient.emit(StreamEvent.textDelta(text: exactText));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(events.length, 1);
      expect(events[0], isA<TextDelta>());
      expect((events[0] as TextDelta).text.length, SecurityLimits.maxTextDeltaSize);

      await subscription.cancel();
    });
  });
}
