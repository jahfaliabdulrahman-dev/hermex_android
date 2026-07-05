import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_summary.freezed.dart';
part 'session_summary.g.dart';

/// Top-level timestamp parser — referenced by @JsonKey annotations in freezed models.
DateTime? _fromTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  return DateTime.tryParse(value.toString());
}

/// Session summary from GET /api/sessions.
/// Cached locally in Isar (CachedSession) for offline access.
@freezed
class SessionSummary with _$SessionSummary {
  const factory SessionSummary({
    required String id,
    String? title,
    @JsonKey(name: 'model_name') String? modelName,
    @JsonKey(name: 'message_count') @Default(0) int messageCount,
    @JsonKey(name: 'created_at', fromJson: _fromTimestamp) DateTime? createdAt,
    @JsonKey(name: 'last_activity', fromJson: _fromTimestamp)
    DateTime? lastActivity,
    @JsonKey(name: 'is_pinned') @Default(false) bool isPinned,
    @JsonKey(name: 'is_archived') @Default(false) bool isArchived,
    String? status,
  }) = _SessionSummary;

  factory SessionSummary.fromJson(Map<String, dynamic> json) =>
      _$SessionSummaryFromJson(json);
}
