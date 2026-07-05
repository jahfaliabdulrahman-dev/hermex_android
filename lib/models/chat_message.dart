import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// Top-level timestamp parser — referenced by @JsonKey annotations in freezed models.
DateTime? _fromTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  return DateTime.tryParse(value.toString());
}

/// A single chat message from GET /api/sessions/{id}/messages.
/// Roles: "user", "assistant", "system", "tool".
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String role,
    required String content,
    @JsonKey(name: 'tool_call_id') String? toolCallId,
    @JsonKey(name: 'tool_name') String? toolName,
    @JsonKey(name: 'timestamp', fromJson: _fromTimestamp) DateTime? timestamp,
    @JsonKey(name: 'tool_calls') @Default([]) List<ToolCall> toolCalls,
    @Default(false) bool isStreaming,
    String? id,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

/// A tool call within a chat message (OpenAI tool_choice format).
@freezed
class ToolCall with _$ToolCall {
  const factory ToolCall({
    String? id,
    String? type,
    required ToolCallFunction function,
  }) = _ToolCall;

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFromJson(json);
}

/// Function definition within a tool call.
@freezed
class ToolCallFunction with _$ToolCallFunction {
  const factory ToolCallFunction({
    required String name,
    @Default('{}') String arguments,
  }) = _ToolCallFunction;

  factory ToolCallFunction.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFunctionFromJson(json);
}
