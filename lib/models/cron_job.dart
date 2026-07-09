import 'package:freezed_annotation/freezed_annotation.dart';

part 'cron_job.freezed.dart';
part 'cron_job.g.dart';

/// Top-level timestamp parser — referenced by @JsonKey annotations in freezed models.
DateTime? _fromTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  return DateTime.tryParse(value.toString());
}

/// Parse the API `schedule` field which can be either:
/// - A string like "0 4 * * 0" (from older API / manual input)
/// - An object like {"kind": "cron", "expr": "0 4 * * 0", "display": "0 4 * * 0"}
///   or {"kind": "interval", "minutes": 2, "display": "every 2m"}
///
/// Always returns the human-readable display form.
String _parseSchedule(dynamic value) {
  if (value is String) return value;
  if (value is Map<String, dynamic>) {
    return (value['display'] ?? value['expr'] ?? value.toString()) as String;
  }
  return value.toString();
}

/// API has `paused_at` (DateTime? where null = not paused) instead of `paused` bool.
/// Converts: null → false (not paused), non-null → true (paused).
bool _fromPausedAt(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value; // Handle case where bool was serialized
  return true;
}

/// Convert paused bool back to paused_at for serialization.
/// null → not paused, non-null (any timestamp) → paused.
String? _toPausedAt(bool paused) => paused ? DateTime.now().toIso8601String() : null;

/// Cron job from GET /api/jobs (Hermes Agent API Server v0.18.2).
///
/// Field mapping corrections (DEC-EPIC001-DEPCHECK):
/// | # | Model Field      | API Key       | Issue Fixed                                |
/// |---|------------------|---------------|--------------------------------------------|
/// | 1 | schedule         | schedule      | Object→String via _parseSchedule (CRITICAL)|
/// | 2 | status           | state         | Renamed API key                            |
/// | 3 | lastRun          | last_run_at   | Renamed API key                            |
/// | 4 | nextRun          | next_run_at   | Renamed API key                            |
/// | 5 | modelProvider    | provider      | Renamed API key                            |
/// | 6 | modelName        | model         | Renamed API key                            |
/// | 7 | paused           | paused_at     | DateTime?→bool via _fromPausedAt           |
@freezed
class CronJob with _$CronJob {
  const factory CronJob({
    required String id,
    required String prompt,
    @JsonKey(fromJson: _parseSchedule) required String schedule,
    @JsonKey(name: 'state') String? status,
    @JsonKey(name: 'last_run_at', fromJson: _fromTimestamp) DateTime? lastRun,
    @JsonKey(name: 'next_run_at', fromJson: _fromTimestamp) DateTime? nextRun,
    @Default([]) List<String> skills,
    @JsonKey(name: 'provider') String? modelProvider,
    @JsonKey(name: 'model') String? modelName,
    String? name,
    String? deliver,
    @JsonKey(name: 'created_at', fromJson: _fromTimestamp) DateTime? createdAt,
    @JsonKey(name: 'last_error') String? lastError,
    @JsonKey(name: 'paused_at', fromJson: _fromPausedAt, toJson: _toPausedAt) @Default(false) bool paused,
  }) = _CronJob;

  factory CronJob.fromJson(Map<String, dynamic> json) =>
      _$CronJobFromJson(json);
}
