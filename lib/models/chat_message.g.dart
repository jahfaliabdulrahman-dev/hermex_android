// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      role: json['role'] as String,
      content: json['content'] as String,
      toolCallId: _stringFromJson(json['tool_call_id']),
      toolName: json['tool_name'] as String?,
      timestamp: _fromTimestamp(json['timestamp']),
      toolCalls: (json['tool_calls'] as List<dynamic>?)
              ?.map((e) => ToolCall.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isStreaming: json['isStreaming'] as bool? ?? false,
      id: _stringFromJson(json['id']),
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'role': instance.role,
      'content': instance.content,
      'tool_call_id': instance.toolCallId,
      'tool_name': instance.toolName,
      'timestamp': instance.timestamp?.toIso8601String(),
      'tool_calls': instance.toolCalls,
      'isStreaming': instance.isStreaming,
      'id': instance.id,
    };

_$ToolCallImpl _$$ToolCallImplFromJson(Map<String, dynamic> json) =>
    _$ToolCallImpl(
      id: json['id'] as String?,
      type: json['type'] as String?,
      function:
          ToolCallFunction.fromJson(json['function'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ToolCallImplToJson(_$ToolCallImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'function': instance.function,
    };

_$ToolCallFunctionImpl _$$ToolCallFunctionImplFromJson(
        Map<String, dynamic> json) =>
    _$ToolCallFunctionImpl(
      name: json['name'] as String,
      arguments: json['arguments'] as String? ?? '{}',
    );

Map<String, dynamic> _$$ToolCallFunctionImplToJson(
        _$ToolCallFunctionImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'arguments': instance.arguments,
    };
