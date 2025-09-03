// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionInfo _$SessionInfoFromJson(Map<String, dynamic> json) => _SessionInfo(
  trackFileType: json['trackFileType'] as String,
  trackFileName: json['trackFileName'] as String,
  cps: (json['cps'] as List<dynamic>)
      .map((e) => Checkpoint.fromJson(e as Map<String, dynamic>))
      .toList(),
  started: json['started'] as bool,
  finished: json['finished'] as bool,
);

Map<String, dynamic> _$SessionInfoToJson(_SessionInfo instance) =>
    <String, dynamic>{
      'trackFileType': instance.trackFileType,
      'trackFileName': instance.trackFileName,
      'cps': instance.cps,
      'started': instance.started,
      'finished': instance.finished,
    };
