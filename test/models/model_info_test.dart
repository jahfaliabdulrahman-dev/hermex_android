import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/models/model_info.dart';

void main() {
  group('ModelInfo — fromJson', () {
    test('parses a complete model info', () {
      final json = {
        'id': 'deepseek-v4-pro',
        'object': 'model',
        'created': 1700000000,
        'owned_by': 'deepseek',
      };

      final model = ModelInfo.fromJson(json);

      expect(model.id, 'deepseek-v4-pro');
      expect(model.object, 'model');
      expect(model.created, 1700000000);
      expect(model.ownedBy, 'deepseek');
    });

    test('defaults missing object to "model"', () {
      final json = {
        'id': 'test-model',
      };

      final model = ModelInfo.fromJson(json);

      expect(model.object, 'model');
    });

    test('handles null owned_by', () {
      final json = {
        'id': 'test-model',
      };

      final model = ModelInfo.fromJson(json);

      expect(model.ownedBy, isNull);
    });

    test('handles null created', () {
      final json = {
        'id': 'test-model',
      };

      final model = ModelInfo.fromJson(json);

      expect(model.created, isNull);
    });

    test('handles empty JSON gracefully', () {
      // id is required by freezed factory — empty JSON throws.
      // Test with minimal valid JSON instead.
      expect(
        () => ModelInfo.fromJson({}),
        throwsA(isA<TypeError>()),
      );

      final model = ModelInfo.fromJson({'id': ''});
      expect(model.id, '');
    });
  });

  group('ModelInfo — capabilities (D.16)', () {
    test('parses capabilities list from JSON', () {
      final json = {
        'id': 'test-model',
        'capabilities': ['chat', 'reasoning', 'vision', 'tools'],
      };

      final model = ModelInfo.fromJson(json);

      expect(model.capabilities, ['chat', 'reasoning', 'vision', 'tools']);
    });

    test('defaults capabilities to empty list when missing', () {
      final json = {'id': 'test-model'};

      final model = ModelInfo.fromJson(json);

      expect(model.capabilities, isEmpty);
    });

    test('capabilities from constructor are preserved', () {
      final model = ModelInfo(
        id: 'test',
        capabilities: ['chat', 'reasoning'],
      );

      expect(model.capabilities, ['chat', 'reasoning']);
    });
  });

  group('ModelInfo — supportedReasoningEfforts (E.20)', () {
    test('parses reasoning_effort from JSON', () {
      final json = {
        'id': 'test-model',
        'reasoning_effort': ['none', 'low', 'medium', 'high'],
      };

      final model = ModelInfo.fromJson(json);

      expect(model.supportedReasoningEfforts, ['none', 'low', 'medium', 'high']);
    });

    test('defaults reasoning_effort to empty list when missing', () {
      final json = {'id': 'test-model'};

      final model = ModelInfo.fromJson(json);

      expect(model.supportedReasoningEfforts, isEmpty);
    });

    test('empty reasoning_effort means model does not support reasoning control', () {
      final model = ModelInfo(id: 'basic-model');

      expect(model.supportedReasoningEfforts, isEmpty);
    });
  });

  group('ModelInfo — equality', () {
    test('two models with same id are equal', () {
      final a = ModelInfo(id: 'model-1');
      final b = ModelInfo(id: 'model-1');
      expect(a, equals(b));
    });

    test('two models with different id are not equal', () {
      final a = ModelInfo(id: 'model-1');
      final b = ModelInfo(id: 'model-2');
      expect(a, isNot(equals(b)));
    });
  });
}
