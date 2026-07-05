// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SkillImpl _$$SkillImplFromJson(Map<String, dynamic> json) => _$SkillImpl(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      snippetCount: (json['snippet_count'] as num?)?.toInt() ?? 0,
      sourceReputation: json['source_reputation'] as String?,
      benchmarkScore: (json['benchmark_score'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$SkillImplToJson(_$SkillImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'enabled': instance.enabled,
      'snippet_count': instance.snippetCount,
      'source_reputation': instance.sourceReputation,
      'benchmark_score': instance.benchmarkScore,
    };
