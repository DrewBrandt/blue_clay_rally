import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:blue_clay_rally/models/checkpoint.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'package:gpx/gpx.dart';
import 'package:csv/csv.dart';

part 'track.g.dart';


@JsonSerializable()
class TrackPoint {
  final LatLng gps;
  final double? alt;
  final DateTime time;
  late final double speed;

  TrackPoint(this.time, this.gps, this.alt);

  factory TrackPoint.fromJson(Map<String, dynamic> json) => _$TrackPointFromJson(json);

  Map<String, dynamic> toJson() => _$TrackPointToJson(this);
}

class Track {
  final List<TrackPoint> points; // growable
  final List<Checkpoint> ways; // your type
  final LatLng min; // SW bound (minLat, minLon)
  final LatLng max; // NE bound (maxLat, maxLon)
  late final String filename;

  Track({this.points = const [], this.ways = const [], this.min = const LatLng(0, 0), this.max = const LatLng(0, 0)});

  LatLng? get center {
    return LatLng((min.latitude + max.latitude) / 2.0, (min.longitude + max.longitude) / 2.0);
  }

  // ---------- Parsing helpers ----------

  // Preferred: parse from a string (works on web too)
  static Future<Track> fromGpxString(String xml) async {
    // Offload heavy parsing off the UI thread
    return compute(_parseGpxString, xml);
  }

  // Native only: convenience for files
  static Future<Track> fromGpxFile(String path) async {
    final xml = await File(path).readAsString();
    // Also offload the parse
    final a = await compute(_parseGpxString, xml);
    a.filename = path;
    return a;
  }

  // Preferred: parse from a string (works on web too)
  static Future<Track> fromCsvString(String csv) async {
    // Offload heavy parsing off the UI thread
    return compute(_parseCsvString, csv);
  }

  // Native only: convenience for files
  static Future<Track> fromCsvFile(String path) async {
    final csv = await File(path).readAsString();
    // Also offload the parse
    final a = await compute(_parseCsvString, csv);
    a.filename = path;
    return a;
  }
}

// Runs in a background isolate via compute()
Track _parseGpxString(String xml) {
  final gpx = GpxReader().fromString(xml);

  final pts = <TrackPoint>[];
  double? minLat, minLon, maxLat, maxLon;
  // int skipped = 0;

  for (final trk in gpx.trks) {
    for (final seg in trk.trksegs) {
      for (final p in seg.trkpts) {
        final t = p.time;
        final lat = p.lat;
        final lon = p.lon;
        if (t == null || lat == null || lon == null) {
          // skipped++;
          continue; // skip invalid points instead of throwing
        }
        final tp = TrackPoint(t.toUtc(), LatLng(lat, lon), p.ele);
        tp.speed = pts.isNotEmpty ? _calcSpeedBetweenPoints(pts.last, tp) : 0.0;
        pts.add(tp);

        // update bounds
        minLat = lat < (minLat ?? double.infinity) ? lat : minLat;
        maxLat = lat > (maxLat ?? double.negativeInfinity) ? lat : maxLat;
        minLon = lon < (minLon ?? double.infinity) ? lon : minLon;
        maxLon = lon > (maxLon ?? double.negativeInfinity) ? lon : maxLon;
      }
    }
  }
  if (pts.isEmpty) throw ErrorDescription("No points Added.");

  final min = LatLng(minLat!, minLon!);
  final max = LatLng(maxLat!, maxLon!);

  return Track(points: pts, ways: const [], min: min, max: max);
}

Track _parseCsvString(String csv) {
  var data = CsvToListConverter(shouldParseNumbers: true, eol: '\n').convert(csv);
  if (data.isEmpty || data.length < 3) {
    throw ErrorDescription('Could not parse any data from CSV');
  }
  var headers = data[0];
  var colIndexes = <int, int>{};
  var ok = 0;
  //column order: time, lat, lon, ele?
  for (int i = 0; i < headers.length; i++) {
    final String h = headers[i].toString().toLowerCase();
    if (h.contains("time")) {
      colIndexes[0] = i;
      ok++;
    } else if (h.contains("lat")) {
      ok++;
      colIndexes[1] = i;
    } else if (h.contains("lon") || h.contains("lng")) {
      ok++;
      colIndexes[2] = i;
    } else if (h.contains('ele') || h.contains('alt')) {
      colIndexes[3] = i;
    }
  }
  if (ok < 3) throw ErrorDescription('Could not parse column headers from CSV');

  double? minLat, minLon, maxLat, maxLon;
  final pts = <TrackPoint>[];
  for (int i = 1; i < data.length; i++) {
    var line = data[i];
    final t = DateTime.parse(line[colIndexes[0]!]).toUtc();
    final lat = (line[colIndexes[1]!] as num).toDouble();
    final lon = (line[colIndexes[2]!] as num).toDouble();
    final ele = colIndexes.containsKey(3) ? (line[colIndexes[3]!] as num?)?.toDouble() : null;

    var tp = TrackPoint(t, LatLng(lat, lon), ele);
    tp.speed = pts.isNotEmpty ? _calcSpeedBetweenPoints(pts.last, tp) : 0.0;
    pts.add(tp);
    minLat = lat < (minLat ?? double.infinity) ? lat : minLat;
    maxLat = lat > (maxLat ?? double.negativeInfinity) ? lat : maxLat;
    minLon = lon < (minLon ?? double.infinity) ? lon : minLon;
    maxLon = lon > (maxLon ?? double.negativeInfinity) ? lon : maxLon;
  }

  if (pts.isEmpty) throw ErrorDescription("No points Added.");

  final min = LatLng(minLat!, minLon!);
  final max = LatLng(maxLat!, maxLon!);

  return Track(points: pts, ways: const [], min: min, max: max);
}

double _calcSpeedBetweenPoints(TrackPoint a, TrackPoint b) {
  return haversine(a.gps.latitude, a.gps.longitude, b.gps.latitude, b.gps.longitude) /
      (b.time.difference(a.time).inMilliseconds / 1000.0);
}

/// Returns distance in meters between two lat/lon points using the Haversine formula.
double haversine(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000; // meters
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);

  final a = pow(sin(dLat / 2), 2) + cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * pow(sin(dLon / 2), 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}

double _degToRad(double deg) => deg * pi / 180.0;
