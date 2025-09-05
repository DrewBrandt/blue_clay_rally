import 'dart:async';
import 'dart:math' as math;

import 'package:blue_clay_rally/models/checkpoint.dart';
import 'package:blue_clay_rally/models/session_info.dart';
import 'package:blue_clay_rally/models/track.dart';
import 'package:blue_clay_rally/providers/ble_provider.dart';
import 'package:blue_clay_rally/providers/gps_packet_provider.dart';
import 'package:blue_clay_rally/storage/hive_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:latlong2/latlong.dart';

typedef StoredSession = (int id, SessionInfo info);

class TrackController extends StateNotifier<Track?> {
  TrackController() : super(null);

  void setTrack(Track track) => state = track;
  void clear() => state = null;
}

final currentTrackProvider = StateNotifierProvider<TrackController, Track?>(
  (ref) => TrackController(),
);

final trackIndexProvider = Provider<int>((ref) {
  return ref.watch(gpsPacketProvider)?.index ?? 0;
});

final checkpointProvider = Provider<List<Checkpoint>>((ref) {
  return ref.watch(appNotifierProvider)?.cps ?? [];
});
final checkpointSingleProvider = Provider.family<Checkpoint?, int>((ref, id) {
  return ref.watch(appNotifierProvider)?.cps.elementAtOrNull(id);
});

final checkpointEditWindowProvider = StateProvider<int?>((_) => null);

// providers.dart (or alongside your other providers)
final sessionSummariesProvider = FutureProvider<List<StoredSession>>((
  ref,
) async {
  final app = ref.read(appNotifierProvider.notifier);
  return app.fetchSessionSummaries();
});

//null if no track loaded
// not null once a track loads, but does not save until track starts
// saves every time a checkpoint is added or edited
class AppNotifier extends Notifier<SessionInfo?> {
  final _storage = HiveStorage();

  // === CSV autosave buffer ===
  static const _csvFlushEvery = Duration(seconds: 5); // time-based flush
  static const _csvFlushBatch = 100; // row count flush
  final List<String> _csvBuffer = <String>[];
  Timer? _csvTimer;

  final Completer<void> _ready = Completer<void>();
  @visibleForTesting
  Future<void> get ready => _ready.future;

  @override
  SessionInfo? build() {
    _init();
    return null;
  }

  Future<void> _init() async {
    await _storage.init();
    if (!_ready.isCompleted) _ready.complete();
    state = SessionInfo(
      trackFileType: 'none',
      trackFileName: 'none',
      cps: [],
      started: false,
      finished: false,
    );
    state = null;
    _startCsvTimer(); // timer lives idle until rows arrive
    debugPrint('Hive Initialized');
  }

  void _startCsvTimer() {
    _csvTimer?.cancel();
    _csvTimer = Timer.periodic(_csvFlushEvery, (_) => _flushCsvBuffer());
  }

  Future<void> _flushCsvBuffer() async {
    if (_csvBuffer.isEmpty) return;
    // Write each row using chunked saver; cheap & bounded. If you prefer a single call
    // you can join with '\n' and add a bulk saver; the chunker will handle size limits.
    final pending = List<String>.from(_csvBuffer);
    _csvBuffer.clear();
    for (final r in pending) {
      await _storage.saveCSV(r);
    }
  }

  // === Public API: call this to append a CSV row (from GPS stream, etc.) ===
  Future<void> logCsvRow(String csvRow) async {
    // Expect "time,lat,lon,ele,..." row (no trailing newline)
    _csvBuffer.add(csvRow);
    if (_csvBuffer.length >= _csvFlushBatch) {
      await _flushCsvBuffer();
    }
  }

  // === Public API: exports (Web/Android/Windows) ===
  Future<void> exportCsv({String? suggestedName}) async {
    await _flushCsvBuffer(); // ensure latest is saved before export
    await _storage.exportCSV(suggestedName: suggestedName);
  }

  Future<void> exportJson({String? suggestedName}) async {
    await _flushCsvBuffer();
    await _storage.exportSessionJson(suggestedName: suggestedName);
  }

  // === Existing APIs (small tweaks noted inline) ===

  Future<void> loadNewFile(String raw, String fileName, String type) async {
    state = SessionInfo(
      trackFileType: type,
      trackFileName: fileName,
      cps: [],
      started: false,
      finished: false,
    );
    await _storage.saveSession(state!, raw);
    type = type.toLowerCase();
    final track = type == 'csv'
        ? await Track.fromCsvString(raw)
        : await Track.fromGpxString(raw);
    ref.read(currentTrackProvider.notifier).setTrack(track);
    ref.read(gpsPacketProvider.notifier).reset();
    // Session is not "started" yet; we’ll set last_session_id on first checkpoint.
  }

  // List sessions for the UI
  Future<List<StoredSession>> fetchSessionSummaries() {
    return _storage.listSessions();
  }

  // Load the chosen session by id — supports merging onto currently loaded track.
  Future<void> loadSessionById(int id) async {
    await _flushCsvBuffer(); // if you added autosave

    final currentTrack = ref.read(currentTrackProvider);
    final currentInfo = state;

    // If there is a track already loaded and names differ, MERGE (new session).
    if (currentTrack != null && currentInfo != null) {
      final incoming = await _storage.peekSession(id);
      if (incoming == null) return;

      final namesDiffer =
          currentInfo.trackFileName != incoming.trackFileName ||
          currentInfo.trackFileType.toLowerCase() !=
              incoming.trackFileType.toLowerCase();

      if (namesDiffer) {
        // Remap old session's checkpoints onto the *current* track
        final remapped = _remapCheckpointsToTrack(
          cpsOld: incoming.cps,
          track: currentTrack,
        );

        // Persist a brand-new session using the *current* track’s raw data
        final currentTrackRaw = await _storage
            .readTrack(); // still the active session’s track
        final merged = incoming.copyWith(
          trackFileName: currentInfo.trackFileName,
          trackFileType: currentInfo.trackFileType,
          cps: remapped,
          started: remapped.isNotEmpty, // start once we have CPs
          // keep .finished from incoming (or recompute if you prefer)
        );

        final newId = await _storage.createNewSession(merged, currentTrackRaw);

        // Publish & UI side-effects (align with old loadPrevious)
        state = merged;
        await save(state); // persist JSON again (cheap; parity with old flow)
        await _storage.updateLastSession(); // point to the new merged id
        ref.read(gpsPacketProvider.notifier).fixProgress();

        // Track is already current; no need to re-parse/re-set.
        return;
      }
    }

    // Otherwise: standard behavior — load that session & its track as-is.
    final info = await _storage.loadSessionById(id);
    if (info == null) return;

    final raw = await _storage.readTrack(); // active _sessionID now equals id
    final track = info.trackFileType.toLowerCase() == 'csv'
        ? await Track.fromCsvString(raw)
        : await Track.fromGpxString(raw);

    ref.read(currentTrackProvider.notifier).setTrack(track);
    ref.read(gpsPacketProvider.notifier).reset();

    state = info;
    await save(state);
    await _storage.updateLastSession();
    ref.read(gpsPacketProvider.notifier).fixProgress();
  }
  // Future<void> loadPrevious() async {
  //   final prev = _storage.lastSession;
  //   if (prev == null) return;
  //   if (state != null) {
  //     if (state!.trackFileName != prev.trackFileName) {
  //       throw UnimplementedError('Both Sessions must refer to the same track file');
  //     }
  //   } else {
  //     await _storage.loadSession(_storage.lastSessionID);
  //     await loadNewFile(await _storage.readTrack(), prev.trackFileName, prev.trackFileType);
  //   }
  //   state = _storage.lastSession;
  //   await save(state);
  //   _storage.updateLastSession();
  //   ref.read(gpsPacketProvider.notifier).fixProgress();
  // }

  Future<void> save(SessionInfo? newState) async {
    state = newState;
    if (newState != null) {
      await _storage.saveSession(newState, null);
    }
  }

  Future<void> setCheckpoint({bool? finished}) async {
    final tps = ref.read(currentTrackProvider)?.points;
    final int idx;
    if (state?.finished ?? false) return;
    if (finished == null || finished == false) {
      idx = ref.read(trackIndexProvider);
    } else {
      idx = (ref.read(currentTrackProvider)?.points.length ?? 1) - 1;
    }

    if (state != null && tps != null && tps.isNotEmpty) {
      final lastCp = state!.cps.lastOrNull;
      final now = DateTime.now();
      final tp = tps[idx];
      final cp = Checkpoint.fromLast(tp: tp, time: now, idx: idx, last: lastCp);

      // Persist session changes
      final wasStarted = state!.started;
      await save(state!.copyWith(cps: [...state!.cps, cp], started: true));

      // Mark as last_session once the user truly "starts"
      if (!wasStarted) {
        await _storage.updateLastSession();
      }
      ref.read(bleProvider.notifier).sendCheckpoint(cpIdx: idx, tpIdx: cp.idx);
    }
  }

  Future<void> removeCheckpoint(Checkpoint c) async {
    if (state != null) {
      await save(
        state!.copyWith(
          cps: state!.cps.where((item) => item.idx != c.idx).toList(),
        ),
      );
    }
  }

  Future<void> updateCheckpoint(Checkpoint o, Checkpoint n) async {
    final s = state;
    if (s == null) return;

    // Find the checkpoint to replace (prefer identity, fall back to value-equality)
    final i = s.cps.indexWhere((c) => identical(c, o) || c == o);
    if (i < 0) return;

    // Build a new list (immutability) and replace at i
    final cps = List<Checkpoint>.of(s.cps);

    // IMPORTANT: last should be the *previous* checkpoint (i-1), not i.
    cps[i] = Checkpoint.fromLast(
      tp: n.tp,
      time: n.time,
      idx: n.idx,
      last: i > 0 ? cps[i - 1] : null,
    );

    // Recompute deltas for all subsequent checkpoints since their "last" changed.
    for (int j = i + 1; j < cps.length; j++) {
      final old = cps[j];
      cps[j] = Checkpoint.fromLast(
        tp: old.tp,
        time: old.time,
        idx: old.idx,
        last: cps[j - 1],
      );
    }

    // Persist new state
    await save(s.copyWith(cps: cps));

    // Notify over BLE (LoRaCP,cpIdx,tpIdx,time)
    await ref
        .read(bleProvider.notifier)
        .sendCheckpoint(cpIdx: i, tpIdx: n.idx, time: n.time);
  }

  Future<void> finish() async {
    if (state != null && !state!.finished && state!.started) {
      await setCheckpoint(finished: true);
      await save(state!.copyWith(finished: true));
      await _flushCsvBuffer(); // make sure all data is persisted
    }
  }

  void dispose() {
    _csvTimer?.cancel();
    // ensure any buffered rows are saved
    // (No await here; Notifier.dispose can’t be async. If you need a guaranteed flush,
    // call a public `shutdown()` from your app lifecycle before provider teardown.)
    // ignore: discarded_futures
    _flushCsvBuffer();
  }

  // Tunables for remapping
  static const _kBaseMeters = 12.0; // initial GPS radius
  static const _kEscalationMeters = <double>[12, 20, 35, 55, 90];
  static const _kTimeBiasMs =
      0.0; // optional soft bias when scoring (0 = pure two-stage selection)
  static const _kMaxBacktrack =
      8; // allow small backtrack if needed (loop crossings)

  // Haversine distance (meters)
  double _distMeters(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);
    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    final h =
        sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;
    return 2 * R * math.asin(math.sqrt(h));
  }

  double _deg2rad(double d) => d * math.pi / 180.0;

  /// Remap a list of checkpoints onto `track`.
  /// - Prefers GPS proximity; if multiple clusters are near (e.g., loops),
  ///   pick the one whose *track-relative time* is closest to the CP’s relative time.
  /// - Enforces mostly-monotonic index growth; allows a tiny backtrack to handle loops.
  List<Checkpoint> _remapCheckpointsToTrack({
    required List<Checkpoint> cpsOld,
    required Track track,
  }) {
    if (cpsOld.isEmpty) return const <Checkpoint>[];

    final pts = track.points; // List<TrackPoint>
    if (pts.isEmpty) return const <Checkpoint>[];

    // Precompute track-relative ms from track start
    final t0 = pts.first.time;
    final trackRel = List<int>.generate(
      pts.length,
      (i) => pts[i].time.difference(t0).inMilliseconds,
    );

    // CP0 is always the start (idx 0)
    final cp0 = cpsOld.first;
    final cp0Time = cp0.time;
    final List<Checkpoint> remapped = [];
    final firstTp = pts.first;
    remapped.add(
      Checkpoint(tp: firstTp, time: cp0.time, idx: 0, delta: Duration.zero),
    );

    var lastIdx = 0;

    for (var n = 1; n < cpsOld.length; n++) {
      final cp = cpsOld[n];
      final cpRel = cp.time.difference(cp0Time).inMilliseconds;
      final cpGps = cp.tp.gps;

      // 1) Fast path: exact-ish GPS equality (floating equality is rare; use tiny epsilon)
      int? chosen;
      const epsilonMeters = 0.2;
      for (var i = math.max(0, lastIdx - _kMaxBacktrack); i < pts.length; i++) {
        if (_distMeters(cpGps, pts[i].gps) <= epsilonMeters) {
          chosen = i;
          break;
        }
      }

      // 2) Otherwise, search by GPS radius (escalating thresholds)
      if (chosen == null) {
        for (final m in _kEscalationMeters) {
          // gather candidates in radius, prefer indices >= lastIdx but allow small backtrack
          final minIdx = math.max(0, lastIdx - _kMaxBacktrack);
          final cand = <int>[];

          for (var i = minIdx; i < pts.length; i++) {
            final d = _distMeters(cpGps, pts[i].gps);
            if (d <= m) cand.add(i);
          }

          if (cand.isNotEmpty) {
            // If many, pick the one whose track-relative time is closest to cpRel.
            // If tie, choose the one with the smallest distance; if still tie, smallest index >= lastIdx.
            cand.sort((i, j) {
              final dtI = (trackRel[i] - cpRel).abs();
              final dtJ = (trackRel[j] - cpRel).abs();
              if (dtI != dtJ) return dtI - dtJ;
              final di = _distMeters(cpGps, pts[i].gps);
              final dj = _distMeters(cpGps, pts[j].gps);
              if (di != dj) return di.compareTo(dj);
              final bi = (i < lastIdx) ? 1 : 0; // prefer forward
              final bj = (j < lastIdx) ? 1 : 0;
              if (bi != bj) return bi - bj;
              return i - j;
            });
            chosen = cand.first;
            break;
          }
        }
      }

      // 3) If still none, fall back to time-only closest point (clamped forward-ish)
      if (chosen == null) {
        // binary-search by time would be faster; linear scan is fine for modest sizes
        var bestI = lastIdx;
        var bestDt = (trackRel[bestI] - cpRel).abs();
        final minIdx = math.max(0, lastIdx - _kMaxBacktrack);
        for (var i = minIdx; i < pts.length; i++) {
          final dt = (trackRel[i] - cpRel).abs();
          if (dt < bestDt) {
            bestDt = dt;
            bestI = i;
          }
        }
        chosen = bestI;
      }

      // Build new CP with recomputed delta against the *new* track timing
      final newTp = pts[chosen];
      final last = remapped.last;
      final delta =
          cp.time.difference(last.time) - newTp.time.difference(last.tp.time);

      remapped.add(
        Checkpoint(tp: newTp, time: cp.time, idx: chosen, delta: delta),
      );
      lastIdx = chosen;
    }

    return remapped;
  }
}

final appNotifierProvider = NotifierProvider<AppNotifier, SessionInfo?>(
  AppNotifier.new,
  isAutoDispose: false,
);
