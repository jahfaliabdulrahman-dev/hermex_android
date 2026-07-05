import 'package:freezed_annotation/freezed_annotation.dart';

part 'stream_event.freezed.dart';
part 'stream_event.g.dart';

/// Sealed class hierarchy for SSE stream events from Hermes Agent API Server.
///
/// Events:
/// - TextDelta: incremental text from the model (choices[0].delta.content)
/// - ToolProgress: tool execution status updates
/// - StreamDone: stream completed successfully
/// - StreamError: stream terminated with an error
@freezed
sealed class StreamEvent with _$StreamEvent {
  /// Incremental text chunk from the model response.
  const factory StreamEvent.textDelta({
    required String text,
  }) = TextDelta;

  /// Tool execution progress update.
  const factory StreamEvent.toolProgress({
    required String toolName,
    required String status, // "started" | "completed"
  }) = ToolProgress;

  /// Stream completed successfully.
  const factory StreamEvent.done() = StreamDone;

  /// Stream terminated with an error.
  const factory StreamEvent.error({
    required String message,
    String? code,
  }) = StreamError;

  factory StreamEvent.fromJson(Map<String, dynamic> json) =>
      _$StreamEventFromJson(json);
}
