import 'dart:async';
import 'dart:collection';

import 'package:blue_clay_rally/models/gps_packet.dart';
import 'package:blue_clay_rally/models/track.dart';
import 'package:blue_clay_rally/providers/gps_packet_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'package:universal_ble/universal_ble.dart';

part 'ble_provider.freezed.dart';

const String nusService = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
const String nusRxChar = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // write
const String nusTxChar = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // notify
const String targetNamePrefix = "ESP32-NUS-";

enum BleStatus { off, idle, scanning, connecting, connected, error }

final deviceProvider = StateProvider<Set<BleDevice>>((ref) {
  return {};
});

@freezed
abstract class BleState with _$BleState {
  factory BleState({required BleStatus status, String? deviceId, String? message}) = _BleState;
}

class BleNotifier extends Notifier<BleState> {
  BleDevice? _dev;
  BleCharacteristic? _rx, _tx;
  final _rxBuf = StringBuffer();
  StreamSubscription? _subscription; // Declare a nullable StreamSubscription variable
  @override
  BleState build() {
    ref.onDispose(() async {
      await _tx?.notifications.unsubscribe();
      await _dev?.disconnect();
    });
    return BleState(status: BleStatus.idle);
  }

  Future<void> connect(BleDevice dev) async {
    try {
      await dev.connect();

      await dev.discoverServices();

      _rx = await dev.getCharacteristic(nusRxChar, service: nusService);
      _tx = await dev.getCharacteristic(nusTxChar, service: nusService);
      await _subscription?.cancel();
      await _tx!.notifications.subscribe();
      _subscription = _tx!.onValueReceived.listen(
        _onNotify,
        onError: (e, _) {
          state = state.copyWith(status: BleStatus.error, message: "Notify error: $e");
        },
      );
      state = state.copyWith(status: BleStatus.connected, message: "connected");
    } catch (_) {
      print('Not available');
    }
  }

  Future<void> startScan() async {
    final avail = await UniversalBle.getBluetoothAvailabilityState();
    if (avail != AvailabilityState.poweredOn) {
      try {
        final b = await UniversalBle.enableBluetooth(timeout: const Duration(seconds: 5));
        if (b) {
          state = state.copyWith(deviceId: null, message: "BT is Idle", status: BleStatus.idle);
        } else {
          throw StateError('BT is Off');
        }
      } catch (_) {
        state = state.copyWith(deviceId: null, message: "BT is Off", status: BleStatus.off);
        return;
      }
    }

    state = state.copyWith(status: BleStatus.scanning, message: "scanning");
    ref.read(deviceProvider.notifier).state = {};

    final devices = LinkedHashSet<BleDevice>(
      equals: (a, b) => a.deviceId.toLowerCase() == b.deviceId.toLowerCase(),
      hashCode: (d) => d.deviceId.toLowerCase().hashCode,
    );
    final sub = UniversalBle.scanStream.listen((d) {
      if (d.name?.toUpperCase().contains(targetNamePrefix.toUpperCase()) ?? false) {
        devices.add(d);
        ref.read(deviceProvider.notifier).state = devices;
      }
    });
    await UniversalBle.startScan(scanFilter: ScanFilter());
    await Future.delayed(const Duration(seconds: 6));
    await UniversalBle.stopScan();

    await sub.cancel();
    if (devices.isEmpty) {
      state = state.copyWith(status: BleStatus.error, message: "No Devices Found");
      return;
    }
    state = state.copyWith(deviceId: null, message: "BT is Idle", status: BleStatus.idle);
  }

  void _onNotify(Uint8List data) {
    _rxBuf.write(String.fromCharCodes(data));
    for (;;) {
      final s = _rxBuf.toString();
      final i = s.indexOf('\n');
      if (i < 0) break;

      final line = s.substring(0, i).trim();
      _rxBuf.clear();
      _rxBuf.write(s.substring(i + 1));

      if (line.isEmpty || line.startsWith('DBG:')) continue;
      final parts = line.split(',');
      if (parts.length >= 3) {
        print(line);
        final lat = double.tryParse(parts[0]);
        final lon = double.tryParse(parts[1]);
        final alt = double.tryParse(parts[2]); // may be null
        if (lat != null && lon != null && !(lat == 0.0 && lon == 0.0)) {
          final tp = TrackPoint(
            DateTime.now().toUtc(), // replace later with GPS TOD if you add it
            LatLng(lat, lon),
            alt,
          );
          ref.read(gpsPacketProvider.notifier).state = GpsPacket(tp: tp);
        }
      }
    }
  }

  Future<void> sendText(String s) async {
    if (_rx == null) return;
    await _rx!.write(Uint8List.fromList(s.codeUnits), withResponse: false);
  }

  Future<void> disconnect() async {
    await _tx?.notifications.unsubscribe();
    await _dev?.disconnect();
    _dev = null;
    _rx = null;
    _tx = null;
    state = state.copyWith(status: BleStatus.idle, message: "disconnected");
  }
}

final bleProvider = NotifierProvider<BleNotifier, BleState>(BleNotifier.new);
