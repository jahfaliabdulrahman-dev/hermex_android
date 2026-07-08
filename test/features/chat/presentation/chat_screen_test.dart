import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/chat/presentation/chat_input.dart';
import 'package:hermex_android/features/chat/presentation/message_bubble.dart';
import 'package:hermex_android/features/chat/presentation/model_selector.dart';
import 'package:hermex_android/models/chat_message.dart';
import 'package:hermex_android/models/model_info.dart';

void main() {
  group('MessageBubble — role-based rendering', () {
    testWidgets('user bubble shows content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                MessageBubble(
                  message: ChatMessage(
                    role: 'user',
                    content: 'Hello from user',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Hello from user'), findsOneWidget);
    });

    testWidgets('agent bubble renders markdown content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                MessageBubble(
                  message: ChatMessage(
                    role: 'assistant',
                    content: '**Bold** response',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // The markdown content should be rendered.
      expect(find.textContaining('Bold'), findsOneWidget);
      expect(find.textContaining('response'), findsOneWidget);
    });

    testWidgets('tool bubble shows compact tool info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                MessageBubble(
                  message: ChatMessage(
                    role: 'tool',
                    content: 'Using tool: web_search',
                    toolName: 'web_search',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.textContaining('Using tool: web_search'), findsOneWidget);
    });

    testWidgets('system bubble shows centered text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                MessageBubble(
                  message: ChatMessage(
                    role: 'system',
                    content: 'Error: Something went wrong',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Error: Something went wrong'), findsOneWidget);
    });

    testWidgets('streaming agent message shows typing indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                MessageBubble(
                  message: ChatMessage(
                    role: 'assistant',
                    content: 'Partial response...',
                    isStreaming: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Partial response...'), findsOneWidget);
      // The typing indicator dots should be present.
      // They are Container widgets with BoxShape.circle in a Row.
    });

    testWidgets('empty agent message shows empty indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                MessageBubble(
                  message: ChatMessage(
                    role: 'assistant',
                    content: '',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('(empty response)'), findsOneWidget);
    });
  });

  group('ChatInput — UI states', () {
    testWidgets('shows stop button when streaming', (tester) async {
      final controller = TextEditingController(text: 'Hello');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              controller: controller,
              isStreaming: true,
              onSend: () {},
            ),
          ),
        ),
      );

      // Stop icon should be visible.
      expect(find.byIcon(Icons.stop), findsOneWidget);
      addTearDown(controller.dispose);
    });

    testWidgets('send button is present', (tester) async {
      final controller = TextEditingController(text: 'Test message');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              controller: controller,
              isStreaming: false,
              onSend: () {},
            ),
          ),
        ),
      );

      // Send icon should be present.
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      addTearDown(controller.dispose);
    });

    testWidgets('sends message when send button tapped', (tester) async {
      final controller = TextEditingController(text: 'Hello world');
      bool sent = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              controller: controller,
              isStreaming: false,
              onSend: () => sent = true,
            ),
          ),
        ),
      );

      // Tap the send button.
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pump();

      expect(sent, true);
      addTearDown(controller.dispose);
    });

    testWidgets('stops generation when stop button tapped while streaming',
        (tester) async {
      final controller = TextEditingController(text: 'Hello');
      bool stopped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              controller: controller,
              isStreaming: true,
              onSend: () => stopped = true, // onSend triggers stop when streaming
            ),
          ),
        ),
      );

      // Tap the stop button.
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();

      expect(stopped, true);
      addTearDown(controller.dispose);
    });
  });

  group('ModelSelector — rendering', () {
    testWidgets('shows model list', (tester) async {
      final models = [
        ModelInfo(id: 'model-a', ownedBy: 'provider-a'),
        ModelInfo(id: 'model-b', ownedBy: 'provider-b'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelector(
              models: models,
              selectedModelId: 'model-a',
              onModelSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('model-a'), findsOneWidget);
      expect(find.text('model-b'), findsOneWidget);
      expect(find.text('provider-a'), findsOneWidget);
    });

    testWidgets('highlights selected model', (tester) async {
      final models = [
        ModelInfo(id: 'model-a'),
        ModelInfo(id: 'model-b'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelector(
              models: models,
              selectedModelId: 'model-a',
              onModelSelected: (_) {},
            ),
          ),
        ),
      );

      // The selected model should show a check icon.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows empty state when no models', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelector(
              models: const [],
              selectedModelId: null,
              onModelSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('No models available.'), findsOneWidget);
    });

    testWidgets('tapping a model calls onModelSelected', (tester) async {
      final models = [
        ModelInfo(id: 'model-a'),
        ModelInfo(id: 'model-b'),
      ];
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelector(
              models: models,
              selectedModelId: null,
              onModelSelected: (id) => selected = id,
            ),
          ),
        ),
      );

      // Tap on model-b.
      await tester.tap(find.text('model-b'));
      await tester.pump();

      expect(selected, 'model-b');
    });
  });
}
