import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/skills/data/skills_repository.dart';
import 'package:hermex_android/models/skill.dart';

void main() {
  late SkillsRepository repository;

  setUp(() {
    repository = SkillsRepository(apiClient: null);
  });

  group('SkillsRepository — no client', () {
    test('getSkills returns empty list when no apiClient', () async {
      final skills = await repository.getSkills();
      expect(skills, isEmpty);
    });
  });

  group('Skill model — parsing', () {
    test('fromJson parses a valid skill', () {
      final json = {
        'name': 'code-review',
        'description': 'Review code for quality',
        'category': 'development',
        'enabled': true,
        'snippet_count': 42,
        'source_reputation': 'High',
        'benchmark_score': 95,
      };

      final skill = Skill.fromJson(json);

      expect(skill.name, 'code-review');
      expect(skill.description, 'Review code for quality');
      expect(skill.category, 'development');
      expect(skill.enabled, true);
      expect(skill.snippetCount, 42);
      expect(skill.sourceReputation, 'High');
      expect(skill.benchmarkScore, 95);
    });

    test('fromJson handles missing optional fields with defaults', () {
      final json = {
        'name': 'minimal-skill',
      };

      final skill = Skill.fromJson(json);

      expect(skill.name, 'minimal-skill');
      expect(skill.description, '');
      expect(skill.category, isNull);
      expect(skill.enabled, true);
      expect(skill.snippetCount, 0);
      expect(skill.sourceReputation, isNull);
      expect(skill.benchmarkScore, 0);
    });

    test('fromJson handles unknown fields gracefully', () {
      final json = {
        'name': 'future-skill',
        'description': 'Has extra fields',
        'unknown_field': 'should not crash',
        'extra_array': [1, 2, 3],
      };

      final skill = Skill.fromJson(json);

      expect(skill.name, 'future-skill');
      expect(skill.description, 'Has extra fields');
    });

    test('copyWith updates enabled flag', () {
      final skill = Skill.fromJson({
        'name': 'test',
        'enabled': true,
      });

      final disabled = skill.copyWith(enabled: false);

      expect(skill.enabled, true);
      expect(disabled.enabled, false);
    });
  });
}
