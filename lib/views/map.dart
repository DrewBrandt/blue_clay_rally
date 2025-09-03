import 'package:blue_clay_rally/models/track.dart';
import 'package:blue_clay_rally/providers/app_state_provider.dart';
import 'package:blue_clay_rally/providers/bunny_provider.dart';
import 'package:blue_clay_rally/providers/gps_packet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:latlong2/latlong.dart';

class MapDisplay extends ConsumerStatefulWidget {
  const MapDisplay({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MapState();
}

class _MapState extends ConsumerState<MapDisplay> {
  final _mapController = MapController();
  @override
  Widget build(BuildContext context) {
    // bool _follow = false; // toggle if you want
    double speed = 1.0; // 1× playback
    final track = ref.watch(currentTrackProvider);
    final cps = ref.watch(appNotifierProvider)?.cps;
    bool follow = ref.watch(followProvider);
    // Listen for track changes to fit bounds once
    ref.listen<Track?>(currentTrackProvider, (prev, next) {
      if (next != null && next.points.length >= 2) {
        // Delay a frame to ensure map is laid out
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.fitCamera(
            CameraFit.bounds(bounds: LatLngBounds(next.min, next.max), padding: const EdgeInsets.all(100)),
          );
        });
      }
    });

    final playback = track == null
        ? const AsyncValue<LatLng?>.data(null)
        : ref.watch(playbackProvider((track: track, speed: speed)));

    ref.listen(gpsPacketProvider, (o, n) {
      if (n != null && follow) {
        _mapController.move(n.tp.gps, _mapController.camera.zoom);
      }
    });
    ref.listen(followProvider, (o, n) {
      if (n && ref.read(gpsPacketProvider) != null) {
        _mapController.move(ref.read(gpsPacketProvider)!.tp.gps, _mapController.camera.zoom);
      }
    });

    final current = playback.value;

    final polylines = track == null
        ? const <Polyline>[]
        : _buildSpeedColoredPolylines(track.points, ref.watch(gpsPacketProvider)?.index ?? 0);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        interactionOptions: InteractionOptions(),
        onMapEvent: (e) {
          if (!ref.read(followProvider)) return;
          switch (e.source) {
            case MapEventSource.dragStart:
            case MapEventSource.onDrag:
            case MapEventSource.dragEnd:
            case MapEventSource.keyboard: // arrow keys, etc.
              ref.read(followProvider.notifier).state = false;
              break;
            default:
              if (ref.read(gpsPacketProvider) != null) {
                _mapController.move(ref.read(gpsPacketProvider)!.tp.gps, _mapController.camera.zoom);
              }
              // Ignore zoom-only sources: scrollWheel, doubleTap, doubleTapHold,
              // doubleTapZoomAnimationController, multi-finger pinch, etc.
              break;
          }
        },
        initialCenter: ref.watch(currentTrackProvider)?.center ?? LatLng(38.9, -77),
        initialZoom: 10,
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer.withAlpha(220),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // Identify your app to OSM
          userAgentPackageName: 'dev.drew.rcr',
          retinaMode: true,
        ),
        if (polylines.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [for (var i = 0; i < track!.points.length; i += 1) track.points[i].gps],
                color: Colors.black,
                strokeWidth: 5,
              ),
              ...polylines,
            ],
          ),
        MarkerLayer(
          alignment: Alignment.center,
          markers: [
            if (cps?.isNotEmpty ?? false)
              ...cps!.map((cp) {
                double size = 40;
                return Marker(
                  width: size,
                  height: size,
                  point: cp.tp.gps,
                  alignment: Alignment(.5, -.6),
                  child: Icon(Icons.flag_rounded, color: Colors.black, size: size),
                );
              }),
            if (ref.watch(gpsPacketProvider) != null)
              Marker(
                width: 80,
                height: 80,
                point: ref.watch(gpsPacketProvider)!.tp.gps,
                child: Image.asset('assets/jeep2.png'),
              ),
            if (current != null) Marker(width: 60, height: 60, point: current, child: Image.asset('assets/bunny2.png')),
          ],
        ),
        // Required attribution when using OSM data
        SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
      ],
    );
  }
}

double _speedMph(TrackPoint tp) {
  return tp.speed * 2.23694;
}

Color _colorForSpeed(double mph) {
  // Tweak bins to taste
  if (mph < 1) return Colors.red; // stopped / crawling
  if (mph < 5) return Colors.orange;
  if (mph < 15) return Colors.yellow;
  if (mph < 30) return Colors.green;
  if (mph < 50) return Colors.blue;
  return Colors.purple;
}

List<Polyline> _buildSpeedColoredPolylines(List<TrackPoint> pts, int currentTrackIndex) {
  if (pts.length < 2) return const [];
  final lines = <Polyline>[];

  Color? currentColor;
  List<LatLng> current = [];

  // Walk consecutive pairs, color each segment by its speed
  for (var i = 1; i < pts.length; i++) {
    final a = pts[i - 1];
    final b = pts[i];
    final segColor = i <= currentTrackIndex ? Colors.blueGrey : _colorForSpeed(_speedMph(a));

    // start or continue a run of same-colored segments
    if (currentColor == null || segColor != currentColor) {
      // flush previous run
      if (current.length >= 2) {
        lines.add(Polyline(points: List.of(current), strokeWidth: 3, color: currentColor!));
      }
      currentColor = segColor;
      current = [a.gps, b.gps];
    } else {
      current.add(b.gps);
    }
  }

  // flush tail
  if (current.length >= 2 && currentColor != null) {
    lines.add(Polyline(points: current, strokeWidth: 3, color: currentColor));
  }
  // debugPrint('${numpts} rendered');
  return lines;
}

final followProvider = StateProvider<bool>((ref) {
  return false;
});
