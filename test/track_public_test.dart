import 'package:blue_clay_rally/models/track.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

// Adjust these imports to your package structure:
import 'fixtures.dart';

void main() {
  group('GPX public API', () {
    test('parses points, bounds, center, and speeds from GPX', () async {
      final track = await Track.fromGpxString(sampleGpx);
      expect(track.points.length, 3);

      // First point speed defined and non-negative
      expect(track.points.first.speed, 0.0);

      // Later points have positive speeds
      expect(track.points[1].speed, greaterThan(0));
      expect(track.points[2].speed, greaterThan(0));

      // Bounds monotonic
      final min = track.min, max = track.max;
      expect(min.latitude <= max.latitude, isTrue);
      expect(min.longitude <= max.longitude, isTrue);

      // Center is midpoint
      final center = track.center!;
      expect(
        center.latitude,
        closeTo((min.latitude + max.latitude) / 2.0, 1e-9),
      );
      expect(
        center.longitude,
        closeTo((min.longitude + max.longitude) / 2.0, 1e-9),
      );

      // Points are lat/lon doubles
      expect(track.points[0].gps, isA<LatLng>());
    });

    test('throws on GPX with no usable points', () async {
      const empty = '<gpx version="1.1"><trk><trkseg/></trk></gpx>';
      expect(
        () => Track.fromGpxString(empty),
        throwsA(isA<ErrorDescription>()),
      );
    });

    test('speed units are meters/second (sanity check)', () async {
      final track = await Track.fromGpxString(equator100m5sGpx);
      expect(track.points.length, 2);
      final v = track.points.last.speed; // 100 m over 5 s -> ~20 m/s
      expect(v, closeTo(20.0, 2.0)); // allow geo approximation slack
    });
  });

  group('CSV public API', () {
    test('parses points, altitudes, and speeds from CSV', () async {
      final track = await Track.fromCsvString(sampleCsv);
      expect(track.points.length, 3);

      // Alts carried through
      expect(track.points[0].alt, 300);
      expect(track.points[1].alt, 301);
      expect(track.points[2].alt, 302);

      // Speeds for later points > 0
      expect(track.points[0].speed, 0);
      expect(track.points[1].speed, greaterThan(0));
      expect(track.points[2].speed, greaterThan(0));
    });

    test('rejects CSV without required headers', () async {
      expect(
        () => Track.fromCsvString(badCsvNoHeaders),
        throwsA(isA<ErrorDescription>()),
      );
    });
  });
}
