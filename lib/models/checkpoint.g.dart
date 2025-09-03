// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkpoint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Checkpoint _$CheckpointFromJson(Map<String, dynamic> json) => _Checkpoint(
  tp: TrackPoint.fromJson(json['tp'] as Map<String, dynamic>),
  time: DateTime.parse(json['time'] as String),
  idx: (json['idx'] as num).toInt(),
  delta: Duration(microseconds: (json['delta'] as num).toInt()),
);

Map<String, dynamic> _$CheckpointToJson(_Checkpoint instance) =>
    <String, dynamic>{
      'tp': instance.tp,
      'time': instance.time.toIso8601String(),
      'idx': instance.idx,
      'delta': instance.delta.inMicroseconds,
    };
