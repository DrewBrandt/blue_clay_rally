import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:blue_clay_rally/storage/hive_storage.dart';
import 'package:blue_clay_rally/models/session_info.dart';
import 'package:blue_clay_rally/models/checkpoint.dart';
import 'package:blue_clay_rally/models/track.dart';
import 'package:flutter/services.dart'; 

// Matches the relative dir you pass to Hive.initFlutter('BlueClayRally')
Future<void> _resetHiveDir() async {
  final dir = Directory('BlueClayRally');
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}

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

SessionInfo _sessionInfo({
  required bool started,
  required bool finished,
  required List<Checkpoint> cps,
  String trackFileType = 'csv',
  String trackFileName = 'test',
}) {
  return SessionInfo(
    trackFileType: trackFileType,
    trackFileName: trackFileName,
    cps: cps,
    started: started,
    finished: finished,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  setUp(() async {
    // Initialize the Flutter test binding.

    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock the platform channel for path_provider to return a temporary directory.

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),

          (MethodCall methodCall) async {
            if (methodCall.method == 'getApplicationSupportDirectory' ||
                methodCall.method == 'getApplicationDocumentsDirectory') {
              // Create a temporary directory that will be deleted after the tests.

              tempDir = Directory.systemTemp.createTempSync('hive_test_');

              // CORRECTED: Return the string path, not the Directory object.

              return tempDir.path;
            }

            return null;
          },
        );

    // Get the mocked path and initialize Hive for testing.

  }); 

  group('HiveStorage w/ real models', () {
    test(
      'cleanupOrphans removes sessions with started=false (and blobs)',
      () async {
        // Boot storage (opens boxes)
        final storage = HiveStorage();
        await storage.init();

        // Open same boxes to seed data directly
        final sessions = await Hive.openLazyBox<String>('sessions');
        final csvs = await Hive.openLazyBox<List<String>>('csvs');
        final tracks = await Hive.openLazyBox<String>('tracks');

        // Seed: orphan (id 1) and good (id 2)
        const orphanId = 1;
        const goodId = 2;

        final orphan = _sessionInfo(
          started: false,
          finished: false,
          cps: [], // empty is fine; cleanup only checks 'started'
        );
        await sessions.put(orphanId, jsonEncode(orphan.toJson()));
        await csvs.put(orphanId, ['a,b,c']);
        await tracks.put(orphanId, '1, 2, 3');

        final now = DateTime.now().toUtc();
        final good = _sessionInfo(
          started: true,
          finished: false,
          cps: [
            Checkpoint(_tpAt(now, 35.0, -85.0, alt: 500, speed: 40), now, 0),
          ],
        );
        await sessions.put(goodId, jsonEncode(good.toJson()));
        await csvs.put(goodId, ['x,y,z']);
        await tracks.put(goodId,'9, 9, 9');

        // Run cleanup via test hook
        final removed = await storage.cleanupOrphans();
        expect(removed, 1);

        // Orphan gone from all boxes
        expect(await sessions.get(orphanId), isNull);
        expect(await csvs.get(orphanId), isNull);
        expect(await tracks.get(orphanId), isNull);

        // Good one remains
        expect(await sessions.get(goodId), isNotNull);
        expect(await csvs.get(goodId), isNotNull);
        expect(await tracks.get(goodId), isNotNull);
      },
    );

    test(
      'init() restores lastSession only if within 12h and started == true',
      () async {
        // Manually seed boxes BEFORE calling storage.init()
        await Hive.initFlutter('BlueClayRally');
        final sessions = await Hive.openLazyBox<String>('sessions');
        final lastBox = await Hive.openBox<int>('last_session');

        // Make a "fresh" session inside the 12h window
        const sid = 42;
        final t0 = DateTime.now().toUtc().subtract(const Duration(hours: 1));
        final sFresh = _sessionInfo(
          started: true,
          finished: false,
          cps: [Checkpoint(_tpAt(t0, 35.0, -85.0, alt: 450, speed: 55), t0, 7)],
        );
        await sessions.put(sid, jsonEncode(sFresh.toJson()));
        await lastBox.put('last_session_id', sid);

        // Now run init(), which should read last_session_id and sessions[sid]
        final storage = HiveStorage();
        final hasPrev = await storage.init();
        expect(hasPrev, isTrue);
        expect(storage.lastSession, isNotNull);
        expect(storage.lastSession!.started, isTrue);

        // Flip to an old (stale) session
        await _resetHiveDir(); // start clean again
        final storage2 = HiveStorage();
        await storage2.init(); // opens boxes

        final sessions2 = await Hive.openLazyBox<String>('sessions');
        final lastBox2 = await Hive.openBox<int>('last_session');

        const sid2 = 99;
        final oldT = DateTime.now().toUtc().subtract(const Duration(hours: 24));
        final sOld = _sessionInfo(
          started: true,
          finished: false,
          cps: [Checkpoint(_tpAt(oldT, 35.0, -85.0), oldT, 0)],
        );
        await sessions2.put(sid2, jsonEncode(sOld.toJson()));
        await lastBox2.put('last_session_id', sid2);

        final storage3 = HiveStorage();
        final hasPrev2 = await storage3.init();
        expect(hasPrev2, isFalse);
        expect(storage3.lastSession, isNull);
      },
    );

    test(
      'saveSession stores JSON and optional track; readTrack & readCSV work',
      () async {
        final storage = HiveStorage();
        await storage.init();

        // Create a recent, started session model
        final t0 = DateTime.now().toUtc();
        final info = _sessionInfo(
          started: true,
          finished: false,
          cps: [
            Checkpoint(_tpAt(t0, 35.0, -85.0, alt: 512.0, speed: 50), t0, 1),
          ],
        );

        // Save session with a GPX string
        const gpx = '<gpx version="1.1"></gpx>';
        await storage.saveSession(info, gpx);

        // CSV header should be created on first append in saveCSV()
        await storage.saveCSV('t,lat,lon,ele');
        await storage.saveCSV('0,35.0,-85.0,0');

        final trackText = await storage.readTrack();
        expect(trackText, equals(gpx));

        final csv = await storage.readCSV();
        // Header is stored without newline in your implementation; LazyBox join adds '\n'
        expect(
          csv,
          'time,lat,lon,ele\n'
          't,lat,lon,ele\n'
          '0,35.0,-85.0,0',
        );
      },
    );
  });
}
