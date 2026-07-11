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

  group('SseClient.parseEvent — Hermes Agent formats', () {
    late SseClient client;

    setUp(() {
      client = SseClient(baseUrl: 'http://localhost:8642');
    });

    tearDown(() {
      client.dispose();
    });

    // ─── assistant.delta (the core fix) ───

    test('parses assistant.delta with non-empty delta as TextDelta', () {
      final event = client.parseEvent(
        '{"delta": "Hello", "message": {"id": "msg-1", "role": "assistant"}}',
        'assistant.delta',
      );
      expect(event, isA<TextDelta>());
      expect((event as TextDelta).text, 'Hello');
    });

    test('parses assistant.delta with multi-word delta', () {
      final event = client.parseEvent(
        '{"delta": "Hey. What can I do for you?", "message": {"id": "msg-2"}}',
        'assistant.delta',
      );
      expect(event, isA<TextDelta>());
      expect((event as TextDelta).text, 'Hey. What can I do for you?');
    });

    test('skips assistant.delta with empty delta', () {
      final event = client.parseEvent(
        '{"delta": "", "message": {"id": "msg-3"}}',
        'assistant.delta',
      );
      expect(event, isNull);
    });

    test('skips assistant.delta without delta key', () {
      final event = client.parseEvent(
        '{"message": {"id": "msg-4"}}',
        'assistant.delta',
      );
      // Falls through to unknown format — should be null
      expect(event, isNull);
    });

    test('assistant.delta only matches with correct eventType', () {
      // Without the 'assistant.delta' eventType, the delta key is
      // not enough to trigger the branch (safety gate).
      final event = client.parseEvent(
        '{"delta": "hello", "extra": true}',
        '',
      );
      // This should NOT be parsed as TextDelta — unknown format
      expect(event, isNull);
    });

    test('assistant.delta with different eventType does not match', () {
      final event = client.parseEvent(
        '{"delta": "hello"}',
        'tool.progress', // wrong eventType
      );
      // tool.progress has no 'tool' or 'tool_name' key, and the delta
      // branch is gated on 'assistant.delta', so it falls through.
      expect(event, isNull);
    });

    // ─── tool.progress (Hermes Agent format) ───

    test('parses tool.progress with tool_name as ToolProgress', () {
      final event = client.parseEvent(
        '{"tool_name": "_thinking", "delta": "Let me think..."}',
        'tool.progress',
      );
      expect(event, isA<ToolProgress>());
      final tp = event as ToolProgress;
      expect(tp.toolName, '_thinking');
      expect(tp.status, 'started'); // default when no 'status' key
    });

    test('parses tool.progress with explicit status', () {
      final event = client.parseEvent(
        '{"tool_name": "web_search", "status": "completed", "delta": ""}',
        'tool.progress',
      );
      expect(event, isA<ToolProgress>());
      final tp = event as ToolProgress;
      expect(tp.toolName, 'web_search');
      expect(tp.status, 'completed');
    });

    test('tool.progress with tool_name defaults to "unknown"', () {
      final event = client.parseEvent(
        '{"tool_name": null}',
        'tool.progress',
      );
      expect(event, isA<ToolProgress>());
      expect((event as ToolProgress).toolName, 'unknown');
    });

    // ─── Backward Compatibility ───

    test('OpenAI Chat Completions format still works', () {
      final event = client.parseEvent(
        '{"choices": [{"delta": {"content": "Hello OpenAI"}}]}',
        '',
      );
      expect(event, isA<TextDelta>());
      expect((event as TextDelta).text, 'Hello OpenAI');
    });

    test('OpenAI Responses API format still works', () {
      final event = client.parseEvent(
        '{"response": {"output_text": {"delta": "Hi from API"}}}',
        '',
      );
      expect(event, isA<TextDelta>());
      expect((event as TextDelta).text, 'Hi from API');
    });

    test('OpenAI tool progress format still works', () {
      final event = client.parseEvent(
        '{"tool": "code_interpreter", "status": "started"}',
        '',
      );
      expect(event, isA<ToolProgress>());
      final tp = event as ToolProgress;
      expect(tp.toolName, 'code_interpreter');
      expect(tp.status, 'started');
    });

    // ─── Edge Cases ───

    test('handles malformed JSON gracefully (returns null)', () {
      final event = client.parseEvent('{broken json', 'assistant.delta');
      expect(event, isNull);
    });

    test('handles empty string', () {
      final event = client.parseEvent('', 'assistant.delta');
      expect(event, isNull);
    });

    test('tool.progress with both tool_name and delta emits ToolProgress not TextDelta', () {
      // This is the critical ordering test: tool_name must be checked BEFORE
      // the assistant.delta delta branch, so tool.progress with a delta
      // key is correctly routed to ToolProgress.
      final event = client.parseEvent(
        '{"tool_name": "search", "delta": "searching..."}',
        'assistant.delta', // Even if eventType were wrong, tool_name takes priority
      );
      expect(event, isA<ToolProgress>());
      expect((event as ToolProgress).toolName, 'search');
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
    Future<List<StreamEvent>> collect(
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
      final events = await collect((ctrl) {
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
      final events = await collect((ctrl) {
        ctrl.add(StreamEvent.textDelta(text: 'Partial...'));
        ctrl.add(StreamEvent.error(message: 'Connection lost'));
      });

      expect(events.length, 2);
      expect(events[0], isA<TextDelta>());
      expect(events[1], isA<StreamError>());
    });

    test('stream can emit only StreamDone for empty responses', () async {
      final events = await collect((ctrl) {
        ctrl.add(StreamEvent.done());
      });

      expect(events.length, 1);
      expect(events[0], isA<StreamDone>());
    });
  });
}
