// GPX with 3 points (10 s spacing)
const sampleGpx = '''
<gpx version="1.1" creator="test">
  <trk><name>demo</name>
    <trkseg>
      <trkpt lat="35.000000" lon="-85.000000"><ele>300</ele><time>2024-01-01T00:00:00Z</time></trkpt>
      <trkpt lat="35.000450" lon="-85.000450"><ele>301</ele><time>2024-01-01T00:00:10Z</time></trkpt>
      <trkpt lat="35.001000" lon="-85.001000"><ele>302</ele><time>2024-01-01T00:00:20Z</time></trkpt>
    </trkseg>
  </trk>
</gpx>
''';

// CSV with 3 points (10 s spacing)
const sampleCsv = '''
time,lat,lon,ele
2024-01-01T00:00:00Z,35.000000,-85.000000,300
2024-01-01T00:00:10Z,35.000450,-85.000450,301
2024-01-01T00:00:20Z,35.001000,-85.001000,302
''';

// CSV missing required headers (should throw)
const badCsvNoHeaders = '''
foo,bar,baz
1,2,3
''';

// GPX engineered for a unit check: 100 m east in 5 s at the equator.
// 1 deg lon at equator ≈ 111_319.49 m → 100 m ≈ 0.0008983153°
const equator100m5sGpx = '''
<gpx version="1.1" creator="test">
  <trk><trkseg>
    <trkpt lat="0.000000" lon="0.000000"><time>2024-01-01T00:00:00Z</time></trkpt>
    <trkpt lat="0.000000" lon="0.0008983153"><time>2024-01-01T00:00:05Z</time></trkpt>
  </trkseg></trk>
</gpx>
''';
