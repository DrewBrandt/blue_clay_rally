import 'dart:async';

import 'package:blue_clay_rally/models/checkpoint.dart';
import 'package:blue_clay_rally/models/session_info.dart';
import 'package:blue_clay_rally/models/track.dart';
import 'package:blue_clay_rally/providers/gps_packet_provider.dart';
import 'package:blue_clay_rally/storage/hive_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class TrackController extends StateNotifier<Track?> {
  TrackController() : super(null);

  void setTrack(Track track) => state = track;
  void clear() => state = null;
}

final currentTrackProvider = StateNotifierProvider<TrackController, Track?>((ref) => TrackController());

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

final hasPreviousSessionProvider = StateProvider<bool>((ref) {
  return false;
});

//null if no track loaded
// not null once a track loads, but does not save until track starts
// saves every time a checkpoint is added or edited
class AppNotifier extends Notifier<SessionInfo?> {
  final _storage = HiveStorage();

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
    state = SessionInfo(trackFileType: 'none', trackFileName: 'none', cps: [], started: false, finished: false);
    state = null;
    ref.read(hasPreviousSessionProvider.notifier).state = _storage.lastSession != null;
  }

  //three options:
  // load new file with no previous
  // load previous with new file
  // load previous with no new file
  Future<void> loadNewFile(String raw, String fileName, String type) async {
    state = SessionInfo(trackFileType: type, trackFileName: fileName, cps: [], started: false, finished: false);
    await _storage.saveSession(state!, raw);
    type = type.toLowerCase();
    final track = type == 'csv' ? await Track.fromCsvString(raw) : await Track.fromGpxString(raw);
    ref.read(currentTrackProvider.notifier).setTrack(track);
    ref.read(gpsPacketProvider.notifier).reset();
  }

  Future<void> loadPrevious() async {
    final prev = _storage.lastSession;
    if (prev == null) return;
    if (state != null) {
      if (state!.trackFileName != prev.trackFileName) {
        throw UnimplementedError('Both Sessions must refer to the same track file');
      }
    } else {
      await _storage.loadSession(_storage.lastSessionID);
      await loadNewFile(await _storage.readTrack(), prev.trackFileName, prev.trackFileType);
    }
    state = _storage.lastSession;
    await save(state);
    _storage.updateLastSession();
    ref.read(gpsPacketProvider.notifier).fixProgress();
    ref.read(hasPreviousSessionProvider.notifier).state = false;
  }

  Future<void> save(SessionInfo? newState) async {
    state = newState;
    if (newState != null) {
      await _storage.saveSession(newState, null);
    }
  }

  Future<void> setCheckpoint({bool? finished}) async {
    final tps = ref.read(currentTrackProvider)?.points;
    final int idx;
    if (finished == null || finished == false) {
      idx = ref.read(trackIndexProvider);
    } else {
      idx = ref.read(currentTrackProvider)?.points.length ?? 1 - 1;
    }

    if (state != null && tps != null && tps.isNotEmpty) {
      final lastCp = state!.cps.lastOrNull;
      final cp = Checkpoint.fromLast(tp: tps[idx], time: DateTime.now(), idx: idx, last: lastCp);
      var old = state;
      await save(state!.copyWith(cps: [...state!.cps, cp], started: true));
      if (!old!.started) {
        await _storage.updateLastSession();
      }
    }
  }

  Future<void> removeCheckpoint(Checkpoint c) async {
    if (state != null) {
      await save(state!.copyWith(cps: state!.cps.where((item) => item.idx != c.idx).toList()));
    }
  }

  Future<void> updateCheckpoint(Checkpoint o, Checkpoint n) async {
    if (state != null) {
      await save(
        state!.copyWith(
          cps: [
            for (int i = 0; i < state!.cps.length; i++)
              if (state!.cps[i] == o) n else state!.cps[i],
          ],
        ),
      );
    }
  }

  Future<void> finish() async {
    if (state != null && !state!.finished && state!.started) {
      setCheckpoint(finished: true);
      await (save(state!.copyWith(finished: true)));
    }
  }
}

final appNotifierProvider = NotifierProvider<AppNotifier, SessionInfo?>(AppNotifier.new, isAutoDispose: false);
