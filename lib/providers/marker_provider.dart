import 'dart:async';

import 'package:blue_clay_rally/models/gps_packet.dart';
import 'package:blue_clay_rally/models/track.dart';
import 'package:blue_clay_rally/providers/app_state_provider.dart';
import 'package:blue_clay_rally/providers/gps_packet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final markerProvider = StreamProvider<(LatLng? bunny, LatLng? jeep)>((ref) {
  final ctrl = StreamController<(LatLng? bunny, LatLng? jeep)>();
  final pts = ref.watch(currentTrackProvider)?.points;
  final cps = ref.watch(checkpointProvider);
  // ref.watch(gpsPacketProvider);
  GpsPacket? o, n;

  LatLng interp(TrackPoint a, TrackPoint b, DateTime t) {
    final totalMs = b.time.difference(a.time).inMilliseconds;
    final partMs = t.difference(a.time).inMilliseconds;
    final f = totalMs <= 0 ? 0.0 : (partMs / totalMs).clamp(0.0, 1.0);
    final lat = a.gps.latitude + (b.gps.latitude - a.gps.latitude) * f;
    final lon = a.gps.longitude + (b.gps.longitude - a.gps.longitude) * f;
    return LatLng(lat, lon);
  }

  LatLng? bunny, jeep;

  // 30 Hz updates is plenty smooth.
  const dt = Duration(milliseconds: 33);
  int seg = 0; // index of the "left" point in the current segment
  Timer? timer;

  void timerFunc(_) {
    bunny = (() {
      if(pts == null) return null;
      if (cps.isEmpty) return pts.first.gps;
      final elapsed = DateTime.now().difference(cps.last.time);
      final playhead = cps.last.tp.time.add(elapsed);

      // Advance to the segment that contains 'playhead'
      while (seg + 1 < pts.length && pts[seg + 1].time.isBefore(playhead)) {
        seg++;
      }

      if (seg + 1 >= pts.length) {
        // Reached (or passed) end; emit last point and stop.

        return pts.last.gps;
      }

      return interp(pts[seg], pts[seg + 1], playhead);
    })();

    // JEEP
    jeep = (() {
      if (o == null && n == null) return null;
      if (n == null) return o!.tp.gps;
      if (o == null) return n!.tp.gps;
      final elapsed = DateTime.now().difference(n!.tp.time);
      final playhead = o!.tp.time.add(elapsed);
      return interp(o!.tp, n!.tp, playhead);
    })();

    ctrl.add((bunny, jeep));
  }

  ref.listen(gpsPacketProvider, (previous, next) {
    o = previous;
    n = next;
    timerFunc(null);
  }, fireImmediately: true);

  timer = Timer.periodic(dt, timerFunc);

  ref.onDispose(() {
    timer?.cancel();
    ctrl.close();
  });

  return ctrl.stream;
});
