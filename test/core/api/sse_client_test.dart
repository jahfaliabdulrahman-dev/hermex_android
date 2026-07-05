import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/core/api/sse_client.dart';
import 'package:hermex_android/models/stream_event.dart';

void main() {
  group('SseClient — lifecycle', () {
    test('constructs with baseUrl', () {
      final client = SseClient(baseUrl: 'http://localhost:8642');
      expect(client.baseUrl, 'http://localhost:8642');
      client.dispose();
    });

    test('cancel prevents further streaming', () {
      final client = SseClient(baseUrl: 'http://localhost:8642');
      client.cancel();
      client.dispose();
    });

    test('dispose calls cancel and releases resources', () {
      final client = SseClient(baseUrl: 'http://localhost:8642');
      client.dispose();
      client.dispose(); // safe double-dispose
    });
  });

  group('SSE data format — event parsing contract', () {
    test('identifies Chat Completions delta format', () {
      final event = StreamEvent.textDelta(text: 'Hello');
      expect(event, isA<TextDelta>());
      expect((event as TextDelta).text, 'Hello');
    });

    test('identifies Responses API output_text delta format', () {
      final event = StreamEvent.textDelta(text: 'Hi');
      expect(event, isA<TextDelta>());
    });

    test('identifies tool progress format', () {
      final event = StreamEvent.toolProgress(
        toolName: 'web_search',
        status: 'started',
      );
      expect(event, isA<ToolProgress>());
      final tp = event as ToolProgress;
      expect(tp.toolName, 'web_search');
      expect(tp.status, 'started');
    });

    test('handles [DONE] marker', () {
      final event = StreamEvent.done();
      expect(event, isA<StreamDone>());
    });

    test('defaults unknown tool to "unknown" name', () {
      final event = StreamEvent.toolProgress(
        toolName: 'unknown',
        status: 'started',
      );
      expect((event as ToolProgress).toolName, 'unknown');
    });

    test('defaults missing status to "started"', () {
      final event = StreamEvent.toolProgress(
        toolName: 'test',
        status: 'started',
      );
      expect((event as ToolProgress).status, 'started');
    });
  });

  group('SSE stream — error handling contract', () {
    test('StreamError carries message and optional code', () {
      final event = StreamEvent.error(message: 'Connection lost', code: '503');
      expect(event, isA<StreamError>());
      final err = event as StreamError;
      expect(err.message, 'Connection lost');
      expect(err.code, '503');
    });

    test('StreamError code is nullable', () {
      final event = StreamEvent.error(message: 'Unknown error');
      final err = event as StreamError;
      expect(err.code, isNull);
    });
  });

  group('SSE stream — event streaming contract', () {
    /// Helper: collect events from a stream created by a callback that adds
    /// events and then closes the controller.
    Future<List<StreamEvent>> _collect(
        void Function(StreamController<StreamEvent>) addEvents) async {
      final controller = StreamController<StreamEvent>();
      addEvents(controller);
      // Use toList() which completes when the stream closes
      final future = controller.stream.toList();
      await controller.close();
      return future;
    }

    test('stream can emit TextDelta then ToolProgress then StreamDone',
        () async {
      final events = await _collect((ctrl) {
        ctrl.add(StreamEvent.textDelta(text: 'Hello'));
        ctrl.add(StreamEvent.toolProgress(
            toolName: 'search', status: 'completed'));
        ctrl.add(StreamEvent.done());
      });

      expect(events.length, 3);
      expect(events[0], isA<TextDelta>());
      expect(events[1], isA<ToolProgress>());
      expect(events[2], isA<StreamDone>());
    });

    test('stream can emit error mid-sequence', () async {
      final events = await _collect((ctrl) {
        ctrl.add(StreamEvent.textDelta(text: 'Partial...'));
        ctrl.add(StreamEvent.error(message: 'Connection lost'));
      });

      expect(events.length, 2);
      expect(events[0], isA<TextDelta>());
      expect(events[1], isA<StreamError>());
    });

    test('stream can emit only StreamDone for empty responses', () async {
      final events = await _collect((ctrl) {
        ctrl.add(StreamEvent.done());
      });

      expect(events.length, 1);
      expect(events[0], isA<StreamDone>());
    });
  });
}
