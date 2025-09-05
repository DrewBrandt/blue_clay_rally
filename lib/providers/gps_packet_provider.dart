import 'package:blue_clay_rally/models/gps_packet.dart';
import 'package:blue_clay_rally/providers/app_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class GpsPacketNotifier extends Notifier<GpsPacket?> {
  final _durationMargin = (Duration(
    minutes: 2,
  )); // arbitrary # of minutes to look ahead of where the track thinks we should be

  static const _exactDistanceMargin =
      2.5; // number of meters we can be "off track" and still have it shortcut the full "closest point" check

  static const double _mPerDegLat37 = 110_977.618; // m / degree latitude
  static const double _mPerDegLon37 = 89_011.640; // m / degree longitude

  @override
  GpsPacket? build() {
    return null;
  }

  double _dist2Meters(LatLng u, LatLng v, double kLat, double kLon) {
    final dx = (u.latitude - v.latitude) * kLat;
    final dy = (u.longitude - v.longitude) * kLon;
    return dx * dx + dy * dy;
  }

  bool _pointInRectangleMeters(LatLng p, LatLng a, LatLng b, double rMeters) {
    final kLat = _mPerDegLat37;
    final kLon = _mPerDegLon37;

    // Convert degree deltas -> meters (isotropic)
    final vx = (b.latitude - a.latitude) * kLat;
    final vy = (b.longitude - a.longitude) * kLon;
    final wx = (p.latitude - a.latitude) * kLat;
    final wy = (p.longitude - a.longitude) * kLon;

    final vv = vx * vx + vy * vy;
    if (vv == 0.0) {
      // Degenerate: segment is a point -> disk of radius rMeters
      return (wx * wx + wy * wy) <= rMeters * rMeters;
    }

    // Perpendicular distance check (no sqrt): |v×w|^2 <= r^2 * |v|^2
    final cross = vx * wy - vy * wx;
    if (cross * cross > (rMeters * rMeters) * vv) return false;

    // Along-axis bounds: 0 <= v·w <= |v|^2
    final dot = wx * vx + wy * vy;
    return (dot >= 0.0) && (dot <= vv);
  }

  void update(GpsPacket? p) {
    final session = ref.read(appNotifierProvider);
    final track = ref.read(currentTrackProvider);
    final lastPassedIndex = state?.index ?? 0;
    GpsPacket? o = state;
    state = p;
    if (session == null || !session.started || session.finished) {
      return; // no session info, or not currently racing
    }

    if (track == null || lastPassedIndex == track.points.length - 1) {
      return; // no track or track already done
    }

    if (p == null) return; // no new point to do anything with

    if (p.index != null) return; // Recieved something over LoRa with index embedded
    
    final timeSinceLastUpdate = p.tp.time.difference(o?.tp.time ?? p.tp.time);
    var durationToCheck = timeSinceLastUpdate + _durationMargin;
    var i = lastPassedIndex;
    final idxTime = track.points[i].time;
    double minDist = double.infinity;
    int minIdx = i;
    while (!durationToCheck.isNegative && i < track.points.length - 1) {
      durationToCheck -= track.points[i].time.difference(idxTime); // take off from # pts left to check

      if (i < track.points.length - 2 &&
          _pointInRectangleMeters(p.tp.gps, track.points[i].gps, track.points[i + 1].gps, _exactDistanceMargin)) {
        state = p.copyWith(index: i);
        return;
      }

      final d2 = _dist2Meters(p.tp.gps, track.points[i].gps, _mPerDegLat37, _mPerDegLon37);
      if (d2 < minDist) {
        minDist = d2;
        minIdx = i;
      }
      i++;
    }
    state = p.copyWith(index: minIdx);
      // Format: ISO time, lat, lon, ele (extend as you like)
      final lat = p.tp.gps.latitude.toStringAsFixed(7);
      final lon = p.tp.gps.longitude.toStringAsFixed(7);
      final ele = (p.tp.alt ?? 0).toStringAsFixed(2);
      ref.read(appNotifierProvider.notifier).logCsvRow('${DateTime.now()},$lat,$lon,$ele');
  }

  void reset() {
    state = state != null ? GpsPacket(tp: state!.tp) : null;
  }

  void fixProgress() {
    final ses = ref.read(appNotifierProvider);
    final track = ref.read(currentTrackProvider);
    if (ses != null && !ses.finished && ses.started && track != null && state != null) {
      final cp = ses.cps.last;
      var i = cp.idx;
      double minDist = double.infinity;
      int idx = i;
      for (i; i < track.points.length; i++) {
        final d = _dist2Meters(state!.tp.gps, track.points[i].gps, _mPerDegLat37, _mPerDegLon37);
        if (d < minDist) {
          minDist = d;
          idx = i;
        }
      }
      state = state!.copyWith(index: idx);
    }
  }
}

final gpsPacketProvider = NotifierProvider<GpsPacketNotifier, GpsPacket?>(GpsPacketNotifier.new);
