// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ModelInfoImpl _$$ModelInfoImplFromJson(Map<String, dynamic> json) =>
    _$ModelInfoImpl(
      id: json['id'] as String,
      object: json['object'] as String? ?? 'model',
      created: (json['created'] as num?)?.toInt(),
      ownedBy: json['owned_by'] as String?,
    );

Map<String, dynamic> _$$ModelInfoImplToJson(_$ModelInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'object': instance.object,
      'created': instance.created,
      'owned_by': instance.ownedBy,
    };
