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
  }) = _ModelInfo;

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);
}
