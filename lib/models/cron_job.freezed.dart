// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cron_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CronJob _$CronJobFromJson(Map<String, dynamic> json) {
  return _CronJob.fromJson(json);
}

/// @nodoc
mixin _$CronJob {
  String get id => throw _privateConstructorUsedError;
  String get prompt => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseSchedule)
  String get schedule => throw _privateConstructorUsedError;
  @JsonKey(name: 'state')
  String? get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_run_at', fromJson: _fromTimestamp)
  DateTime? get lastRun => throw _privateConstructorUsedError;
  @JsonKey(name: 'next_run_at', fromJson: _fromTimestamp)
  DateTime? get nextRun => throw _privateConstructorUsedError;
  List<String> get skills => throw _privateConstructorUsedError;
  @JsonKey(name: 'provider')
  String? get modelProvider => throw _privateConstructorUsedError;
  @JsonKey(name: 'model')
  String? get modelName => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get deliver => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at', fromJson: _fromTimestamp)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_error')
  String? get lastError => throw _privateConstructorUsedError;
  @JsonKey(name: 'paused_at', fromJson: _fromPausedAt, toJson: _toPausedAt)
  bool get paused => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CronJobCopyWith<CronJob> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CronJobCopyWith<$Res> {
  factory $CronJobCopyWith(CronJob value, $Res Function(CronJob) then) =
      _$CronJobCopyWithImpl<$Res, CronJob>;
  @useResult
  $Res call(
      {String id,
      String prompt,
      @JsonKey(fromJson: _parseSchedule) String schedule,
      @JsonKey(name: 'state') String? status,
      @JsonKey(name: 'last_run_at', fromJson: _fromTimestamp) DateTime? lastRun,
      @JsonKey(name: 'next_run_at', fromJson: _fromTimestamp) DateTime? nextRun,
      List<String> skills,
      @JsonKey(name: 'provider') String? modelProvider,
      @JsonKey(name: 'model') String? modelName,
      String? name,
      String? deliver,
      @JsonKey(name: 'created_at', fromJson: _fromTimestamp)
      DateTime? createdAt,
      @JsonKey(name: 'last_error') String? lastError,
      @JsonKey(name: 'paused_at', fromJson: _fromPausedAt, toJson: _toPausedAt)
      bool paused});
}

/// @nodoc
class _$CronJobCopyWithImpl<$Res, $Val extends CronJob>
    implements $CronJobCopyWith<$Res> {
  _$CronJobCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? prompt = null,
    Object? schedule = null,
    Object? status = freezed,
    Object? lastRun = freezed,
    Object? nextRun = freezed,
    Object? skills = null,
    Object? modelProvider = freezed,
    Object? modelName = freezed,
    Object? name = freezed,
    Object? deliver = freezed,
    Object? createdAt = freezed,
    Object? lastError = freezed,
    Object? paused = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      prompt: null == prompt
          ? _value.prompt
          : prompt // ignore: cast_nullable_to_non_nullable
              as String,
      schedule: null == schedule
          ? _value.schedule
          : schedule // ignore: cast_nullable_to_non_nullable
              as String,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      lastRun: freezed == lastRun
          ? _value.lastRun
          : lastRun // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextRun: freezed == nextRun
          ? _value.nextRun
          : nextRun // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      skills: null == skills
          ? _value.skills
          : skills // ignore: cast_nullable_to_non_nullable
              as List<String>,
      modelProvider: freezed == modelProvider
          ? _value.modelProvider
          : modelProvider // ignore: cast_nullable_to_non_nullable
              as String?,
      modelName: freezed == modelName
          ? _value.modelName
          : modelName // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      deliver: freezed == deliver
          ? _value.deliver
          : deliver // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastError: freezed == lastError
          ? _value.lastError
          : lastError // ignore: cast_nullable_to_non_nullable
              as String?,
      paused: null == paused
          ? _value.paused
          : paused // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CronJobImplCopyWith<$Res> implements $CronJobCopyWith<$Res> {
  factory _$$CronJobImplCopyWith(
          _$CronJobImpl value, $Res Function(_$CronJobImpl) then) =
      __$$CronJobImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String prompt,
      @JsonKey(fromJson: _parseSchedule) String schedule,
      @JsonKey(name: 'state') String? status,
      @JsonKey(name: 'last_run_at', fromJson: _fromTimestamp) DateTime? lastRun,
      @JsonKey(name: 'next_run_at', fromJson: _fromTimestamp) DateTime? nextRun,
      List<String> skills,
      @JsonKey(name: 'provider') String? modelProvider,
      @JsonKey(name: 'model') String? modelName,
      String? name,
      String? deliver,
      @JsonKey(name: 'created_at', fromJson: _fromTimestamp)
      DateTime? createdAt,
      @JsonKey(name: 'last_error') String? lastError,
      @JsonKey(name: 'paused_at', fromJson: _fromPausedAt, toJson: _toPausedAt)
      bool paused});
}

/// @nodoc
class __$$CronJobImplCopyWithImpl<$Res>
    extends _$CronJobCopyWithImpl<$Res, _$CronJobImpl>
    implements _$$CronJobImplCopyWith<$Res> {
  __$$CronJobImplCopyWithImpl(
      _$CronJobImpl _value, $Res Function(_$CronJobImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? prompt = null,
    Object? schedule = null,
    Object? status = freezed,
    Object? lastRun = freezed,
    Object? nextRun = freezed,
    Object? skills = null,
    Object? modelProvider = freezed,
    Object? modelName = freezed,
    Object? name = freezed,
    Object? deliver = freezed,
    Object? createdAt = freezed,
    Object? lastError = freezed,
    Object? paused = null,
  }) {
    return _then(_$CronJobImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      prompt: null == prompt
          ? _value.prompt
          : prompt // ignore: cast_nullable_to_non_nullable
              as String,
      schedule: null == schedule
          ? _value.schedule
          : schedule // ignore: cast_nullable_to_non_nullable
              as String,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      lastRun: freezed == lastRun
          ? _value.lastRun
          : lastRun // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextRun: freezed == nextRun
          ? _value.nextRun
          : nextRun // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      skills: null == skills
          ? _value._skills
          : skills // ignore: cast_nullable_to_non_nullable
              as List<String>,
      modelProvider: freezed == modelProvider
          ? _value.modelProvider
          : modelProvider // ignore: cast_nullable_to_non_nullable
              as String?,
      modelName: freezed == modelName
          ? _value.modelName
          : modelName // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      deliver: freezed == deliver
          ? _value.deliver
          : deliver // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastError: freezed == lastError
          ? _value.lastError
          : lastError // ignore: cast_nullable_to_non_nullable
              as String?,
      paused: null == paused
          ? _value.paused
          : paused // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CronJobImpl implements _CronJob {
  const _$CronJobImpl(
      {required this.id,
      required this.prompt,
      @JsonKey(fromJson: _parseSchedule) required this.schedule,
      @JsonKey(name: 'state') this.status,
      @JsonKey(name: 'last_run_at', fromJson: _fromTimestamp) this.lastRun,
      @JsonKey(name: 'next_run_at', fromJson: _fromTimestamp) this.nextRun,
      final List<String> skills = const [],
      @JsonKey(name: 'provider') this.modelProvider,
      @JsonKey(name: 'model') this.modelName,
      this.name,
      this.deliver,
      @JsonKey(name: 'created_at', fromJson: _fromTimestamp) this.createdAt,
      @JsonKey(name: 'last_error') this.lastError,
      @JsonKey(name: 'paused_at', fromJson: _fromPausedAt, toJson: _toPausedAt)
      this.paused = false})
      : _skills = skills;

  factory _$CronJobImpl.fromJson(Map<String, dynamic> json) =>
      _$$CronJobImplFromJson(json);

  @override
  final String id;
  @override
  final String prompt;
  @override
  @JsonKey(fromJson: _parseSchedule)
  final String schedule;
  @override
  @JsonKey(name: 'state')
  final String? status;
  @override
  @JsonKey(name: 'last_run_at', fromJson: _fromTimestamp)
  final DateTime? lastRun;
  @override
  @JsonKey(name: 'next_run_at', fromJson: _fromTimestamp)
  final DateTime? nextRun;
  final List<String> _skills;
  @override
  @JsonKey()
  List<String> get skills {
    if (_skills is EqualUnmodifiableListView) return _skills;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_skills);
  }

  @override
  @JsonKey(name: 'provider')
  final String? modelProvider;
  @override
  @JsonKey(name: 'model')
  final String? modelName;
  @override
  final String? name;
  @override
  final String? deliver;
  @override
  @JsonKey(name: 'created_at', fromJson: _fromTimestamp)
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'last_error')
  final String? lastError;
  @override
  @JsonKey(name: 'paused_at', fromJson: _fromPausedAt, toJson: _toPausedAt)
  final bool paused;

  @override
  String toString() {
    return 'CronJob(id: $id, prompt: $prompt, schedule: $schedule, status: $status, lastRun: $lastRun, nextRun: $nextRun, skills: $skills, modelProvider: $modelProvider, modelName: $modelName, name: $name, deliver: $deliver, createdAt: $createdAt, lastError: $lastError, paused: $paused)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CronJobImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.prompt, prompt) || other.prompt == prompt) &&
            (identical(other.schedule, schedule) ||
                other.schedule == schedule) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastRun, lastRun) || other.lastRun == lastRun) &&
            (identical(other.nextRun, nextRun) || other.nextRun == nextRun) &&
            const DeepCollectionEquality().equals(other._skills, _skills) &&
            (identical(other.modelProvider, modelProvider) ||
                other.modelProvider == modelProvider) &&
            (identical(other.modelName, modelName) ||
                other.modelName == modelName) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.deliver, deliver) || other.deliver == deliver) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastError, lastError) ||
                other.lastError == lastError) &&
            (identical(other.paused, paused) || other.paused == paused));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      prompt,
      schedule,
      status,
      lastRun,
      nextRun,
      const DeepCollectionEquality().hash(_skills),
      modelProvider,
      modelName,
      name,
      deliver,
      createdAt,
      lastError,
      paused);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CronJobImplCopyWith<_$CronJobImpl> get copyWith =>
      __$$CronJobImplCopyWithImpl<_$CronJobImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CronJobImplToJson(
      this,
    );
  }
}

abstract class _CronJob implements CronJob {
  const factory _CronJob(
      {required final String id,
      required final String prompt,
      @JsonKey(fromJson: _parseSchedule) required final String schedule,
      @JsonKey(name: 'state') final String? status,
      @JsonKey(name: 'last_run_at', fromJson: _fromTimestamp)
      final DateTime? lastRun,
      @JsonKey(name: 'next_run_at', fromJson: _fromTimestamp)
      final DateTime? nextRun,
      final List<String> skills,
      @JsonKey(name: 'provider') final String? modelProvider,
      @JsonKey(name: 'model') final String? modelName,
      final String? name,
      final String? deliver,
      @JsonKey(name: 'created_at', fromJson: _fromTimestamp)
      final DateTime? createdAt,
      @JsonKey(name: 'last_error') final String? lastError,
      @JsonKey(name: 'paused_at', fromJson: _fromPausedAt, toJson: _toPausedAt)
      final bool paused}) = _$CronJobImpl;

  factory _CronJob.fromJson(Map<String, dynamic> json) = _$CronJobImpl.fromJson;

  @override
  String get id;
  @override
  String get prompt;
  @override
  @JsonKey(fromJson: _parseSchedule)
  String get schedule;
  @override
  @JsonKey(name: 'state')
  String? get status;
  @override
  @JsonKey(name: 'last_run_at', fromJson: _fromTimestamp)
  DateTime? get lastRun;
  @override
  @JsonKey(name: 'next_run_at', fromJson: _fromTimestamp)
  DateTime? get nextRun;
  @override
  List<String> get skills;
  @override
  @JsonKey(name: 'provider')
  String? get modelProvider;
  @override
  @JsonKey(name: 'model')
  String? get modelName;
  @override
  String? get name;
  @override
  String? get deliver;
  @override
  @JsonKey(name: 'created_at', fromJson: _fromTimestamp)
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'last_error')
  String? get lastError;
  @override
  @JsonKey(name: 'paused_at', fromJson: _fromPausedAt, toJson: _toPausedAt)
  bool get paused;
  @override
  @JsonKey(ignore: true)
  _$$CronJobImplCopyWith<_$CronJobImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
