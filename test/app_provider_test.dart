// test/app_notifier_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:blue_clay_rally/models/checkpoint.dart';
import 'package:blue_clay_rally/models/session_info.dart';
import 'package:blue_clay_rally/models/track.dart';
import 'package:blue_clay_rally/providers/app_state_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';

import 'fixtures.dart';

// ---------- helpers ----------
TrackPoint _tpAt(
  DateTime t,
  double lat,
  double lon, {
  double? alt,
  double speed = 0,
}) {
  final tp = TrackPoint(t, LatLng(lat, lon), alt);
  tp.speed = speed;
  return tp;
}

Future<void> _mockPathProviderToTemp(Directory tempDir) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall m) async {
          if (m.method == 'getApplicationSupportDirectory' ||
              m.method == 'getApplicationDocumentsDirectory') {
            return tempDir.path; // return string path
          }
          return null;
        },
      );
}

Future<void> _resetHiveDir(Directory tempDir) async {
  if (await tempDir.exists()) {
    await tempDir.delete(recursive: true);
  }
  await tempDir.create(recursive: true);
}

Future<void> _safeDeleteDir(Directory dir) async {
  // Close Hive first (releases file handles)
  await Hive.close();
  // Small retry loop for Windows file locks
  for (var i = 0; i < 5; i++) {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      break;
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}

// ---------- tests ----------
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('bcr_riverpod_');
    await _mockPathProviderToTemp(tempDir);
    await _resetHiveDir(tempDir);
    // Let HiveStorage.init() do Hive.initFlutter('BlueClayRally').
    // No manual Hive.init here to avoid mismatched dirs.
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AppNotifier (Riverpod) integration', () {
    test('boot with no previous session', () async {
      final container = ProviderContainer();
      addTearDown(() async {
        container.dispose();
        await _safeDeleteDir(tempDir);
      });

      final app = container.read(appNotifierProvider.notifier);
      await app.ready; // <- ensures HiveStorage.init() finished
      // Allow its async _init() to run
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(app.hasPreviousSession, isFalse);
      expect(container.read(appNotifierProvider), isNull);
      expect(container.read(currentTrackProvider), isNull);
    });

    test('loadNewFile sets state, saves track, and publishes Track', () async {
      final container = ProviderContainer();
      addTearDown(() async {
        container.dispose();
        await _safeDeleteDir(tempDir);
      });

      final app = container.read(appNotifierProvider.notifier);
      await app.ready; // <- ensures HiveStorage.init() finished
      await app.loadNewFile(sampleCsv, 'rc2025.csv', 'csv');
      // state created (not started yet)
      final s = container.read(appNotifierProvider);
      expect(s, isNotNull);
      expect(s!.trackFileType, 'csv');
      expect(s.trackFileName, 'rc2025.csv');
      expect(s.started, isFalse);
      expect(s.cps, isEmpty);

      // track provider populated
      final track = container.read(currentTrackProvider);
      expect(track, isNotNull);
      expect(track!.points.length, greaterThanOrEqualTo(2));

      // persisted track contents round-trip (box-level)
      final tracksBox = await Hive.openLazyBox<String>(
        'tracks',
      ); // or <Uint8List> if using bytes
      // there should be exactly one key for this run; fetch its value
      final firstKey = tracksBox.keys.first as int;
      final persisted = await tracksBox.get(firstKey);
      expect(persisted, isNotNull);
      expect(persisted!, contains('time,'));
    });

    test('setCheckpoint appends and marks started', () async {
      final container = ProviderContainer();
      addTearDown(() async {
        container.dispose();
        await _safeDeleteDir(tempDir);
      });

      final app = container.read(appNotifierProvider.notifier);
      await app.ready; // <- ensures HiveStorage.init() finished
      // Seed a new file
      await app.loadNewFile(sampleCsv, 'rc2025.csv', 'csv');

      // Select an index in the track
      container.read(trackIndexProvider.notifier).state = 1;

      // Add a checkpoint
      await app.setCheckpoint();

      final s = container.read(appNotifierProvider);
      expect(s, isNotNull);
      expect(s!.started, isTrue);
      expect(s.cps.length, 1);
      expect(s.cps.first.idx, 1);
    });

    test('removeCheckpoint removes by idx', () async {
      final container = ProviderContainer();
      addTearDown(() async {
        container.dispose();
        await _safeDeleteDir(tempDir);
      });
      final app = container.read(appNotifierProvider.notifier);
      await app.ready; // <- ensures HiveStorage.init() finished
      await app.loadNewFile(sampleCsv, 'rc2025.csv', 'csv');
      container.read(trackIndexProvider.notifier).state = 1;
      await app.setCheckpoint();
      container.read(trackIndexProvider.notifier).state = 2;
      await app.setCheckpoint();

      var s = container.read(appNotifierProvider)!;
      expect(s.cps.length, 2);

      final toRemove = s.cps.first;
      await app.removeCheckpoint(toRemove);

      s = container.read(appNotifierProvider)!;
      expect(s.cps.length, 1);
      expect(s.cps.first.idx, isNot(toRemove.idx));
    });

    test('updateCheckpoint replaces only the matching idx', () async {
      final container = ProviderContainer();
      addTearDown(() async {
        container.dispose();
        await _safeDeleteDir(tempDir);
      });
      final app = container.read(appNotifierProvider.notifier);
      await app.ready; // <- ensures HiveStorage.init() finished
      await app.loadNewFile(sampleCsv, 'rc2025.csv', 'csv');
      container.read(trackIndexProvider.notifier).state = 1;
      await app.setCheckpoint();
      var s = container.read(appNotifierProvider)!;
      final original = s.cps.first;

      // Make a new CP with same idx but different time
      final newTime = original.time.add(const Duration(seconds: 30));
      final newCp = Checkpoint(original.tp, newTime, original.idx);

      await app.updateCheckpoint(original, newCp);

      s = container.read(appNotifierProvider)!;
      expect(s.cps.length, 1);
      expect(s.cps.first.idx, original.idx);
      expect(s.cps.first.time, newTime);
    });

    test('loadPrevious reconstructs from last_session', () async {
      // 1) Seed directly via Hive
      await Hive.initFlutter('BlueClayRally');
      final sessions = await Hive.openLazyBox<String>('sessions');
      final tracks = await Hive.openLazyBox<String>('tracks'); // <-- add this
      final lastBox = await Hive.openBox<int>('last_session');

      final now = DateTime.now().toUtc();
      final prev = SessionInfo(
        trackFileType: 'csv',
        trackFileName: 'prev.csv',
        cps: [Checkpoint(_tpAt(now, 35.0, -85.0, alt: 480, speed: 42), now, 0)],
        started: true,
        finished: false,
      );

      const prevId = 7;
      await sessions.put(prevId, jsonEncode(prev.toJson()));
      await tracks.put(prevId, sampleCsv); // <-- seed the CSV bytes as STRING
      await lastBox.put('last_session_id', prevId);

      // 2) App boot
      final container = ProviderContainer();
      addTearDown(() async {
        container.dispose();
        await _safeDeleteDir(tempDir);
      });
      final app = container.read(appNotifierProvider.notifier);
      await app.ready;

      // 3) load previous
      await app.loadPrevious();

      final s = container.read(appNotifierProvider);
      expect(s, isNotNull);
      expect(s!.trackFileName, 'prev.csv');
      expect(s.started, isTrue);
      expect(s.cps.length, 1);
    });
  });
}
