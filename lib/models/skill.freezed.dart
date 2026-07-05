// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skill.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Skill _$SkillFromJson(Map<String, dynamic> json) {
  return _Skill.fromJson(json);
}

/// @nodoc
mixin _$Skill {
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  @JsonKey(name: 'snippet_count')
  int get snippetCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_reputation')
  String? get sourceReputation => throw _privateConstructorUsedError;
  @JsonKey(name: 'benchmark_score')
  int get benchmarkScore => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SkillCopyWith<Skill> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SkillCopyWith<$Res> {
  factory $SkillCopyWith(Skill value, $Res Function(Skill) then) =
      _$SkillCopyWithImpl<$Res, Skill>;
  @useResult
  $Res call(
      {String name,
      String description,
      String? category,
      bool enabled,
      @JsonKey(name: 'snippet_count') int snippetCount,
      @JsonKey(name: 'source_reputation') String? sourceReputation,
      @JsonKey(name: 'benchmark_score') int benchmarkScore});
}

/// @nodoc
class _$SkillCopyWithImpl<$Res, $Val extends Skill>
    implements $SkillCopyWith<$Res> {
  _$SkillCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? category = freezed,
    Object? enabled = null,
    Object? snippetCount = null,
    Object? sourceReputation = freezed,
    Object? benchmarkScore = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      snippetCount: null == snippetCount
          ? _value.snippetCount
          : snippetCount // ignore: cast_nullable_to_non_nullable
              as int,
      sourceReputation: freezed == sourceReputation
          ? _value.sourceReputation
          : sourceReputation // ignore: cast_nullable_to_non_nullable
              as String?,
      benchmarkScore: null == benchmarkScore
          ? _value.benchmarkScore
          : benchmarkScore // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SkillImplCopyWith<$Res> implements $SkillCopyWith<$Res> {
  factory _$$SkillImplCopyWith(
          _$SkillImpl value, $Res Function(_$SkillImpl) then) =
      __$$SkillImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String description,
      String? category,
      bool enabled,
      @JsonKey(name: 'snippet_count') int snippetCount,
      @JsonKey(name: 'source_reputation') String? sourceReputation,
      @JsonKey(name: 'benchmark_score') int benchmarkScore});
}

/// @nodoc
class __$$SkillImplCopyWithImpl<$Res>
    extends _$SkillCopyWithImpl<$Res, _$SkillImpl>
    implements _$$SkillImplCopyWith<$Res> {
  __$$SkillImplCopyWithImpl(
      _$SkillImpl _value, $Res Function(_$SkillImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? category = freezed,
    Object? enabled = null,
    Object? snippetCount = null,
    Object? sourceReputation = freezed,
    Object? benchmarkScore = null,
  }) {
    return _then(_$SkillImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      snippetCount: null == snippetCount
          ? _value.snippetCount
          : snippetCount // ignore: cast_nullable_to_non_nullable
              as int,
      sourceReputation: freezed == sourceReputation
          ? _value.sourceReputation
          : sourceReputation // ignore: cast_nullable_to_non_nullable
              as String?,
      benchmarkScore: null == benchmarkScore
          ? _value.benchmarkScore
          : benchmarkScore // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SkillImpl implements _Skill {
  const _$SkillImpl(
      {required this.name,
      this.description = '',
      this.category,
      this.enabled = true,
      @JsonKey(name: 'snippet_count') this.snippetCount = 0,
      @JsonKey(name: 'source_reputation') this.sourceReputation,
      @JsonKey(name: 'benchmark_score') this.benchmarkScore = 0});

  factory _$SkillImpl.fromJson(Map<String, dynamic> json) =>
      _$$SkillImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey()
  final String description;
  @override
  final String? category;
  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey(name: 'snippet_count')
  final int snippetCount;
  @override
  @JsonKey(name: 'source_reputation')
  final String? sourceReputation;
  @override
  @JsonKey(name: 'benchmark_score')
  final int benchmarkScore;

  @override
  String toString() {
    return 'Skill(name: $name, description: $description, category: $category, enabled: $enabled, snippetCount: $snippetCount, sourceReputation: $sourceReputation, benchmarkScore: $benchmarkScore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SkillImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.snippetCount, snippetCount) ||
                other.snippetCount == snippetCount) &&
            (identical(other.sourceReputation, sourceReputation) ||
                other.sourceReputation == sourceReputation) &&
            (identical(other.benchmarkScore, benchmarkScore) ||
                other.benchmarkScore == benchmarkScore));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, description, category,
      enabled, snippetCount, sourceReputation, benchmarkScore);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SkillImplCopyWith<_$SkillImpl> get copyWith =>
      __$$SkillImplCopyWithImpl<_$SkillImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SkillImplToJson(
      this,
    );
  }
}

abstract class _Skill implements Skill {
  const factory _Skill(
          {required final String name,
          final String description,
          final String? category,
          final bool enabled,
          @JsonKey(name: 'snippet_count') final int snippetCount,
          @JsonKey(name: 'source_reputation') final String? sourceReputation,
          @JsonKey(name: 'benchmark_score') final int benchmarkScore}) =
      _$SkillImpl;

  factory _Skill.fromJson(Map<String, dynamic> json) = _$SkillImpl.fromJson;

  @override
  String get name;
  @override
  String get description;
  @override
  String? get category;
  @override
  bool get enabled;
  @override
  @JsonKey(name: 'snippet_count')
  int get snippetCount;
  @override
  @JsonKey(name: 'source_reputation')
  String? get sourceReputation;
  @override
  @JsonKey(name: 'benchmark_score')
  int get benchmarkScore;
  @override
  @JsonKey(ignore: true)
  _$$SkillImplCopyWith<_$SkillImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
