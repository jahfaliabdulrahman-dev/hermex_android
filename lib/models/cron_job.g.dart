// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cron_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CronJobImpl _$$CronJobImplFromJson(Map<String, dynamic> json) =>
    _$CronJobImpl(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      schedule: _parseSchedule(json['schedule']),
      status: json['state'] as String?,
      lastRun: _fromTimestamp(json['last_run_at']),
      nextRun: _fromTimestamp(json['next_run_at']),
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      modelProvider: json['provider'] as String?,
      modelName: json['model'] as String?,
      name: json['name'] as String?,
      deliver: json['deliver'] as String?,
      createdAt: _fromTimestamp(json['created_at']),
      lastError: json['last_error'] as String?,
      paused:
          json['paused_at'] == null ? false : _fromPausedAt(json['paused_at']),
    );

Map<String, dynamic> _$$CronJobImplToJson(_$CronJobImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'prompt': instance.prompt,
      'schedule': instance.schedule,
      'state': instance.status,
      'last_run_at': instance.lastRun?.toIso8601String(),
      'next_run_at': instance.nextRun?.toIso8601String(),
      'skills': instance.skills,
      'provider': instance.modelProvider,
      'model': instance.modelName,
      'name': instance.name,
      'deliver': instance.deliver,
      'created_at': instance.createdAt?.toIso8601String(),
      'last_error': instance.lastError,
      'paused_at': _toPausedAt(instance.paused),
    };
