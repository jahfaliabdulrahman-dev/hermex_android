// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkspaceEntry _$WorkspaceEntryFromJson(Map<String, dynamic> json) {
  return _WorkspaceEntry.fromJson(json);
}

/// @nodoc
mixin _$WorkspaceEntry {
  String get name => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError; // 'file' | 'directory'
  int get size => throw _privateConstructorUsedError;
  @JsonKey(name: 'modified_at')
  String? get modifiedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_binary')
  bool get isBinary => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkspaceEntryCopyWith<WorkspaceEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkspaceEntryCopyWith<$Res> {
  factory $WorkspaceEntryCopyWith(
          WorkspaceEntry value, $Res Function(WorkspaceEntry) then) =
      _$WorkspaceEntryCopyWithImpl<$Res, WorkspaceEntry>;
  @useResult
  $Res call(
      {String name,
      String type,
      int size,
      @JsonKey(name: 'modified_at') String? modifiedAt,
      @JsonKey(name: 'is_binary') bool isBinary});
}

/// @nodoc
class _$WorkspaceEntryCopyWithImpl<$Res, $Val extends WorkspaceEntry>
    implements $WorkspaceEntryCopyWith<$Res> {
  _$WorkspaceEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? type = null,
    Object? size = null,
    Object? modifiedAt = freezed,
    Object? isBinary = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      modifiedAt: freezed == modifiedAt
          ? _value.modifiedAt
          : modifiedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      isBinary: null == isBinary
          ? _value.isBinary
          : isBinary // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkspaceEntryImplCopyWith<$Res>
    implements $WorkspaceEntryCopyWith<$Res> {
  factory _$$WorkspaceEntryImplCopyWith(_$WorkspaceEntryImpl value,
          $Res Function(_$WorkspaceEntryImpl) then) =
      __$$WorkspaceEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String type,
      int size,
      @JsonKey(name: 'modified_at') String? modifiedAt,
      @JsonKey(name: 'is_binary') bool isBinary});
}

/// @nodoc
class __$$WorkspaceEntryImplCopyWithImpl<$Res>
    extends _$WorkspaceEntryCopyWithImpl<$Res, _$WorkspaceEntryImpl>
    implements _$$WorkspaceEntryImplCopyWith<$Res> {
  __$$WorkspaceEntryImplCopyWithImpl(
      _$WorkspaceEntryImpl _value, $Res Function(_$WorkspaceEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? type = null,
    Object? size = null,
    Object? modifiedAt = freezed,
    Object? isBinary = null,
  }) {
    return _then(_$WorkspaceEntryImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      modifiedAt: freezed == modifiedAt
          ? _value.modifiedAt
          : modifiedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      isBinary: null == isBinary
          ? _value.isBinary
          : isBinary // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkspaceEntryImpl implements _WorkspaceEntry {
  const _$WorkspaceEntryImpl(
      {required this.name,
      this.type = 'file',
      this.size = 0,
      @JsonKey(name: 'modified_at') this.modifiedAt,
      @JsonKey(name: 'is_binary') this.isBinary = false});

  factory _$WorkspaceEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkspaceEntryImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey()
  final String type;
// 'file' | 'directory'
  @override
  @JsonKey()
  final int size;
  @override
  @JsonKey(name: 'modified_at')
  final String? modifiedAt;
  @override
  @JsonKey(name: 'is_binary')
  final bool isBinary;

  @override
  String toString() {
    return 'WorkspaceEntry(name: $name, type: $type, size: $size, modifiedAt: $modifiedAt, isBinary: $isBinary)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkspaceEntryImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.modifiedAt, modifiedAt) ||
                other.modifiedAt == modifiedAt) &&
            (identical(other.isBinary, isBinary) ||
                other.isBinary == isBinary));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, type, size, modifiedAt, isBinary);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkspaceEntryImplCopyWith<_$WorkspaceEntryImpl> get copyWith =>
      __$$WorkspaceEntryImplCopyWithImpl<_$WorkspaceEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkspaceEntryImplToJson(
      this,
    );
  }
}

abstract class _WorkspaceEntry implements WorkspaceEntry {
  const factory _WorkspaceEntry(
      {required final String name,
      final String type,
      final int size,
      @JsonKey(name: 'modified_at') final String? modifiedAt,
      @JsonKey(name: 'is_binary') final bool isBinary}) = _$WorkspaceEntryImpl;

  factory _WorkspaceEntry.fromJson(Map<String, dynamic> json) =
      _$WorkspaceEntryImpl.fromJson;

  @override
  String get name;
  @override
  String get type;
  @override // 'file' | 'directory'
  int get size;
  @override
  @JsonKey(name: 'modified_at')
  String? get modifiedAt;
  @override
  @JsonKey(name: 'is_binary')
  bool get isBinary;
  @override
  @JsonKey(ignore: true)
  _$$WorkspaceEntryImplCopyWith<_$WorkspaceEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
