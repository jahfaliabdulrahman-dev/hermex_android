import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill.freezed.dart';
part 'skill.g.dart';

/// Skill from GET /v1/skills.
/// Represents an installable agent capability on the Hermes server.
@freezed
class Skill with _$Skill {
  const factory Skill({
    required String name,
    @Default('') String description,
    String? category,
    @Default(true) bool enabled,
    @JsonKey(name: 'snippet_count') @Default(0) int snippetCount,
    @JsonKey(name: 'source_reputation') String? sourceReputation,
    @JsonKey(name: 'benchmark_score') @Default(0) int benchmarkScore,
  }) = _Skill;

  factory Skill.fromJson(Map<String, dynamic> json) => _$SkillFromJson(json);
}
