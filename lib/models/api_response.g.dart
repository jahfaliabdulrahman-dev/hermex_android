// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ApiResponseImpl _$$ApiResponseImplFromJson(Map<String, dynamic> json) =>
    _$ApiResponseImpl(
      data: json['data'] as Map<String, dynamic>? ?? const {},
      total: (json['total'] as num?)?.toInt() ?? 0,
      error: json['error'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$$ApiResponseImplToJson(_$ApiResponseImpl instance) =>
    <String, dynamic>{
      'data': instance.data,
      'total': instance.total,
      'error': instance.error,
      'message': instance.message,
    };

_$ApiListResponseImpl _$$ApiListResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$ApiListResponseImpl(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ApiListResponseImplToJson(
        _$ApiListResponseImpl instance) =>
    <String, dynamic>{
      'data': instance.data,
      'total': instance.total,
      'limit': instance.limit,
      'offset': instance.offset,
    };
