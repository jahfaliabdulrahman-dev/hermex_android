// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ApiResponse _$ApiResponseFromJson(Map<String, dynamic> json) {
  return _ApiResponse.fromJson(json);
}

/// @nodoc
mixin _$ApiResponse {
  Map<String, dynamic> get data => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ApiResponseCopyWith<ApiResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiResponseCopyWith<$Res> {
  factory $ApiResponseCopyWith(
          ApiResponse value, $Res Function(ApiResponse) then) =
      _$ApiResponseCopyWithImpl<$Res, ApiResponse>;
  @useResult
  $Res call(
      {Map<String, dynamic> data, int total, String? error, String? message});
}

/// @nodoc
class _$ApiResponseCopyWithImpl<$Res, $Val extends ApiResponse>
    implements $ApiResponseCopyWith<$Res> {
  _$ApiResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
    Object? total = null,
    Object? error = freezed,
    Object? message = freezed,
  }) {
    return _then(_value.copyWith(
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApiResponseImplCopyWith<$Res>
    implements $ApiResponseCopyWith<$Res> {
  factory _$$ApiResponseImplCopyWith(
          _$ApiResponseImpl value, $Res Function(_$ApiResponseImpl) then) =
      __$$ApiResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Map<String, dynamic> data, int total, String? error, String? message});
}

/// @nodoc
class __$$ApiResponseImplCopyWithImpl<$Res>
    extends _$ApiResponseCopyWithImpl<$Res, _$ApiResponseImpl>
    implements _$$ApiResponseImplCopyWith<$Res> {
  __$$ApiResponseImplCopyWithImpl(
      _$ApiResponseImpl _value, $Res Function(_$ApiResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
    Object? total = null,
    Object? error = freezed,
    Object? message = freezed,
  }) {
    return _then(_$ApiResponseImpl(
      data: null == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApiResponseImpl implements _ApiResponse {
  const _$ApiResponseImpl(
      {final Map<String, dynamic> data = const {},
      this.total = 0,
      this.error,
      this.message})
      : _data = data;

  factory _$ApiResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApiResponseImplFromJson(json);

  final Map<String, dynamic> _data;
  @override
  @JsonKey()
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  @JsonKey()
  final int total;
  @override
  final String? error;
  @override
  final String? message;

  @override
  String toString() {
    return 'ApiResponse(data: $data, total: $total, error: $error, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiResponseImpl &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_data), total, error, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiResponseImplCopyWith<_$ApiResponseImpl> get copyWith =>
      __$$ApiResponseImplCopyWithImpl<_$ApiResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApiResponseImplToJson(
      this,
    );
  }
}

abstract class _ApiResponse implements ApiResponse {
  const factory _ApiResponse(
      {final Map<String, dynamic> data,
      final int total,
      final String? error,
      final String? message}) = _$ApiResponseImpl;

  factory _ApiResponse.fromJson(Map<String, dynamic> json) =
      _$ApiResponseImpl.fromJson;

  @override
  Map<String, dynamic> get data;
  @override
  int get total;
  @override
  String? get error;
  @override
  String? get message;
  @override
  @JsonKey(ignore: true)
  _$$ApiResponseImplCopyWith<_$ApiResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ApiListResponse _$ApiListResponseFromJson(Map<String, dynamic> json) {
  return _ApiListResponse.fromJson(json);
}

/// @nodoc
mixin _$ApiListResponse {
  List<Map<String, dynamic>> get data => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;
  int get offset => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ApiListResponseCopyWith<ApiListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiListResponseCopyWith<$Res> {
  factory $ApiListResponseCopyWith(
          ApiListResponse value, $Res Function(ApiListResponse) then) =
      _$ApiListResponseCopyWithImpl<$Res, ApiListResponse>;
  @useResult
  $Res call(
      {List<Map<String, dynamic>> data, int total, int limit, int offset});
}

/// @nodoc
class _$ApiListResponseCopyWithImpl<$Res, $Val extends ApiListResponse>
    implements $ApiListResponseCopyWith<$Res> {
  _$ApiListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
    Object? total = null,
    Object? limit = null,
    Object? offset = null,
  }) {
    return _then(_value.copyWith(
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      offset: null == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApiListResponseImplCopyWith<$Res>
    implements $ApiListResponseCopyWith<$Res> {
  factory _$$ApiListResponseImplCopyWith(_$ApiListResponseImpl value,
          $Res Function(_$ApiListResponseImpl) then) =
      __$$ApiListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<Map<String, dynamic>> data, int total, int limit, int offset});
}

/// @nodoc
class __$$ApiListResponseImplCopyWithImpl<$Res>
    extends _$ApiListResponseCopyWithImpl<$Res, _$ApiListResponseImpl>
    implements _$$ApiListResponseImplCopyWith<$Res> {
  __$$ApiListResponseImplCopyWithImpl(
      _$ApiListResponseImpl _value, $Res Function(_$ApiListResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
    Object? total = null,
    Object? limit = null,
    Object? offset = null,
  }) {
    return _then(_$ApiListResponseImpl(
      data: null == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      offset: null == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApiListResponseImpl implements _ApiListResponse {
  const _$ApiListResponseImpl(
      {final List<Map<String, dynamic>> data = const [],
      this.total = 0,
      this.limit = 20,
      this.offset = 0})
      : _data = data;

  factory _$ApiListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApiListResponseImplFromJson(json);

  final List<Map<String, dynamic>> _data;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get data {
    if (_data is EqualUnmodifiableListView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_data);
  }

  @override
  @JsonKey()
  final int total;
  @override
  @JsonKey()
  final int limit;
  @override
  @JsonKey()
  final int offset;

  @override
  String toString() {
    return 'ApiListResponse(data: $data, total: $total, limit: $limit, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiListResponseImpl &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.offset, offset) || other.offset == offset));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_data), total, limit, offset);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiListResponseImplCopyWith<_$ApiListResponseImpl> get copyWith =>
      __$$ApiListResponseImplCopyWithImpl<_$ApiListResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApiListResponseImplToJson(
      this,
    );
  }
}

abstract class _ApiListResponse implements ApiListResponse {
  const factory _ApiListResponse(
      {final List<Map<String, dynamic>> data,
      final int total,
      final int limit,
      final int offset}) = _$ApiListResponseImpl;

  factory _ApiListResponse.fromJson(Map<String, dynamic> json) =
      _$ApiListResponseImpl.fromJson;

  @override
  List<Map<String, dynamic>> get data;
  @override
  int get total;
  @override
  int get limit;
  @override
  int get offset;
  @override
  @JsonKey(ignore: true)
  _$$ApiListResponseImplCopyWith<_$ApiListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
