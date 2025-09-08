import 'dart:convert';
import 'dart:typed_data';

import 'package:blue_clay_rally/models/session_info.dart';
import 'package:file_saver/file_saver.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';



// A record for (id, info) — uses your existing SessionInfo
typedef StoredSession = (int id, SessionInfo info);

extension _KeyScan on HiveStorage {
  int _computeNextId(Iterable keys) {
    var maxId = -1;
    for (final k in keys) {
      if (k is int && k > maxId) maxId = k;
    }
    return maxId + 1;
  }
}
class HiveStorage {
  late LazyBox<String> _sessionData; // {sessionID: SessionInfoJSON}
  late LazyBox<String> _track; // {sessionID: GPSData}
  late Box<int> _lastSession; // {last_session: SessionInfoJSON}

  // NEW: add alongside your existing fields
  late LazyBox<String> _csv; // chunk payloads: key = "csv:{sid}:{chunk}"
  late Box<Map>
  _csvMeta; // per-session meta: key = "csvmeta:{sid}" => {chunk:int, lines:int, bytes:int}

  static const _CSV_HEADER = 'time,lat,lon,ele';
  static const _MAX_LINES_PER_CHUNK = 5_000; // tune as needed
  static const _MAX_BYTES_PER_CHUNK = 256 * 1024; // ~256 KB per chunk

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
    _csvMeta = await Hive.openBox<Map>('csv_meta'); // NEW
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

  Future<void> saveCSV(String row) async {
    _requireInit();
    final sid = _sessionID!;
    var meta = await _loadCsvMeta(sid);

    // ensure single leading newline on append
    final addition = '\n$row';
    final willLines = meta.lines + 1;
    final willBytes = meta.bytes + addition.length;

    // rotate chunk if limits exceeded
    if (willLines > _MAX_LINES_PER_CHUNK || willBytes > _MAX_BYTES_PER_CHUNK) {
      meta = _Meta(chunk: meta.chunk + 1, lines: 0, bytes: 0);
      // first write to new chunk should NOT repeat header
      await _csv.put(_csvKey(sid, meta.chunk), '');
    }

    final key = _csvKey(sid, meta.chunk);
    final cur = (await _csv.get(key)) ?? '';
    final next = cur.isEmpty ? row : (cur + addition);
    await _csv.put(key, next);

    meta.lines += 1;
    meta.bytes += (cur.isEmpty ? row.length : addition.length);
    await _saveCsvMeta(sid, meta);
  }

  Future<String> readTrack() async {
    _requireInit();
    return await _track.get(_sessionID) ?? '';
  }

  Future<String> readCSV() async {
    _requireInit();
    final sid = _sessionID!;
    final meta = await _loadCsvMeta(sid);
    final buf = StringBuffer();

    for (int i = 0; i <= meta.chunk; i++) {
      final s = await _csv.get(_csvKey(sid, i));
      if (s != null && s.isNotEmpty) {
        if (buf.isNotEmpty && !s.startsWith('\n')) buf.write('\n');
        buf.write(s);
      }
    }
    return buf.toString();
  }

  // CSV
  Future<void> exportCSV({String? suggestedName}) async {
    _requireInit();
    final sid = _sessionID!;
    final content = await readCSV();
    final bytes = Uint8List.fromList(content.codeUnits);

    final name = suggestedName ?? 'session_${sid}_track';
    await FileSaver.instance.saveAs(
      name: name,
      fileExtension: 'csv',
      bytes: bytes,
      mimeType: MimeType.csv,
    );
  }

  // JSON (SessionInfo + optional track)
  Future<void> exportSessionJson({String? suggestedName}) async {
    _requireInit();
    final sid = _sessionID!;
    final json = await _sessionData.get(sid);
    if (json == null || json.isEmpty) {
      throw StateError('No session JSON to export.');
    }

    final name = suggestedName ?? 'session_${sid}_info';
    await FileSaver.instance.saveAs(
      name: name,
      fileExtension: 'json',
      bytes: Uint8List.fromList(json.codeUnits),
      mimeType: MimeType.json,
    );
  }

  String _csvKey(int sid, int chunk) => 'csv:$sid:$chunk';
  String _csvMetaKey(int sid) => 'csvmeta:$sid';

  Future<_Meta> _loadCsvMeta(int sid) async {
    final m = _csvMeta.get(_csvMetaKey(sid));
    if (m == null) {
      // create chunk 0 with header
      final key = _csvKey(sid, 0);
      await _csv.put(key, _CSV_HEADER);
      final meta = _Meta(chunk: 0, lines: 1, bytes: _CSV_HEADER.length);
      await _csvMeta.put(_csvMetaKey(sid), meta.toMap());
      return meta;
    }
    return _Meta.fromMap(Map<String, dynamic>.from(m));
  }

  Future<void> _saveCsvMeta(int sid, _Meta meta) async {
    await _csvMeta.put(_csvMetaKey(sid), meta.toMap());
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
      await _csvMeta.delete(_csvMetaKey(key as int));
      int i = 0;
      while (true) {
        final k = _csvKey(key, i);
        if (!_csv.containsKey(k)) break;
        await _csv.delete(k);
        i++;
      }
    }
  }

  Future<int> cleanupOrphans() async {
    final before = (_sessionData).length; // LazyBox.length is sync
    await _cleanupOldSessions();
    final after = (_sessionData).length;
    return before - after;
  }


  // List sessions in reverse-chronological order (by first CP time if present, else by id)
  Future<List<StoredSession>> listSessions({int? limit}) async {
    final List<StoredSession> out = [];
    for (final k in _sessionData.keys) {
      if (k is! int) continue;
      final json = await _sessionData.get(k);
      if (json == null || json.isEmpty) continue;
      try {
        final info = SessionInfo.fromJson(jsonDecode(json) as Map<String, dynamic>);
        out.add((k, info));
      } catch (_) {
        // ignore; _cleanupOldSessions will handle corrupt entries
      }
    }

    int byStartedTime(StoredSession a, StoredSession b) {
      final aTime = (a.$2.cps.isNotEmpty) ? a.$2.cps.first.time : null;
      final bTime = (b.$2.cps.isNotEmpty) ? b.$2.cps.first.time : null;
      if (aTime != null && bTime != null) return bTime.compareTo(aTime); // desc
      if (aTime != null) return -1;
      if (bTime != null) return 1;
      return b.$1.compareTo(a.$1); // fallback: id desc
    }

    out.sort(byStartedTime);
    if (limit != null && out.length > limit) {
      return out.sublist(0, limit);
    }
    return out;
  }

  // Load a specific session by id and make it active in this storage
  Future<SessionInfo?> loadSessionById(int id) async {
    return await loadSession(id); // your existing method sets _sessionID=id when successful
  }

  // (Optional helper) Read track for a specific id, without changing external API.
  Future<String> readTrackById(int id) async {
    final prev = _sessionID;
    try {
      _sessionID = id;
      return await readTrack();
    } finally {
      _sessionID = prev; // restore
    }
  }
  /// Read a session by id *without* changing the active _sessionID.
  Future<SessionInfo?> peekSession(int id) async {
    final json = await _sessionData.get(id);
    if (json == null || json.isEmpty) return null;
    return SessionInfo.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Create a brand-new session id, set it active, and save JSON + track.
  Future<int> createNewSession(SessionInfo info, String trackData) async {
    final newId = _computeNextId(_sessionData.keys);
    _sessionID = newId;
    await _sessionData.put(_sessionID, jsonEncode(info.toJson()));
    await _track.put(_sessionID, trackData);
    // CSV chunks/meta will be created lazily on first CSV write, which is fine.
    return newId;
  }
}

class _Meta {
  int chunk;
  int lines;
  int bytes;
  _Meta({required this.chunk, required this.lines, required this.bytes});
  Map<String, dynamic> toMap() => {
    'chunk': chunk,
    'lines': lines,
    'bytes': bytes,
  };
  static _Meta fromMap(Map<String, dynamic> m) => _Meta(
    chunk: m['chunk'] ?? 0,
    lines: m['lines'] ?? 0,
    bytes: m['bytes'] ?? 0,
  );


}
