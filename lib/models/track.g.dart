// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackPoint _$TrackPointFromJson(Map<String, dynamic> json) => TrackPoint(
  DateTime.parse(json['time'] as String),
  LatLng.fromJson(json['gps'] as Map<String, dynamic>),
  (json['alt'] as num?)?.toDouble(),
)..speed = (json['speed'] as num).toDouble();

Map<String, dynamic> _$TrackPointToJson(TrackPoint instance) =>
    <String, dynamic>{
      'gps': instance.gps,
      'alt': instance.alt,
      'time': instance.time.toIso8601String(),
      'speed': instance.speed,
    };
