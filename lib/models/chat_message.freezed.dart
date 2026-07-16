// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) {
  return _ChatMessage.fromJson(json);
}

/// @nodoc
mixin _$ChatMessage {
  String get role => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'tool_call_id', fromJson: _stringFromJson)
  String? get toolCallId => throw _privateConstructorUsedError;
  @JsonKey(name: 'tool_name')
  String? get toolName => throw _privateConstructorUsedError;
  @JsonKey(name: 'timestamp', fromJson: _fromTimestamp)
  DateTime? get timestamp => throw _privateConstructorUsedError;
  @JsonKey(name: 'tool_calls')
  List<ToolCall> get toolCalls => throw _privateConstructorUsedError;
  bool get isStreaming =>
      throw _privateConstructorUsedError; // Server sends numeric ids — parse tolerantly (see _stringFromJson).
  @JsonKey(fromJson: _stringFromJson)
  String? get id => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
          ChatMessage value, $Res Function(ChatMessage) then) =
      _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call(
      {String role,
      String content,
      @JsonKey(name: 'tool_call_id', fromJson: _stringFromJson)
      String? toolCallId,
      @JsonKey(name: 'tool_name') String? toolName,
      @JsonKey(name: 'timestamp', fromJson: _fromTimestamp) DateTime? timestamp,
      @JsonKey(name: 'tool_calls') List<ToolCall> toolCalls,
      bool isStreaming,
      @JsonKey(fromJson: _stringFromJson) String? id});
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? role = null,
    Object? content = null,
    Object? toolCallId = freezed,
    Object? toolName = freezed,
    Object? timestamp = freezed,
    Object? toolCalls = null,
    Object? isStreaming = null,
    Object? id = freezed,
  }) {
    return _then(_value.copyWith(
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      toolCallId: freezed == toolCallId
          ? _value.toolCallId
          : toolCallId // ignore: cast_nullable_to_non_nullable
              as String?,
      toolName: freezed == toolName
          ? _value.toolName
          : toolName // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      toolCalls: null == toolCalls
          ? _value.toolCalls
          : toolCalls // ignore: cast_nullable_to_non_nullable
              as List<ToolCall>,
      isStreaming: null == isStreaming
          ? _value.isStreaming
          : isStreaming // ignore: cast_nullable_to_non_nullable
              as bool,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
          _$ChatMessageImpl value, $Res Function(_$ChatMessageImpl) then) =
      __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String role,
      String content,
      @JsonKey(name: 'tool_call_id', fromJson: _stringFromJson)
      String? toolCallId,
      @JsonKey(name: 'tool_name') String? toolName,
      @JsonKey(name: 'timestamp', fromJson: _fromTimestamp) DateTime? timestamp,
      @JsonKey(name: 'tool_calls') List<ToolCall> toolCalls,
      bool isStreaming,
      @JsonKey(fromJson: _stringFromJson) String? id});
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
      _$ChatMessageImpl _value, $Res Function(_$ChatMessageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? role = null,
    Object? content = null,
    Object? toolCallId = freezed,
    Object? toolName = freezed,
    Object? timestamp = freezed,
    Object? toolCalls = null,
    Object? isStreaming = null,
    Object? id = freezed,
  }) {
    return _then(_$ChatMessageImpl(
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      toolCallId: freezed == toolCallId
          ? _value.toolCallId
          : toolCallId // ignore: cast_nullable_to_non_nullable
              as String?,
      toolName: freezed == toolName
          ? _value.toolName
          : toolName // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      toolCalls: null == toolCalls
          ? _value._toolCalls
          : toolCalls // ignore: cast_nullable_to_non_nullable
              as List<ToolCall>,
      isStreaming: null == isStreaming
          ? _value.isStreaming
          : isStreaming // ignore: cast_nullable_to_non_nullable
              as bool,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatMessageImpl implements _ChatMessage {
  const _$ChatMessageImpl(
      {required this.role,
      required this.content,
      @JsonKey(name: 'tool_call_id', fromJson: _stringFromJson) this.toolCallId,
      @JsonKey(name: 'tool_name') this.toolName,
      @JsonKey(name: 'timestamp', fromJson: _fromTimestamp) this.timestamp,
      @JsonKey(name: 'tool_calls') final List<ToolCall> toolCalls = const [],
      this.isStreaming = false,
      @JsonKey(fromJson: _stringFromJson) this.id})
      : _toolCalls = toolCalls;

  factory _$ChatMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageImplFromJson(json);

  @override
  final String role;
  @override
  final String content;
  @override
  @JsonKey(name: 'tool_call_id', fromJson: _stringFromJson)
  final String? toolCallId;
  @override
  @JsonKey(name: 'tool_name')
  final String? toolName;
  @override
  @JsonKey(name: 'timestamp', fromJson: _fromTimestamp)
  final DateTime? timestamp;
  final List<ToolCall> _toolCalls;
  @override
  @JsonKey(name: 'tool_calls')
  List<ToolCall> get toolCalls {
    if (_toolCalls is EqualUnmodifiableListView) return _toolCalls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_toolCalls);
  }

  @override
  @JsonKey()
  final bool isStreaming;
// Server sends numeric ids — parse tolerantly (see _stringFromJson).
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? id;

  @override
  String toString() {
    return 'ChatMessage(role: $role, content: $content, toolCallId: $toolCallId, toolName: $toolName, timestamp: $timestamp, toolCalls: $toolCalls, isStreaming: $isStreaming, id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.toolCallId, toolCallId) ||
                other.toolCallId == toolCallId) &&
            (identical(other.toolName, toolName) ||
                other.toolName == toolName) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            const DeepCollectionEquality()
                .equals(other._toolCalls, _toolCalls) &&
            (identical(other.isStreaming, isStreaming) ||
                other.isStreaming == isStreaming) &&
            (identical(other.id, id) || other.id == id));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      role,
      content,
      toolCallId,
      toolName,
      timestamp,
      const DeepCollectionEquality().hash(_toolCalls),
      isStreaming,
      id);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageImplToJson(
      this,
    );
  }
}

abstract class _ChatMessage implements ChatMessage {
  const factory _ChatMessage(
          {required final String role,
          required final String content,
          @JsonKey(name: 'tool_call_id', fromJson: _stringFromJson)
          final String? toolCallId,
          @JsonKey(name: 'tool_name') final String? toolName,
          @JsonKey(name: 'timestamp', fromJson: _fromTimestamp)
          final DateTime? timestamp,
          @JsonKey(name: 'tool_calls') final List<ToolCall> toolCalls,
          final bool isStreaming,
          @JsonKey(fromJson: _stringFromJson) final String? id}) =
      _$ChatMessageImpl;

  factory _ChatMessage.fromJson(Map<String, dynamic> json) =
      _$ChatMessageImpl.fromJson;

  @override
  String get role;
  @override
  String get content;
  @override
  @JsonKey(name: 'tool_call_id', fromJson: _stringFromJson)
  String? get toolCallId;
  @override
  @JsonKey(name: 'tool_name')
  String? get toolName;
  @override
  @JsonKey(name: 'timestamp', fromJson: _fromTimestamp)
  DateTime? get timestamp;
  @override
  @JsonKey(name: 'tool_calls')
  List<ToolCall> get toolCalls;
  @override
  bool get isStreaming;
  @override // Server sends numeric ids — parse tolerantly (see _stringFromJson).
  @JsonKey(fromJson: _stringFromJson)
  String? get id;
  @override
  @JsonKey(ignore: true)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ToolCall _$ToolCallFromJson(Map<String, dynamic> json) {
  return _ToolCall.fromJson(json);
}

/// @nodoc
mixin _$ToolCall {
  String? get id => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;
  ToolCallFunction get function => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ToolCallCopyWith<ToolCall> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToolCallCopyWith<$Res> {
  factory $ToolCallCopyWith(ToolCall value, $Res Function(ToolCall) then) =
      _$ToolCallCopyWithImpl<$Res, ToolCall>;
  @useResult
  $Res call({String? id, String? type, ToolCallFunction function});

  $ToolCallFunctionCopyWith<$Res> get function;
}

/// @nodoc
class _$ToolCallCopyWithImpl<$Res, $Val extends ToolCall>
    implements $ToolCallCopyWith<$Res> {
  _$ToolCallCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? type = freezed,
    Object? function = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      function: null == function
          ? _value.function
          : function // ignore: cast_nullable_to_non_nullable
              as ToolCallFunction,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ToolCallFunctionCopyWith<$Res> get function {
    return $ToolCallFunctionCopyWith<$Res>(_value.function, (value) {
      return _then(_value.copyWith(function: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ToolCallImplCopyWith<$Res>
    implements $ToolCallCopyWith<$Res> {
  factory _$$ToolCallImplCopyWith(
          _$ToolCallImpl value, $Res Function(_$ToolCallImpl) then) =
      __$$ToolCallImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? id, String? type, ToolCallFunction function});

  @override
  $ToolCallFunctionCopyWith<$Res> get function;
}

/// @nodoc
class __$$ToolCallImplCopyWithImpl<$Res>
    extends _$ToolCallCopyWithImpl<$Res, _$ToolCallImpl>
    implements _$$ToolCallImplCopyWith<$Res> {
  __$$ToolCallImplCopyWithImpl(
      _$ToolCallImpl _value, $Res Function(_$ToolCallImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? type = freezed,
    Object? function = null,
  }) {
    return _then(_$ToolCallImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      function: null == function
          ? _value.function
          : function // ignore: cast_nullable_to_non_nullable
              as ToolCallFunction,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ToolCallImpl implements _ToolCall {
  const _$ToolCallImpl({this.id, this.type, required this.function});

  factory _$ToolCallImpl.fromJson(Map<String, dynamic> json) =>
      _$$ToolCallImplFromJson(json);

  @override
  final String? id;
  @override
  final String? type;
  @override
  final ToolCallFunction function;

  @override
  String toString() {
    return 'ToolCall(id: $id, type: $type, function: $function)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolCallImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.function, function) ||
                other.function == function));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, type, function);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolCallImplCopyWith<_$ToolCallImpl> get copyWith =>
      __$$ToolCallImplCopyWithImpl<_$ToolCallImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ToolCallImplToJson(
      this,
    );
  }
}

abstract class _ToolCall implements ToolCall {
  const factory _ToolCall(
      {final String? id,
      final String? type,
      required final ToolCallFunction function}) = _$ToolCallImpl;

  factory _ToolCall.fromJson(Map<String, dynamic> json) =
      _$ToolCallImpl.fromJson;

  @override
  String? get id;
  @override
  String? get type;
  @override
  ToolCallFunction get function;
  @override
  @JsonKey(ignore: true)
  _$$ToolCallImplCopyWith<_$ToolCallImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ToolCallFunction _$ToolCallFunctionFromJson(Map<String, dynamic> json) {
  return _ToolCallFunction.fromJson(json);
}

/// @nodoc
mixin _$ToolCallFunction {
  String get name => throw _privateConstructorUsedError;
  String get arguments => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ToolCallFunctionCopyWith<ToolCallFunction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToolCallFunctionCopyWith<$Res> {
  factory $ToolCallFunctionCopyWith(
          ToolCallFunction value, $Res Function(ToolCallFunction) then) =
      _$ToolCallFunctionCopyWithImpl<$Res, ToolCallFunction>;
  @useResult
  $Res call({String name, String arguments});
}

/// @nodoc
class _$ToolCallFunctionCopyWithImpl<$Res, $Val extends ToolCallFunction>
    implements $ToolCallFunctionCopyWith<$Res> {
  _$ToolCallFunctionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? arguments = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      arguments: null == arguments
          ? _value.arguments
          : arguments // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ToolCallFunctionImplCopyWith<$Res>
    implements $ToolCallFunctionCopyWith<$Res> {
  factory _$$ToolCallFunctionImplCopyWith(_$ToolCallFunctionImpl value,
          $Res Function(_$ToolCallFunctionImpl) then) =
      __$$ToolCallFunctionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String arguments});
}

/// @nodoc
class __$$ToolCallFunctionImplCopyWithImpl<$Res>
    extends _$ToolCallFunctionCopyWithImpl<$Res, _$ToolCallFunctionImpl>
    implements _$$ToolCallFunctionImplCopyWith<$Res> {
  __$$ToolCallFunctionImplCopyWithImpl(_$ToolCallFunctionImpl _value,
      $Res Function(_$ToolCallFunctionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? arguments = null,
  }) {
    return _then(_$ToolCallFunctionImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      arguments: null == arguments
          ? _value.arguments
          : arguments // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ToolCallFunctionImpl implements _ToolCallFunction {
  const _$ToolCallFunctionImpl({required this.name, this.arguments = '{}'});

  factory _$ToolCallFunctionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ToolCallFunctionImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey()
  final String arguments;

  @override
  String toString() {
    return 'ToolCallFunction(name: $name, arguments: $arguments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolCallFunctionImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.arguments, arguments) ||
                other.arguments == arguments));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, arguments);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolCallFunctionImplCopyWith<_$ToolCallFunctionImpl> get copyWith =>
      __$$ToolCallFunctionImplCopyWithImpl<_$ToolCallFunctionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ToolCallFunctionImplToJson(
      this,
    );
  }
}

abstract class _ToolCallFunction implements ToolCallFunction {
  const factory _ToolCallFunction(
      {required final String name,
      final String arguments}) = _$ToolCallFunctionImpl;

  factory _ToolCallFunction.fromJson(Map<String, dynamic> json) =
      _$ToolCallFunctionImpl.fromJson;

  @override
  String get name;
  @override
  String get arguments;
  @override
  @JsonKey(ignore: true)
  _$$ToolCallFunctionImplCopyWith<_$ToolCallFunctionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
