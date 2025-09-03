import 'package:blue_clay_rally/models/track.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkpoint.g.dart';
part 'checkpoint.freezed.dart';

@freezed
abstract class Checkpoint with _$Checkpoint {
  const Checkpoint._();

  factory Checkpoint({required TrackPoint tp, required DateTime time, required int idx, required Duration delta}) = _Checkpoint;

  factory Checkpoint.fromLast({required TrackPoint tp, required DateTime time, required int idx, Checkpoint? last}) {
    final computedDelta = (last == null)
        ? Duration.zero
        : time.difference(last.time) - tp.time.difference(last.tp.time);

    return Checkpoint(tp: tp, time: time, idx: idx, delta: computedDelta);
  }

  factory Checkpoint.fromJson(Map<String, dynamic> json) => _$CheckpointFromJson(json);
}
