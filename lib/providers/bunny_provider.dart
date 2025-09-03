import 'dart:async';

import 'package:blue_clay_rally/models/track.dart';
import 'package:blue_clay_rally/providers/app_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Emits the current LatLng along the track, advancing according to point timestamps.
/// `speed` is a multiplier (1.0 = realtime).
final playbackProvider = StreamProvider.family<LatLng?, ({Track track, double speed})>((ref, args) {
  final track = args.track;
  final speed = args.speed;

  final ctrl = StreamController<LatLng?>();
  final pts = track.points;
  final cps = ref.watch(checkpointProvider);

  if (pts.length < 2 || cps.isEmpty) {
    // Not enough to animate—just pin to the first point.
    ctrl.add(pts.isNotEmpty ? pts.first.gps : null);
    // Close on next microtask so listeners can read the first value.
    scheduleMicrotask(() => ctrl.close());
    return ctrl.stream;
  }

  // Wall-clock start aligned to the first track time.
  final wallStart = DateTime.now();
  final t0 = cps.last.tp.time;

  // 30 Hz updates is plenty smooth.
  const dt = Duration(milliseconds: 33);
  int seg = 0; // index of the "left" point in the current segment
  Timer? timer;

  LatLng interp(TrackPoint a, TrackPoint b, DateTime t) {
    final totalMs = b.time.difference(a.time).inMilliseconds;
    final partMs = t.difference(a.time).inMilliseconds;
    final f = totalMs <= 0 ? 0.0 : (partMs / totalMs).clamp(0.0, 1.0);
    final lat = a.gps.latitude + (b.gps.latitude - a.gps.latitude) * f;
    final lon = a.gps.longitude + (b.gps.longitude - a.gps.longitude) * f;
    return LatLng(lat, lon);
  }

  timer = Timer.periodic(dt, (_) {
    final elapsedMs = DateTime.now().difference(wallStart).inMilliseconds * speed;
    final playhead = t0.add(Duration(milliseconds: elapsedMs.round()));

    // Advance to the segment that contains 'playhead'
    while (seg + 1 < pts.length && pts[seg + 1].time.isBefore(playhead)) {
      seg++;
    }

    if (seg + 1 >= pts.length) {
      // Reached (or passed) end; emit last point and stop.
      ctrl.add(pts.last.gps);
      timer?.cancel();
      ctrl.close();
      return;
    }

    ctrl.add(interp(pts[seg], pts[seg + 1], playhead));
  });

  ref.onDispose(() {
    timer?.cancel();
    ctrl.close();
  });

  return ctrl.stream;
});
