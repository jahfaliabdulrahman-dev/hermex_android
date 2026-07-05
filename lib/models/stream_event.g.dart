// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stream_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TextDeltaImpl _$$TextDeltaImplFromJson(Map<String, dynamic> json) =>
    _$TextDeltaImpl(
      text: json['text'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$TextDeltaImplToJson(_$TextDeltaImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'runtimeType': instance.$type,
    };

_$ToolProgressImpl _$$ToolProgressImplFromJson(Map<String, dynamic> json) =>
    _$ToolProgressImpl(
      toolName: json['toolName'] as String,
      status: json['status'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ToolProgressImplToJson(_$ToolProgressImpl instance) =>
    <String, dynamic>{
      'toolName': instance.toolName,
      'status': instance.status,
      'runtimeType': instance.$type,
    };

_$StreamDoneImpl _$$StreamDoneImplFromJson(Map<String, dynamic> json) =>
    _$StreamDoneImpl(
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$StreamDoneImplToJson(_$StreamDoneImpl instance) =>
    <String, dynamic>{
      'runtimeType': instance.$type,
    };

_$StreamErrorImpl _$$StreamErrorImplFromJson(Map<String, dynamic> json) =>
    _$StreamErrorImpl(
      message: json['message'] as String,
      code: json['code'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$StreamErrorImplToJson(_$StreamErrorImpl instance) =>
    <String, dynamic>{
      'message': instance.message,
      'code': instance.code,
      'runtimeType': instance.$type,
    };
