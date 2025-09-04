import 'dart:async';
import 'dart:collection';

import 'package:blue_clay_rally/models/checkpoint.dart';
import 'package:blue_clay_rally/models/gps_packet.dart';
import 'package:blue_clay_rally/models/track.dart';
import 'package:blue_clay_rally/providers/app_state_provider.dart';
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
  StreamSubscription? _btSub; // Declare a nullable StreamSubscription variable
  ProviderSubscription<List<Checkpoint>>? _cpUpdateSub;
  @override
  BleState build() {
    ref.onDispose(() async {
      await _tx?.notifications.unsubscribe();
      await _dev?.disconnect();
      _cpUpdateSub?.close();
    });
    return BleState(status: BleStatus.idle);
  }

  Future<void> connect(BleDevice dev) async {
    try {
      await dev.connect();

      await dev.discoverServices();

      _rx = await dev.getCharacteristic(nusRxChar, service: nusService);
      _tx = await dev.getCharacteristic(nusTxChar, service: nusService);
      await _btSub?.cancel();
      await _tx!.notifications.subscribe();
      _btSub = _tx!.onValueReceived.listen(
        _onNotify,
        onError: (e, _) {
          state = state.copyWith(status: BleStatus.error, message: "Notify error: $e");
        },
      );
      state = state.copyWith(status: BleStatus.connected, message: "connected");
    } catch (_) {
      print('Not available');
    }

    _cpUpdateSub = ref.listen(checkpointProvider, (List<Checkpoint>? o, List<Checkpoint> n) {
      for (final c in n) {
        if (!o!.contains(c)) {
          sendText(_toLoRaCpCsv(cpIdx: n.indexOf(c), time: c.time, tpIdx: c.idx));
        }
      }
    });
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

      var line = s.substring(0, i).trim();
      _rxBuf
        ..clear()
        ..write(s.substring(i + 1));
      print(line);

      if (line.isEmpty || line.startsWith('DBG:')) continue;

      // Helper: strip a known prefix ("GPS"/"LoRa") and return the remainder
      String? _payloadAfterPrefix(String src, String prefix) {
        if (!src.startsWith(prefix)) return null;
        var t = src.substring(prefix.length).trimLeft();
        if (t.startsWith(',')) t = t.substring(1).trimLeft(); // allow "GPS,..." style
        return t;
      }

      // --- GPS lines ---
      if (line.startsWith('GPS')) {
        final payload = _payloadAfterPrefix(line, 'GPS')!;
        final parts = payload.split(',');
        if (parts.length < 2) continue;

        final lat = double.tryParse(parts[0]);
        final lon = double.tryParse(parts[1]);
        final alt = parts.length >= 3 ? double.tryParse(parts[2]) : null;

        if (lat == null || lon == null || (lat == 0.0 && lon == 0.0)) continue;

        final tp = TrackPoint(DateTime.now().toUtc(), LatLng(lat, lon), alt);
        ref.read(gpsPacketProvider.notifier).state = GpsPacket(tp: tp);
        final idx = ref.read(gpsPacketProvider)?.index ?? 0;
        sendText(_toLoRaCsv(time: tp.time, lat: lat, lon: lon, alt: alt, idx: idx));
        continue;
      }
      if (line.startsWith('LoRaCP')) {
        final payload = _payloadAfterPrefix(line, 'LoRaCP');
        if (payload != null) {
          final parts = payload.split(',').map((e) => e.trim()).toList();

          int? cpIdx, tpIdx;
          DateTime? t;

          if (parts.length >= 3 && int.tryParse(parts[0]) != null && int.tryParse(parts[1]) != null) {
            cpIdx = int.tryParse(parts[0]);
            tpIdx = int.tryParse(parts[1]);
            t = DateTime.tryParse(parts[2])?.toUtc();
          }

          if (cpIdx != null && tpIdx != null && t != null) {
            final cps = ref.read(checkpointProvider);
            if (cpIdx >= ref.read(checkpointProvider).length) {
              ref.read(appNotifierProvider.notifier).setCheckpoint();
            }
            final tp = ref.read(currentTrackProvider)?.points[tpIdx];
            if (tp != null) {
              ref
                  .read(appNotifierProvider.notifier)
                  .updateCheckpoint(
                    cps[cpIdx],
                    Checkpoint.fromLast(tp: tp, idx: tpIdx, time: t, last: cps.elementAtOrNull(cpIdx)),
                  );
            }
          }
        }
        continue;
      }
      // --- LoRa lines: support both old and new shapes ---
      else if (line.startsWith('LoRa')) {
        final payload = _payloadAfterPrefix(line, 'LoRa');
        final parts = payload!.split(',').map((e) => e.trim()).toList();

        DateTime? t;
        int? idx;
        double? lat, lon, alt;

        if (parts.isNotEmpty && DateTime.tryParse(parts[0]) != null) {
          t = DateTime.parse(parts[0]).toUtc();
          lat = parts.length > 1 ? double.tryParse(parts[1]) : null;
          lon = parts.length > 2 ? double.tryParse(parts[2]) : null;
          alt = parts.length > 3 ? double.tryParse(parts[3]) : null;
          idx = parts.length > 4 ? int.tryParse(parts[4]) : null;
        }

        if (idx == null || lat == null || lon == null || (lat == 0 && lon == 0)) continue;

        final tp = TrackPoint(t ?? DateTime.now().toUtc(), LatLng(lat, lon), alt);
        ref.read(gpsPacketProvider.notifier).update(GpsPacket(tp: tp, index: idx));

        continue;
      }
    }
  }

  String _fmtTime(DateTime t) => t.toUtc().toIso8601String();
  String _fmtNum(double? v, {int frac = 6}) => v == null ? '' : v.toStringAsFixed(frac);

  String _toLoRaCsv({required DateTime time, required double lat, required double lon, double? alt, required int idx}) {
    // Canonical: LoRa,time,lat,lon,alt,idx
    return 'LoRa,${_fmtTime(time)},${_fmtNum(lat)},${_fmtNum(lon)},${_fmtNum(alt)},$idx';
  }

  Future<void> sendText(String s) async {
    if (_rx == null) return;
    await _rx!.write(Uint8List.fromList(s.codeUnits), withResponse: false);
  }

  String _toLoRaCpCsv({required int cpIdx, required int tpIdx, required DateTime time}) =>
      'LoRaCP,$cpIdx,$tpIdx,${_fmtTime(time)}';

  Future<void> sendCheckpoint({required int cpIdx, required int tpIdx, DateTime? time}) async {
    final t = (time ?? DateTime.now().toUtc());
    await sendText(_toLoRaCpCsv(cpIdx: cpIdx, tpIdx: tpIdx, time: t));
  }

  Future<void> disconnect() async {
    await _tx?.notifications.unsubscribe();
    _cpUpdateSub?.close();
    await _dev?.disconnect();
    _dev = null;
    _rx = null;
    _tx = null;
    state = state.copyWith(status: BleStatus.idle, message: "disconnected");
  }
}

final bleProvider = NotifierProvider<BleNotifier, BleState>(BleNotifier.new);
