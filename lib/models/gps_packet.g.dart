// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gps_packet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GpsPacket _$GpsPacketFromJson(Map<String, dynamic> json) => _GpsPacket(
  tp: TrackPoint.fromJson(json['tp'] as Map<String, dynamic>),
  index: (json['index'] as num?)?.toInt(),
);

Map<String, dynamic> _$GpsPacketToJson(_GpsPacket instance) =>
    <String, dynamic>{'tp': instance.tp, 'index': instance.index};
