// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SessionSummary _$SessionSummaryFromJson(Map<String, dynamic> json) {
  return _SessionSummary.fromJson(json);
}

/// @nodoc
mixin _$SessionSummary {
  String get id => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'model_name')
  String? get modelName => throw _privateConstructorUsedError;
  @JsonKey(name: 'message_count')
  int get messageCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at', fromJson: _fromTimestamp)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_activity', fromJson: _fromTimestamp)
  DateTime? get lastActivity => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_pinned')
  bool get isPinned => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_archived')
  bool get isArchived => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SessionSummaryCopyWith<SessionSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionSummaryCopyWith<$Res> {
  factory $SessionSummaryCopyWith(
          SessionSummary value, $Res Function(SessionSummary) then) =
      _$SessionSummaryCopyWithImpl<$Res, SessionSummary>;
  @useResult
  $Res call(
      {String id,
      String? title,
      @JsonKey(name: 'model_name') String? modelName,
      @JsonKey(name: 'message_count') int messageCount,
      @JsonKey(name: 'created_at', fromJson: _fromTimestamp)
      DateTime? createdAt,
      @JsonKey(name: 'last_activity', fromJson: _fromTimestamp)
      DateTime? lastActivity,
      @JsonKey(name: 'is_pinned') bool isPinned,
      @JsonKey(name: 'is_archived') bool isArchived,
      String? status});
}

/// @nodoc
class _$SessionSummaryCopyWithImpl<$Res, $Val extends SessionSummary>
    implements $SessionSummaryCopyWith<$Res> {
  _$SessionSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = freezed,
    Object? modelName = freezed,
    Object? messageCount = null,
    Object? createdAt = freezed,
    Object? lastActivity = freezed,
    Object? isPinned = null,
    Object? isArchived = null,
    Object? status = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      modelName: freezed == modelName
          ? _value.modelName
          : modelName // ignore: cast_nullable_to_non_nullable
              as String?,
      messageCount: null == messageCount
          ? _value.messageCount
          : messageCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastActivity: freezed == lastActivity
          ? _value.lastActivity
          : lastActivity // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isPinned: null == isPinned
          ? _value.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      isArchived: null == isArchived
          ? _value.isArchived
          : isArchived // ignore: cast_nullable_to_non_nullable
              as bool,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SessionSummaryImplCopyWith<$Res>
    implements $SessionSummaryCopyWith<$Res> {
  factory _$$SessionSummaryImplCopyWith(_$SessionSummaryImpl value,
          $Res Function(_$SessionSummaryImpl) then) =
      __$$SessionSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? title,
      @JsonKey(name: 'model_name') String? modelName,
      @JsonKey(name: 'message_count') int messageCount,
      @JsonKey(name: 'created_at', fromJson: _fromTimestamp)
      DateTime? createdAt,
      @JsonKey(name: 'last_activity', fromJson: _fromTimestamp)
      DateTime? lastActivity,
      @JsonKey(name: 'is_pinned') bool isPinned,
      @JsonKey(name: 'is_archived') bool isArchived,
      String? status});
}

/// @nodoc
class __$$SessionSummaryImplCopyWithImpl<$Res>
    extends _$SessionSummaryCopyWithImpl<$Res, _$SessionSummaryImpl>
    implements _$$SessionSummaryImplCopyWith<$Res> {
  __$$SessionSummaryImplCopyWithImpl(
      _$SessionSummaryImpl _value, $Res Function(_$SessionSummaryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = freezed,
    Object? modelName = freezed,
    Object? messageCount = null,
    Object? createdAt = freezed,
    Object? lastActivity = freezed,
    Object? isPinned = null,
    Object? isArchived = null,
    Object? status = freezed,
  }) {
    return _then(_$SessionSummaryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      modelName: freezed == modelName
          ? _value.modelName
          : modelName // ignore: cast_nullable_to_non_nullable
              as String?,
      messageCount: null == messageCount
          ? _value.messageCount
          : messageCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastActivity: freezed == lastActivity
          ? _value.lastActivity
          : lastActivity // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isPinned: null == isPinned
          ? _value.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      isArchived: null == isArchived
          ? _value.isArchived
          : isArchived // ignore: cast_nullable_to_non_nullable
              as bool,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionSummaryImpl implements _SessionSummary {
  const _$SessionSummaryImpl(
      {required this.id,
      this.title,
      @JsonKey(name: 'model_name') this.modelName,
      @JsonKey(name: 'message_count') this.messageCount = 0,
      @JsonKey(name: 'created_at', fromJson: _fromTimestamp) this.createdAt,
      @JsonKey(name: 'last_activity', fromJson: _fromTimestamp)
      this.lastActivity,
      @JsonKey(name: 'is_pinned') this.isPinned = false,
      @JsonKey(name: 'is_archived') this.isArchived = false,
      this.status});

  factory _$SessionSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionSummaryImplFromJson(json);

  @override
  final String id;
  @override
  final String? title;
  @override
  @JsonKey(name: 'model_name')
  final String? modelName;
  @override
  @JsonKey(name: 'message_count')
  final int messageCount;
  @override
  @JsonKey(name: 'created_at', fromJson: _fromTimestamp)
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'last_activity', fromJson: _fromTimestamp)
  final DateTime? lastActivity;
  @override
  @JsonKey(name: 'is_pinned')
  final bool isPinned;
  @override
  @JsonKey(name: 'is_archived')
  final bool isArchived;
  @override
  final String? status;

  @override
  String toString() {
    return 'SessionSummary(id: $id, title: $title, modelName: $modelName, messageCount: $messageCount, createdAt: $createdAt, lastActivity: $lastActivity, isPinned: $isPinned, isArchived: $isArchived, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionSummaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.modelName, modelName) ||
                other.modelName == modelName) &&
            (identical(other.messageCount, messageCount) ||
                other.messageCount == messageCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastActivity, lastActivity) ||
                other.lastActivity == lastActivity) &&
            (identical(other.isPinned, isPinned) ||
                other.isPinned == isPinned) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, modelName,
      messageCount, createdAt, lastActivity, isPinned, isArchived, status);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionSummaryImplCopyWith<_$SessionSummaryImpl> get copyWith =>
      __$$SessionSummaryImplCopyWithImpl<_$SessionSummaryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionSummaryImplToJson(
      this,
    );
  }
}

abstract class _SessionSummary implements SessionSummary {
  const factory _SessionSummary(
      {required final String id,
      final String? title,
      @JsonKey(name: 'model_name') final String? modelName,
      @JsonKey(name: 'message_count') final int messageCount,
      @JsonKey(name: 'created_at', fromJson: _fromTimestamp)
      final DateTime? createdAt,
      @JsonKey(name: 'last_activity', fromJson: _fromTimestamp)
      final DateTime? lastActivity,
      @JsonKey(name: 'is_pinned') final bool isPinned,
      @JsonKey(name: 'is_archived') final bool isArchived,
      final String? status}) = _$SessionSummaryImpl;

  factory _SessionSummary.fromJson(Map<String, dynamic> json) =
      _$SessionSummaryImpl.fromJson;

  @override
  String get id;
  @override
  String? get title;
  @override
  @JsonKey(name: 'model_name')
  String? get modelName;
  @override
  @JsonKey(name: 'message_count')
  int get messageCount;
  @override
  @JsonKey(name: 'created_at', fromJson: _fromTimestamp)
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'last_activity', fromJson: _fromTimestamp)
  DateTime? get lastActivity;
  @override
  @JsonKey(name: 'is_pinned')
  bool get isPinned;
  @override
  @JsonKey(name: 'is_archived')
  bool get isArchived;
  @override
  String? get status;
  @override
  @JsonKey(ignore: true)
  _$$SessionSummaryImplCopyWith<_$SessionSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
