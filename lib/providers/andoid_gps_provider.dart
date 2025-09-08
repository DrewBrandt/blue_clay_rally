import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:location/location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:blue_clay_rally/models/gps_packet.dart';
import 'package:blue_clay_rally/models/track.dart';
import 'package:blue_clay_rally/providers/gps_packet_provider.dart';

/// Try to call [fn]. If the plugin isn't ready (NPE -> PlatformException),
/// wait a bit and retry. Returns the function's result or rethrows after max tries.
Future<T> _retryIfPluginNotReady<T>(
  Future<T> Function() fn, {
  int maxTries = 8,
  Duration initialDelay = const Duration(milliseconds: 80),
}) async {
  var delay = initialDelay;
  for (var attempt = 1; attempt <= maxTries; attempt++) {
    try {
      return await fn();
    } on PlatformException catch (e) {
      // The lyokone/location race shows up as NPE inside plugin.
      final msg = '${e.message ?? ''} ${e.details ?? ''}'.toLowerCase();
      final isPluginNull =
          msg.contains('null object reference') || msg.contains('flutterlocation');
      if (!isPluginNull || attempt == maxTries) rethrow;
      await Future.delayed(delay);
      delay *= 2; // exponential backoff: 80,160,320,... ~1s total
    }
  }
  // Unreachable but appeases analyzer
  throw StateError('retry failed');
}

/// Starts Android GPS stream, resilient to cold-start race.
/// Returns the subscription, or null if user/service denied.
Future<StreamSubscription<LocationData>?> androidGps(WidgetRef ref) async {
  // Make sure we’re after first frame AND give the platform a tiny breather.
  if (WidgetsBinding.instance.lifecycleState == null) {
    await WidgetsBinding.instance.endOfFrame;
  }
  await SchedulerBinding.instance.endOfFrame;
  await Future.delayed(const Duration(milliseconds: 50));

  final location = Location();

  // Permissions (with retry)
  PermissionStatus permission = await _retryIfPluginNotReady(
    () => location.hasPermission(),
  );

  if (permission == PermissionStatus.denied) {
    permission = await _retryIfPluginNotReady(
      () => location.requestPermission(),
    );
  }
  if (permission != PermissionStatus.granted &&
      permission != PermissionStatus.grantedLimited) {
    return null;
  }

  // Service enabled (with retry)
  bool enabled = await _retryIfPluginNotReady(() => location.serviceEnabled());
  if (!enabled) {
    try {
      enabled = await _retryIfPluginNotReady(() => location.requestService());
    } on PlatformException {
      return null; // cannot show dialog yet; bail cleanly
    }
  }
  if (!enabled) return null;

  // Configure rate
  await _retryIfPluginNotReady(() => location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 250,
        distanceFilter: 0,
      ));

  // Subscribe
  final sub = location.onLocationChanged.listen((l) {
    final lat = l.latitude, lon = l.longitude;
    if (lat == null || lon == null) return;
    ref.read(gpsPacketProvider.notifier).update(
          GpsPacket(
            tp: TrackPoint(DateTime.now(), LatLng(lat, lon), l.altitude),
          ),
        );
  });

  // Auto-cleanup if the provider that called this dies
  // ref.onDispose(() => sub.cancel());

  return sub;
}
