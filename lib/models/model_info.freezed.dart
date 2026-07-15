// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ModelInfo _$ModelInfoFromJson(Map<String, dynamic> json) {
  return _ModelInfo.fromJson(json);
}

/// @nodoc
mixin _$ModelInfo {
  String get id => throw _privateConstructorUsedError;
  String get object => throw _privateConstructorUsedError;
  @JsonKey(name: 'created')
  int? get created => throw _privateConstructorUsedError;
  @JsonKey(name: 'owned_by')
  String? get ownedBy => throw _privateConstructorUsedError;

  /// List of capability strings (e.g., ["chat", "reasoning", "vision", "tools"]).
  /// D.16: Added for model-capability-aware features (reasoning-effort, tool use).
  List<String> get capabilities => throw _privateConstructorUsedError;

  /// Supported reasoning effort levels (e.g., ["none", "low", "medium", "high"]).
  /// Empty list means the model does not support reasoning-effort control.
  /// D.16 + E.20: Added for reasoning-effort / thinking control feature.
  @JsonKey(name: 'reasoning_effort')
  List<String> get supportedReasoningEfforts =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ModelInfoCopyWith<ModelInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelInfoCopyWith<$Res> {
  factory $ModelInfoCopyWith(ModelInfo value, $Res Function(ModelInfo) then) =
      _$ModelInfoCopyWithImpl<$Res, ModelInfo>;
  @useResult
  $Res call(
      {String id,
      String object,
      @JsonKey(name: 'created') int? created,
      @JsonKey(name: 'owned_by') String? ownedBy,
      List<String> capabilities,
      @JsonKey(name: 'reasoning_effort')
      List<String> supportedReasoningEfforts});
}

/// @nodoc
class _$ModelInfoCopyWithImpl<$Res, $Val extends ModelInfo>
    implements $ModelInfoCopyWith<$Res> {
  _$ModelInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? object = null,
    Object? created = freezed,
    Object? ownedBy = freezed,
    Object? capabilities = null,
    Object? supportedReasoningEfforts = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      object: null == object
          ? _value.object
          : object // ignore: cast_nullable_to_non_nullable
              as String,
      created: freezed == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as int?,
      ownedBy: freezed == ownedBy
          ? _value.ownedBy
          : ownedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      capabilities: null == capabilities
          ? _value.capabilities
          : capabilities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      supportedReasoningEfforts: null == supportedReasoningEfforts
          ? _value.supportedReasoningEfforts
          : supportedReasoningEfforts // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModelInfoImplCopyWith<$Res>
    implements $ModelInfoCopyWith<$Res> {
  factory _$$ModelInfoImplCopyWith(
          _$ModelInfoImpl value, $Res Function(_$ModelInfoImpl) then) =
      __$$ModelInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String object,
      @JsonKey(name: 'created') int? created,
      @JsonKey(name: 'owned_by') String? ownedBy,
      List<String> capabilities,
      @JsonKey(name: 'reasoning_effort')
      List<String> supportedReasoningEfforts});
}

/// @nodoc
class __$$ModelInfoImplCopyWithImpl<$Res>
    extends _$ModelInfoCopyWithImpl<$Res, _$ModelInfoImpl>
    implements _$$ModelInfoImplCopyWith<$Res> {
  __$$ModelInfoImplCopyWithImpl(
      _$ModelInfoImpl _value, $Res Function(_$ModelInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? object = null,
    Object? created = freezed,
    Object? ownedBy = freezed,
    Object? capabilities = null,
    Object? supportedReasoningEfforts = null,
  }) {
    return _then(_$ModelInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      object: null == object
          ? _value.object
          : object // ignore: cast_nullable_to_non_nullable
              as String,
      created: freezed == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as int?,
      ownedBy: freezed == ownedBy
          ? _value.ownedBy
          : ownedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      capabilities: null == capabilities
          ? _value._capabilities
          : capabilities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      supportedReasoningEfforts: null == supportedReasoningEfforts
          ? _value._supportedReasoningEfforts
          : supportedReasoningEfforts // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelInfoImpl implements _ModelInfo {
  const _$ModelInfoImpl(
      {required this.id,
      this.object = 'model',
      @JsonKey(name: 'created') this.created,
      @JsonKey(name: 'owned_by') this.ownedBy,
      final List<String> capabilities = const [],
      @JsonKey(name: 'reasoning_effort')
      final List<String> supportedReasoningEfforts = const []})
      : _capabilities = capabilities,
        _supportedReasoningEfforts = supportedReasoningEfforts;

  factory _$ModelInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModelInfoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String object;
  @override
  @JsonKey(name: 'created')
  final int? created;
  @override
  @JsonKey(name: 'owned_by')
  final String? ownedBy;

  /// List of capability strings (e.g., ["chat", "reasoning", "vision", "tools"]).
  /// D.16: Added for model-capability-aware features (reasoning-effort, tool use).
  final List<String> _capabilities;

  /// List of capability strings (e.g., ["chat", "reasoning", "vision", "tools"]).
  /// D.16: Added for model-capability-aware features (reasoning-effort, tool use).
  @override
  @JsonKey()
  List<String> get capabilities {
    if (_capabilities is EqualUnmodifiableListView) return _capabilities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_capabilities);
  }

  /// Supported reasoning effort levels (e.g., ["none", "low", "medium", "high"]).
  /// Empty list means the model does not support reasoning-effort control.
  /// D.16 + E.20: Added for reasoning-effort / thinking control feature.
  final List<String> _supportedReasoningEfforts;

  /// Supported reasoning effort levels (e.g., ["none", "low", "medium", "high"]).
  /// Empty list means the model does not support reasoning-effort control.
  /// D.16 + E.20: Added for reasoning-effort / thinking control feature.
  @override
  @JsonKey(name: 'reasoning_effort')
  List<String> get supportedReasoningEfforts {
    if (_supportedReasoningEfforts is EqualUnmodifiableListView)
      return _supportedReasoningEfforts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_supportedReasoningEfforts);
  }

  @override
  String toString() {
    return 'ModelInfo(id: $id, object: $object, created: $created, ownedBy: $ownedBy, capabilities: $capabilities, supportedReasoningEfforts: $supportedReasoningEfforts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.object, object) || other.object == object) &&
            (identical(other.created, created) || other.created == created) &&
            (identical(other.ownedBy, ownedBy) || other.ownedBy == ownedBy) &&
            const DeepCollectionEquality()
                .equals(other._capabilities, _capabilities) &&
            const DeepCollectionEquality().equals(
                other._supportedReasoningEfforts, _supportedReasoningEfforts));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      object,
      created,
      ownedBy,
      const DeepCollectionEquality().hash(_capabilities),
      const DeepCollectionEquality().hash(_supportedReasoningEfforts));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelInfoImplCopyWith<_$ModelInfoImpl> get copyWith =>
      __$$ModelInfoImplCopyWithImpl<_$ModelInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModelInfoImplToJson(
      this,
    );
  }
}

abstract class _ModelInfo implements ModelInfo {
  const factory _ModelInfo(
      {required final String id,
      final String object,
      @JsonKey(name: 'created') final int? created,
      @JsonKey(name: 'owned_by') final String? ownedBy,
      final List<String> capabilities,
      @JsonKey(name: 'reasoning_effort')
      final List<String> supportedReasoningEfforts}) = _$ModelInfoImpl;

  factory _ModelInfo.fromJson(Map<String, dynamic> json) =
      _$ModelInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get object;
  @override
  @JsonKey(name: 'created')
  int? get created;
  @override
  @JsonKey(name: 'owned_by')
  String? get ownedBy;
  @override

  /// List of capability strings (e.g., ["chat", "reasoning", "vision", "tools"]).
  /// D.16: Added for model-capability-aware features (reasoning-effort, tool use).
  List<String> get capabilities;
  @override

  /// Supported reasoning effort levels (e.g., ["none", "low", "medium", "high"]).
  /// Empty list means the model does not support reasoning-effort control.
  /// D.16 + E.20: Added for reasoning-effort / thinking control feature.
  @JsonKey(name: 'reasoning_effort')
  List<String> get supportedReasoningEfforts;
  @override
  @JsonKey(ignore: true)
  _$$ModelInfoImplCopyWith<_$ModelInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
