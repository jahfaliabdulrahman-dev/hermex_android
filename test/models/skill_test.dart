import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/models/skill.dart';

void main() {
  group('Skill — fromJson', () {
    test('parses a complete skill', () {
      final json = {
        'name': 'flutter-patterns',
        'description': 'Class-level Flutter patterns',
        'category': 'flutter',
        'enabled': true,
        'snippet_count': 42,
        'source_reputation': 'High',
        'benchmark_score': 95,
      };

      final skill = Skill.fromJson(json);

      expect(skill.name, 'flutter-patterns');
      expect(skill.description, 'Class-level Flutter patterns');
      expect(skill.category, 'flutter');
      expect(skill.enabled, true);
      expect(skill.snippetCount, 42);
      expect(skill.sourceReputation, 'High');
      expect(skill.benchmarkScore, 95);
    });

    test('defaults missing fields', () {
      final json = {
        'name': 'test-skill',
      };

      final skill = Skill.fromJson(json);

      expect(skill.description, '');
      expect(skill.category, isNull);
      expect(skill.enabled, true);
      expect(skill.snippetCount, 0);
      expect(skill.sourceReputation, isNull);
      expect(skill.benchmarkScore, 0);
    });

    test('handles disabled skill', () {
      final json = {
        'name': 'disabled-skill',
        'enabled': false,
      };

      final skill = Skill.fromJson(json);

      expect(skill.enabled, false);
    });

    test('handles null values', () {
      final json = {
        'name': 'test',
        'description': null,
        'category': null,
      };

      final skill = Skill.fromJson(json);

      expect(skill.description, '');
      expect(skill.category, isNull);
    });
  });

  group('Skill — equality', () {
    test('two skills with same fields are equal', () {
      final a = Skill(name: 'test-skill', description: 'A skill');
      final b = Skill(name: 'test-skill', description: 'A skill');
      expect(a, equals(b));
    });

    test('two skills with different names are not equal', () {
      final a = Skill(name: 'skill-a');
      final b = Skill(name: 'skill-b');
      expect(a, isNot(equals(b)));
    });
  });
}
