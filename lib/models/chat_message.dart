import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// Top-level timestamp parser — referenced by @JsonKey annotations in freezed models.
///
/// BUG-RC6-SESSION-RESTORE: the live Hermes server sends `timestamp` as a
/// float (epoch seconds with fraction, e.g. 1752629471.83). The previous
/// `is int` check missed doubles and fell through to
/// `DateTime.tryParse("1752629471.83")` → null, silently dropping every
/// timestamp. Handle any [num] as epoch seconds.
DateTime? _fromTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch((value * 1000).round());
  }
  return DateTime.tryParse(value.toString());
}

/// Tolerant string parser — referenced by @JsonKey annotations below.
///
/// BUG-RC6-SESSION-RESTORE ROOT CAUSE: the live Hermes server sends message
/// `id` as an *int* (verified on GET /api/sessions/{id}/messages: `id` was
/// int in 45/45 messages). The generated `json['id'] as String?` cast threw
/// `_TypeError: type 'int' is not a subtype of type 'String?'` for EVERY
/// message of EVERY session, which surfaced as the generic
/// "Request failed. Please check your input and try again." banner whenever
/// a session was opened from the Sessions list.
String? _stringFromJson(dynamic value) => value?.toString();

/// A single chat message from GET /api/sessions/{id}/messages.
/// Roles: "user", "assistant", "system", "tool".
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String role,
    required String content,
    @JsonKey(name: 'tool_call_id', fromJson: _stringFromJson) String? toolCallId,
    @JsonKey(name: 'tool_name') String? toolName,
    @JsonKey(name: 'timestamp', fromJson: _fromTimestamp) DateTime? timestamp,
    @JsonKey(name: 'tool_calls') @Default([]) List<ToolCall> toolCalls,
    @Default(false) bool isStreaming,
    // Server sends numeric ids — parse tolerantly (see _stringFromJson).
    @JsonKey(fromJson: _stringFromJson) String? id,
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
