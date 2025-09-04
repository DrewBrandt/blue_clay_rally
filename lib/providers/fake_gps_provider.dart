import 'dart:io';

import 'package:blue_clay_rally/models/track.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

String data = r"C:\Users\Snoopy\Documents\blue_clay_rally\lib\out.gpx";

class FakeGpsNotifier extends Notifier<Track?> {
  @override
  Track? build() {
    _load();
    return null; // initial
  }

  Future<void> _load() async {
    // final f = await FilePicker.platform.pickFiles();
    // final xml = await File(f!.files.single.path!).readAsString();
    if (!kIsWeb && Platform.isWindows) {
      final xml = await File(data).readAsString();
      final t = await Track.fromGpxString(xml);
      state = t;
    }
  }
}

final fakeGpsProvider = NotifierProvider<FakeGpsNotifier, Track?>(FakeGpsNotifier.new);

final fakeGpsIndexProvider = StateProvider<int?>((ref) {
  return null;
});
