
import 'package:blue_clay_rally/models/track.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'gps_packet.freezed.dart';
part 'gps_packet.g.dart';

@freezed
abstract class GpsPacket with _$GpsPacket{

  factory GpsPacket({
    required TrackPoint tp,
    int? index,
  }) = _GpsPacket;

    factory GpsPacket.fromJson(Map<String, dynamic> json) =>
      _$GpsPacketFromJson(json);
}
