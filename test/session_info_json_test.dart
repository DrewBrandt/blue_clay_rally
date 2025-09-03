// test/session_info_json_test.dart
import 'dart:convert';
import 'package:blue_clay_rally/models/track.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:blue_clay_rally/models/session_info.dart';
import 'package:blue_clay_rally/models/checkpoint.dart';

void main() {
  group('SessionInfo JSON', () {
    test('toJson -> fromJson round trip preserves fields', () {
      var tp = TrackPoint(
        DateTime.utc(2025, 8, 26, 12, 0, 0),
        const LatLng(35.0, -85.0),
        512.0,
      );
      tp.speed = 50;
      final cp = Checkpoint(tp, DateTime.utc(2025, 8, 26, 12, 0, 10), 7);

      final original = SessionInfo(
        trackFileType: 'csv',
        trackFileName: 'test',
        cps: [cp],
        started: true,
        finished: false,
      );

      // Serialize → JSON string
      final jsonStr = jsonEncode(original.toJson());

      // Deserialize → object
      final decoded = SessionInfo.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );

      // Compare top-level fields
      expect(decoded.trackFileName, equals(original.trackFileName));
      expect(decoded.trackFileType, equals(original.trackFileType));
      expect(decoded.started, equals(original.started));
      expect(decoded.finished, equals(original.finished));
      expect(decoded.cps.length, equals(1));

      // Compare nested checkpoint
      final cpDecoded = decoded.cps.first;
      expect(cpDecoded.idx, equals(cp.idx));
      expect(cpDecoded.time, equals(cp.time));

      // Compare nested trackpoint
      final tpDecoded = cpDecoded.tp;
      expect(tpDecoded.time, equals(tp.time));
      expect(tpDecoded.alt, equals(tp.alt));
      expect(tpDecoded.gps.latitude, closeTo(tp.gps.latitude, 1e-9));
      expect(tpDecoded.gps.longitude, closeTo(tp.gps.longitude, 1e-9));
      expect(tpDecoded.speed, equals(tp.speed));
    });
  });
}
