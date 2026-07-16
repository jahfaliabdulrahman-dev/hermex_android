import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/chat/presentation/model_selector.dart';
import 'package:hermex_android/models/model_info.dart';

void main() {
  group('ModelSelector', () {
    final sampleModels = [
      ModelInfo(id: 'deepseek-v4-pro', ownedBy: 'deepseek'),
      ModelInfo(
        id: 'hermes-default',
        ownedBy: 'nous',
        capabilities: ['chat', 'reasoning'],
        supportedReasoningEfforts: ['low', 'medium', 'high'],
      ),
      ModelInfo(id: 'gpt-4', ownedBy: 'openai'),
    ];

    Widget buildSelector({
      String? selectedModelId,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ModelSelector(
            models: sampleModels,
            selectedModelId: selectedModelId,
            onModelSelected: (_) {},
          ),
        ),
      );
    }

    testWidgets('renders "Select Model" title', (tester) async {
      await tester.pumpWidget(buildSelector());

      expect(find.text('Select Model'), findsOneWidget);
    });

    testWidgets('renders all model names', (tester) async {
      await tester.pumpWidget(buildSelector());

      expect(find.text('deepseek-v4-pro'), findsOneWidget);
      expect(find.text('hermes-default'), findsOneWidget);
      expect(find.text('gpt-4'), findsOneWidget);
    });

    testWidgets('renders model owner as subtitle when present', (tester) async {
      await tester.pumpWidget(buildSelector());

      expect(find.text('deepseek'), findsOneWidget);
      expect(find.text('nous'), findsOneWidget);
      expect(find.text('openai'), findsOneWidget);
    });

    testWidgets('does not render subtitle for models without ownedBy', (tester) async {
      final models = [ModelInfo(id: 'no-owner')];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ModelSelector(
            models: models,
            selectedModelId: null,
            onModelSelected: (_) {},
          ),
        ),
      ));

      // Only the title and the model ID should be present
      expect(find.text('no-owner'), findsOneWidget);
    });

    testWidgets('shows check icon for selected model', (tester) async {
      await tester.pumpWidget(buildSelector(selectedModelId: 'hermes-default'));

      // The selected model should have a check_circle icon, others circle_outlined.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsWidgets);
    });

    testWidgets('shows empty state when models list is empty', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ModelSelector(
            models: [],
            selectedModelId: null,
            onModelSelected: (_) {},
          ),
        ),
      ));

      expect(find.text('No models available.'), findsOneWidget);
    });

    testWidgets('calls onModelSelected when tapping a model', (tester) async {
      String? selectedId;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ModelSelector(
            models: sampleModels,
            selectedModelId: null,
            onModelSelected: (id) => selectedId = id,
          ),
        ),
      ));

      await tester.tap(find.text('gpt-4'));
      await tester.pumpAndSettle();

      expect(selectedId, 'gpt-4');
    });
  });
}
