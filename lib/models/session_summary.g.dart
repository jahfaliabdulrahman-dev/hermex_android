// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionSummaryImpl _$$SessionSummaryImplFromJson(Map<String, dynamic> json) =>
    _$SessionSummaryImpl(
      id: json['id'] as String,
      title: json['title'] as String?,
      modelName: json['model_name'] as String?,
      messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
      createdAt: _fromTimestamp(json['created_at']),
      lastActivity: _fromTimestamp(json['last_activity']),
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$$SessionSummaryImplToJson(
        _$SessionSummaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'model_name': instance.modelName,
      'message_count': instance.messageCount,
      'created_at': instance.createdAt?.toIso8601String(),
      'last_activity': instance.lastActivity?.toIso8601String(),
      'is_pinned': instance.isPinned,
      'is_archived': instance.isArchived,
      'status': instance.status,
    };
