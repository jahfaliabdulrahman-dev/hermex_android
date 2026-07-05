// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkspaceEntryImpl _$$WorkspaceEntryImplFromJson(Map<String, dynamic> json) =>
    _$WorkspaceEntryImpl(
      name: json['name'] as String,
      type: json['type'] as String? ?? 'file',
      size: (json['size'] as num?)?.toInt() ?? 0,
      modifiedAt: json['modified_at'] as String?,
      isBinary: json['is_binary'] as bool? ?? false,
    );

Map<String, dynamic> _$$WorkspaceEntryImplToJson(
        _$WorkspaceEntryImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'size': instance.size,
      'modified_at': instance.modifiedAt,
      'is_binary': instance.isBinary,
    };
