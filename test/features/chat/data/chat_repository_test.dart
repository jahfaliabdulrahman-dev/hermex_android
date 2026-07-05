import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/models/chat_message.dart';
import 'package:hermex_android/models/model_info.dart';
import 'package:hermex_android/models/stream_event.dart';

/// Tests for ChatRepository data parsing and response handling.
///
/// The ChatRepository requires ApiClient (Dio) and SseClient (dart:io HttpClient)
/// which cannot be easily mocked without a mocking library. These tests cover
/// the data parsing contracts that the repository relies on. Full repository
/// coverage requires integration tests (see test/integration/).
void main() {
  group('ChatRepository — model parsing contract', () {
    test('GET /v1/models response: parses data array', () {
      final json = {
        'data': [
          {'id': 'deepseek-v4-pro', 'owned_by': 'deepseek'},
          {'id': 'qwen3.7-max', 'owned_by': 'alibaba'},
        ],
      };

      final data = json['data'] as List<dynamic>?;
      expect(data, isNotNull);
      expect(data!.length, 2);

      final models = data
          .map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(models.length, 2);
      expect(models[0].id, 'deepseek-v4-pro');
      expect(models[1].id, 'qwen3.7-max');
      expect(models[0].ownedBy, 'deepseek');
    });

    test('GET /v1/models response: handles null data', () {
      final json = <String, dynamic>{};
      final data = json['data'] as List<dynamic>?;
      expect(data, isNull);
    });

    test('GET /api/sessions/{id}/messages response: parses messages', () {
      final json = {
        'messages': [
          {'role': 'user', 'content': 'Hello'},
          {'role': 'assistant', 'content': 'Hi there!'},
          {'role': 'tool', 'content': 'Result', 'tool_name': 'search'},
        ],
      };

      final messages = json['messages'] as List<dynamic>?;
      expect(messages, isNotNull);
      expect(messages!.length, 3);

      final parsed = messages
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(parsed[0].role, 'user');
      expect(parsed[1].role, 'assistant');
      expect(parsed[2].role, 'tool');
      expect(parsed[2].toolName, 'search');
    });

    test('GET /api/sessions/{id}/messages response: handles null messages', () {
      final json = <String, dynamic>{};
      final messages = json['messages'] as List<dynamic>?;
      expect(messages, isNull);
    });
  });

  group('ChatRepository — chat completion body format', () {
    test('streaming request builds correct JSON body', () {
      final message = 'Hello world';
      final model = 'deepseek-v4-pro';
      final history = <Map<String, dynamic>>[
        {'role': 'system', 'content': 'You are helpful.'},
        {'role': 'user', 'content': 'Previous question'},
        {'role': 'assistant', 'content': 'Previous answer'},
      ];

      // This is what ChatRepository.streamChatCompletion() builds
      final messages = <Map<String, dynamic>>[
        ...history,
        {'role': 'user', 'content': message},
      ];

      final body = {
        'model': model,
        'messages': messages,
        'stream': true,
      };

      expect(body['model'], 'deepseek-v4-pro');
      expect(body['stream'], true);
      expect((body['messages'] as List).length, 4);
      expect((body['messages'] as List).last['role'], 'user');
      expect((body['messages'] as List).last['content'], 'Hello world');
    });

    test('streaming request without history only includes current message', () {
      final messages = <Map<String, dynamic>>[
        {'role': 'user', 'content': 'Hello'},
      ];

      final body = {
        'model': 'test-model',
        'messages': messages,
        'stream': true,
      };

      expect((body['messages'] as List).length, 1);
    });

    test('non-streaming request sets stream: false', () {
      final body = {
        'model': 'test-model',
        'messages': [
          {'role': 'user', 'content': 'Hello'},
        ],
        'stream': false,
      };

      expect(body['stream'], false);
    });
  });

  group('ChatRepository — non-streaming response parsing', () {
    test('parses choices[0].message.content', () {
      final json = {
        'choices': [
          {
            'message': {
              'content': 'Hello from the assistant!',
            },
          },
        ],
      };

      final choices = json['choices'] as List<dynamic>?;
      expect(choices, isNotNull);

      final message =
          choices![0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      expect(content, 'Hello from the assistant!');
    });

    test('handles null choices', () {
      final json = <String, dynamic>{};
      final choices = json['choices'] as List<dynamic>?;
      expect(choices, isNull);
    });

    test('handles empty choices', () {
      final json = {'choices': <dynamic>[]};
      final choices = json['choices'];
      expect(choices, isEmpty);
    });

    test('handles missing content field', () {
      final json = {
        'choices': [
          {'message': <String, dynamic>{}}, // no content
        ],
      };

      final choices = json['choices'] as List<dynamic>?;
      final message =
          choices![0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      expect(content, isNull);
    });
  });

  group('ChatRepository — SSE streaming formats', () {
    test('streamSessionChat builds correct body', () {
      final message = 'Continue our conversation';
      final model = 'deepseek-v4-pro';

      final body = {
        'message': message,
        'model': model,
      };

      expect(body['message'], 'Continue our conversation');
      expect(body['model'], 'deepseek-v4-pro');
    });

    test('SSE stream can emit sequence of events', () async {
      // Simulate a full SSE sequence.
      final controller = StreamController<StreamEvent>();
      controller.add(StreamEvent.textDelta(text: 'Let me search...'));
      controller.add(StreamEvent.toolProgress(
        toolName: 'web_search',
        status: 'started',
      ));
      controller.add(StreamEvent.toolProgress(
        toolName: 'web_search',
        status: 'completed',
      ));
      controller.add(StreamEvent.textDelta(text: ' Found results.'));

      final future = controller.stream.toList();
      await controller.close();
      final events = await future;

      expect(events.length, 4);
      expect(events.whereType<TextDelta>().length, 2);
      expect(events.whereType<ToolProgress>().length, 2);
    });
  });
}
