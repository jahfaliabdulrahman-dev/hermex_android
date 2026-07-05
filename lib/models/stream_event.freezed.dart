// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StreamEvent _$StreamEventFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'textDelta':
      return TextDelta.fromJson(json);
    case 'toolProgress':
      return ToolProgress.fromJson(json);
    case 'done':
      return StreamDone.fromJson(json);
    case 'error':
      return StreamError.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'StreamEvent',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$StreamEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String text) textDelta,
    required TResult Function(String toolName, String status) toolProgress,
    required TResult Function() done,
    required TResult Function(String message, String? code) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String text)? textDelta,
    TResult? Function(String toolName, String status)? toolProgress,
    TResult? Function()? done,
    TResult? Function(String message, String? code)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String text)? textDelta,
    TResult Function(String toolName, String status)? toolProgress,
    TResult Function()? done,
    TResult Function(String message, String? code)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextDelta value) textDelta,
    required TResult Function(ToolProgress value) toolProgress,
    required TResult Function(StreamDone value) done,
    required TResult Function(StreamError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextDelta value)? textDelta,
    TResult? Function(ToolProgress value)? toolProgress,
    TResult? Function(StreamDone value)? done,
    TResult? Function(StreamError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextDelta value)? textDelta,
    TResult Function(ToolProgress value)? toolProgress,
    TResult Function(StreamDone value)? done,
    TResult Function(StreamError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StreamEventCopyWith<$Res> {
  factory $StreamEventCopyWith(
          StreamEvent value, $Res Function(StreamEvent) then) =
      _$StreamEventCopyWithImpl<$Res, StreamEvent>;
}

/// @nodoc
class _$StreamEventCopyWithImpl<$Res, $Val extends StreamEvent>
    implements $StreamEventCopyWith<$Res> {
  _$StreamEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$TextDeltaImplCopyWith<$Res> {
  factory _$$TextDeltaImplCopyWith(
          _$TextDeltaImpl value, $Res Function(_$TextDeltaImpl) then) =
      __$$TextDeltaImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String text});
}

/// @nodoc
class __$$TextDeltaImplCopyWithImpl<$Res>
    extends _$StreamEventCopyWithImpl<$Res, _$TextDeltaImpl>
    implements _$$TextDeltaImplCopyWith<$Res> {
  __$$TextDeltaImplCopyWithImpl(
      _$TextDeltaImpl _value, $Res Function(_$TextDeltaImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
  }) {
    return _then(_$TextDeltaImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TextDeltaImpl implements TextDelta {
  const _$TextDeltaImpl({required this.text, final String? $type})
      : $type = $type ?? 'textDelta';

  factory _$TextDeltaImpl.fromJson(Map<String, dynamic> json) =>
      _$$TextDeltaImplFromJson(json);

  @override
  final String text;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'StreamEvent.textDelta(text: $text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TextDeltaImpl &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, text);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TextDeltaImplCopyWith<_$TextDeltaImpl> get copyWith =>
      __$$TextDeltaImplCopyWithImpl<_$TextDeltaImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String text) textDelta,
    required TResult Function(String toolName, String status) toolProgress,
    required TResult Function() done,
    required TResult Function(String message, String? code) error,
  }) {
    return textDelta(text);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String text)? textDelta,
    TResult? Function(String toolName, String status)? toolProgress,
    TResult? Function()? done,
    TResult? Function(String message, String? code)? error,
  }) {
    return textDelta?.call(text);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String text)? textDelta,
    TResult Function(String toolName, String status)? toolProgress,
    TResult Function()? done,
    TResult Function(String message, String? code)? error,
    required TResult orElse(),
  }) {
    if (textDelta != null) {
      return textDelta(text);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextDelta value) textDelta,
    required TResult Function(ToolProgress value) toolProgress,
    required TResult Function(StreamDone value) done,
    required TResult Function(StreamError value) error,
  }) {
    return textDelta(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextDelta value)? textDelta,
    TResult? Function(ToolProgress value)? toolProgress,
    TResult? Function(StreamDone value)? done,
    TResult? Function(StreamError value)? error,
  }) {
    return textDelta?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextDelta value)? textDelta,
    TResult Function(ToolProgress value)? toolProgress,
    TResult Function(StreamDone value)? done,
    TResult Function(StreamError value)? error,
    required TResult orElse(),
  }) {
    if (textDelta != null) {
      return textDelta(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$TextDeltaImplToJson(
      this,
    );
  }
}

abstract class TextDelta implements StreamEvent {
  const factory TextDelta({required final String text}) = _$TextDeltaImpl;

  factory TextDelta.fromJson(Map<String, dynamic> json) =
      _$TextDeltaImpl.fromJson;

  String get text;
  @JsonKey(ignore: true)
  _$$TextDeltaImplCopyWith<_$TextDeltaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ToolProgressImplCopyWith<$Res> {
  factory _$$ToolProgressImplCopyWith(
          _$ToolProgressImpl value, $Res Function(_$ToolProgressImpl) then) =
      __$$ToolProgressImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String toolName, String status});
}

/// @nodoc
class __$$ToolProgressImplCopyWithImpl<$Res>
    extends _$StreamEventCopyWithImpl<$Res, _$ToolProgressImpl>
    implements _$$ToolProgressImplCopyWith<$Res> {
  __$$ToolProgressImplCopyWithImpl(
      _$ToolProgressImpl _value, $Res Function(_$ToolProgressImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? toolName = null,
    Object? status = null,
  }) {
    return _then(_$ToolProgressImpl(
      toolName: null == toolName
          ? _value.toolName
          : toolName // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ToolProgressImpl implements ToolProgress {
  const _$ToolProgressImpl(
      {required this.toolName, required this.status, final String? $type})
      : $type = $type ?? 'toolProgress';

  factory _$ToolProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$ToolProgressImplFromJson(json);

  @override
  final String toolName;
  @override
  final String status;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'StreamEvent.toolProgress(toolName: $toolName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolProgressImpl &&
            (identical(other.toolName, toolName) ||
                other.toolName == toolName) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, toolName, status);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolProgressImplCopyWith<_$ToolProgressImpl> get copyWith =>
      __$$ToolProgressImplCopyWithImpl<_$ToolProgressImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String text) textDelta,
    required TResult Function(String toolName, String status) toolProgress,
    required TResult Function() done,
    required TResult Function(String message, String? code) error,
  }) {
    return toolProgress(toolName, status);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String text)? textDelta,
    TResult? Function(String toolName, String status)? toolProgress,
    TResult? Function()? done,
    TResult? Function(String message, String? code)? error,
  }) {
    return toolProgress?.call(toolName, status);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String text)? textDelta,
    TResult Function(String toolName, String status)? toolProgress,
    TResult Function()? done,
    TResult Function(String message, String? code)? error,
    required TResult orElse(),
  }) {
    if (toolProgress != null) {
      return toolProgress(toolName, status);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextDelta value) textDelta,
    required TResult Function(ToolProgress value) toolProgress,
    required TResult Function(StreamDone value) done,
    required TResult Function(StreamError value) error,
  }) {
    return toolProgress(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextDelta value)? textDelta,
    TResult? Function(ToolProgress value)? toolProgress,
    TResult? Function(StreamDone value)? done,
    TResult? Function(StreamError value)? error,
  }) {
    return toolProgress?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextDelta value)? textDelta,
    TResult Function(ToolProgress value)? toolProgress,
    TResult Function(StreamDone value)? done,
    TResult Function(StreamError value)? error,
    required TResult orElse(),
  }) {
    if (toolProgress != null) {
      return toolProgress(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ToolProgressImplToJson(
      this,
    );
  }
}

abstract class ToolProgress implements StreamEvent {
  const factory ToolProgress(
      {required final String toolName,
      required final String status}) = _$ToolProgressImpl;

  factory ToolProgress.fromJson(Map<String, dynamic> json) =
      _$ToolProgressImpl.fromJson;

  String get toolName;
  String get status;
  @JsonKey(ignore: true)
  _$$ToolProgressImplCopyWith<_$ToolProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$StreamDoneImplCopyWith<$Res> {
  factory _$$StreamDoneImplCopyWith(
          _$StreamDoneImpl value, $Res Function(_$StreamDoneImpl) then) =
      __$$StreamDoneImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$StreamDoneImplCopyWithImpl<$Res>
    extends _$StreamEventCopyWithImpl<$Res, _$StreamDoneImpl>
    implements _$$StreamDoneImplCopyWith<$Res> {
  __$$StreamDoneImplCopyWithImpl(
      _$StreamDoneImpl _value, $Res Function(_$StreamDoneImpl) _then)
      : super(_value, _then);
}

/// @nodoc
@JsonSerializable()
class _$StreamDoneImpl implements StreamDone {
  const _$StreamDoneImpl({final String? $type}) : $type = $type ?? 'done';

  factory _$StreamDoneImpl.fromJson(Map<String, dynamic> json) =>
      _$$StreamDoneImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'StreamEvent.done()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$StreamDoneImpl);
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String text) textDelta,
    required TResult Function(String toolName, String status) toolProgress,
    required TResult Function() done,
    required TResult Function(String message, String? code) error,
  }) {
    return done();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String text)? textDelta,
    TResult? Function(String toolName, String status)? toolProgress,
    TResult? Function()? done,
    TResult? Function(String message, String? code)? error,
  }) {
    return done?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String text)? textDelta,
    TResult Function(String toolName, String status)? toolProgress,
    TResult Function()? done,
    TResult Function(String message, String? code)? error,
    required TResult orElse(),
  }) {
    if (done != null) {
      return done();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextDelta value) textDelta,
    required TResult Function(ToolProgress value) toolProgress,
    required TResult Function(StreamDone value) done,
    required TResult Function(StreamError value) error,
  }) {
    return done(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextDelta value)? textDelta,
    TResult? Function(ToolProgress value)? toolProgress,
    TResult? Function(StreamDone value)? done,
    TResult? Function(StreamError value)? error,
  }) {
    return done?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextDelta value)? textDelta,
    TResult Function(ToolProgress value)? toolProgress,
    TResult Function(StreamDone value)? done,
    TResult Function(StreamError value)? error,
    required TResult orElse(),
  }) {
    if (done != null) {
      return done(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$StreamDoneImplToJson(
      this,
    );
  }
}

abstract class StreamDone implements StreamEvent {
  const factory StreamDone() = _$StreamDoneImpl;

  factory StreamDone.fromJson(Map<String, dynamic> json) =
      _$StreamDoneImpl.fromJson;
}

/// @nodoc
abstract class _$$StreamErrorImplCopyWith<$Res> {
  factory _$$StreamErrorImplCopyWith(
          _$StreamErrorImpl value, $Res Function(_$StreamErrorImpl) then) =
      __$$StreamErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message, String? code});
}

/// @nodoc
class __$$StreamErrorImplCopyWithImpl<$Res>
    extends _$StreamEventCopyWithImpl<$Res, _$StreamErrorImpl>
    implements _$$StreamErrorImplCopyWith<$Res> {
  __$$StreamErrorImplCopyWithImpl(
      _$StreamErrorImpl _value, $Res Function(_$StreamErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? code = freezed,
  }) {
    return _then(_$StreamErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StreamErrorImpl implements StreamError {
  const _$StreamErrorImpl(
      {required this.message, this.code, final String? $type})
      : $type = $type ?? 'error';

  factory _$StreamErrorImpl.fromJson(Map<String, dynamic> json) =>
      _$$StreamErrorImplFromJson(json);

  @override
  final String message;
  @override
  final String? code;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'StreamEvent.error(message: $message, code: $code)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StreamErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.code, code) || other.code == code));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, message, code);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StreamErrorImplCopyWith<_$StreamErrorImpl> get copyWith =>
      __$$StreamErrorImplCopyWithImpl<_$StreamErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String text) textDelta,
    required TResult Function(String toolName, String status) toolProgress,
    required TResult Function() done,
    required TResult Function(String message, String? code) error,
  }) {
    return error(message, code);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String text)? textDelta,
    TResult? Function(String toolName, String status)? toolProgress,
    TResult? Function()? done,
    TResult? Function(String message, String? code)? error,
  }) {
    return error?.call(message, code);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String text)? textDelta,
    TResult Function(String toolName, String status)? toolProgress,
    TResult Function()? done,
    TResult Function(String message, String? code)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message, code);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextDelta value) textDelta,
    required TResult Function(ToolProgress value) toolProgress,
    required TResult Function(StreamDone value) done,
    required TResult Function(StreamError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextDelta value)? textDelta,
    TResult? Function(ToolProgress value)? toolProgress,
    TResult? Function(StreamDone value)? done,
    TResult? Function(StreamError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextDelta value)? textDelta,
    TResult Function(ToolProgress value)? toolProgress,
    TResult Function(StreamDone value)? done,
    TResult Function(StreamError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$StreamErrorImplToJson(
      this,
    );
  }
}

abstract class StreamError implements StreamEvent {
  const factory StreamError(
      {required final String message, final String? code}) = _$StreamErrorImpl;

  factory StreamError.fromJson(Map<String, dynamic> json) =
      _$StreamErrorImpl.fromJson;

  String get message;
  String? get code;
  @JsonKey(ignore: true)
  _$$StreamErrorImplCopyWith<_$StreamErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
