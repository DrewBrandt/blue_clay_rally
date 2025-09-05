import 'dart:async';

import 'package:blue_clay_rally/models/gps_packet.dart';
import 'package:blue_clay_rally/models/track.dart';
import 'package:blue_clay_rally/providers/ble_provider.dart';
import 'package:blue_clay_rally/providers/gps_packet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

Future<void> androidGps(WidgetRef ref) async {
  Location location = Location();
  bool serviceEnabled;
  PermissionStatus permissionGranted;

  StreamSubscription? _s;
  
  serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      return;
    }
  }

  permissionGranted = await location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await location.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      return;
    }
  }
  _s = location.onLocationChanged.listen((LocationData l) {
    ref
        .read(gpsPacketProvider.notifier)
        .update(GpsPacket(tp: TrackPoint(DateTime.now(), LatLng(l.latitude ?? 0, l.longitude ?? 0), l.altitude)));
  });
  ref.listen(bleProvider, (o, n) {
    if(n.status == BleStatus.connected) {
      _s?.pause();
    }
    else {
      _s?.resume();
    }
  });
}
