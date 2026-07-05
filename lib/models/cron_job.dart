import 'package:freezed_annotation/freezed_annotation.dart';

part 'cron_job.freezed.dart';
part 'cron_job.g.dart';

/// Top-level timestamp parser — referenced by @JsonKey annotations in freezed models.
DateTime? _fromTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  return DateTime.tryParse(value.toString());
}

/// Cron job from GET /api/jobs.
/// Represents a scheduled task on the Hermes Agent API Server.
@freezed
class CronJob with _$CronJob {
  const factory CronJob({
    required String id,
    required String prompt,
    required String schedule,
    String? status,
    @JsonKey(name: 'last_run', fromJson: _fromTimestamp) DateTime? lastRun,
    @JsonKey(name: 'next_run', fromJson: _fromTimestamp) DateTime? nextRun,
    @Default([]) List<String> skills,
    @JsonKey(name: 'model_provider') String? modelProvider,
    @JsonKey(name: 'model_name') String? modelName,
    String? name,
    String? deliver,
    @JsonKey(name: 'created_at', fromJson: _fromTimestamp) DateTime? createdAt,
    @JsonKey(name: 'last_error') String? lastError,
    @Default(false) bool paused,
  }) = _CronJob;

  factory CronJob.fromJson(Map<String, dynamic> json) =>
      _$CronJobFromJson(json);
}
