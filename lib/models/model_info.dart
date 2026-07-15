import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_info.freezed.dart';
part 'model_info.g.dart';

/// Model information from GET /v1/models (OpenAI-compatible endpoint).
/// Not persisted locally — fetched from Hermes Agent API Server.
@freezed
class ModelInfo with _$ModelInfo {
  const factory ModelInfo({
    required String id,
    @Default('model') String object,
    @JsonKey(name: 'created') int? created,
    @JsonKey(name: 'owned_by') String? ownedBy,
    /// List of capability strings (e.g., ["chat", "reasoning", "vision", "tools"]).
    /// D.16: Added for model-capability-aware features (reasoning-effort, tool use).
    @Default([]) List<String> capabilities,
    /// Supported reasoning effort levels (e.g., ["none", "low", "medium", "high"]).
    /// Empty list means the model does not support reasoning-effort control.
    /// D.16 + E.20: Added for reasoning-effort / thinking control feature.
    @JsonKey(name: 'reasoning_effort')
    @Default([]) List<String> supportedReasoningEfforts,
  }) = _ModelInfo;

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);
}
