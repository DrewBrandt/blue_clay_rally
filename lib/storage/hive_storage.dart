import 'dart:convert';

import 'package:blue_clay_rally/models/session_info.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveStorage {
  late LazyBox<String> _sessionData; // {sessionID: SessionInfoJSON}
  late LazyBox<List<String>> _csv; // {sessionID: csvData}
  late LazyBox<String> _track; // {sessionID: GPSData}
  late Box<int> _lastSession; // {last_session: SessionInfoJSON}

  int? _sessionID, lastSessionID;

  SessionInfo? lastSession;

  void _requireInit() {
    if (_sessionID == null) {
      throw StateError('Please Initialize before accessing sessions.');
    }
  }

  //returns if there is a previous session started within the last 12 hours
  Future<bool> init() async {
    await Hive.initFlutter('BlueClayRally');
    _sessionData = await Hive.openLazyBox('sessions');
    _lastSession = await Hive.openBox('last_session');
    _csv = await Hive.openLazyBox('csvs');
    _track = await Hive.openLazyBox('tracks');
    await _cleanupOldSessions();

    try {
      lastSessionID = _lastSession.get('last_session_id');
      lastSession = SessionInfo.fromJson(
        jsonDecode(await _sessionData.get(lastSessionID) ?? ''),
      );
      if (lastSession!.started == false ||
          DateTime.now().difference(lastSession!.cps[0].time) >
              Duration(hours: 12)) {
        await _lastSession.delete('last_session_id');
        lastSession = null;
        lastSessionID = null;
      }
    } catch (_) {
      await _lastSession.delete('last_session_id');
      lastSessionID = null;
      lastSession = null;
    }
    _sessionID = (_sessionData.isEmpty
        ? 0
        : (_sessionData.keys.last as int) + 1);

    return lastSession != null;
  }

  Future<SessionInfo?> loadSession(int? id) async {
    _requireInit();
    int oldID = _sessionID!;
    try {
      _sessionID = id;
      return SessionInfo.fromJson(
        jsonDecode((await _sessionData.get(id ?? lastSessionID)) ?? ''),
      );
    } catch (e) {
      _sessionID = oldID;
      return null;
    }
  }

  Future<void> saveSession(SessionInfo info, String? trackData) async {
    _requireInit();
    await _sessionData.put(_sessionID, jsonEncode(info.toJson()));
    if (trackData != null) await _track.put(_sessionID, trackData);
  }

  Future<void> updateLastSession() async {
    _requireInit();
    await _lastSession.put('last_session_id', _sessionID!);
  }

  Future<void> saveCSV(String text) async {
    _requireInit();
    if (!_csv.containsKey(_sessionID)) {
      await _csv.put(_sessionID, ['time,lat,lon,ele']);
    }
    final curText = await _csv.get(_sessionID) ?? [];
    curText.add(text);
    await _csv.put(_sessionID, curText);
  }

  Future<String> readTrack() async {
    _requireInit();
    return await _track.get(_sessionID) ?? '';
  }

  Future<String> readCSV() async {
    _requireInit();
    return (await _csv.get(_sessionID, defaultValue: []))!.join('\n');
  }

  Future<void> close() async {
    _requireInit();
    await _csv.close();
    await _sessionData.close();
    await _lastSession.close();
    await _track.close();
  }

  Future<void> _cleanupOldSessions() async {
    for (final key in _sessionData.keys) {
      final json = await _sessionData.get(key);
      if (json == null) {
        print('NO DATA | deleted $key: $json');
        await _sessionData.delete(key);
        await _csv.delete(key);
        await _track.delete(key);
        continue;
      }
      Map<String, dynamic> m;
      try {
        m = jsonDecode(json) as Map<String, dynamic>;
      } catch (_) {
        print('CORRUPT | deleted $key: $json');
        // Corrupt JSON: remove it and any blobs tied to this id
        await _sessionData.delete(key);
        await _csv.delete(key);
        await _track.delete(key);
        continue;
      }
      final started = (m['started'] as bool?) ?? false;
      if (!started) {
        print('NOT STARTED | deleted $key: $json');
        await _sessionData.delete(key);
        await _csv.delete(key);
        await _track.delete(key);
      }
    }
  }

  Future<int> cleanupOrphans() async {
    final before = (_sessionData).length; // LazyBox.length is sync
    await _cleanupOldSessions();
    final after = (_sessionData).length;
    return before - after;
  }
}
