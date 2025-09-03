import 'package:blue_clay_rally/providers/app_state_provider.dart';
import 'package:blue_clay_rally/providers/bunny_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _formatDuration(Duration d) {
  return (d.isNegative ? '- ' : '+ ') + d.toString().split('.').first.split('-').last.padLeft(8, "0");
}

final deltaProvider = Provider<String>((ref) {
  if (ref.watch(currentTrackProvider) != null) {
    ref.watch(playbackProvider((track: ref.read(currentTrackProvider)!, speed: 1)));
  }
  final cp = ref.watch(checkpointProvider).lastOrNull;
  final lastPassed = ref.watch(currentTrackProvider)?.points[ref.watch(trackIndexProvider)];
  if (cp == null || lastPassed == null) return _formatDuration(Duration());

  final officialDif = lastPassed.time.difference(cp.tp.time);
  final realDif = DateTime.now().difference(cp.time);
  return _formatDuration(realDif - officialDif);
});

final elapsedProvider = Provider<String>((ref) {
  if (ref.watch(currentTrackProvider) != null) {
    ref.watch(playbackProvider((track: ref.read(currentTrackProvider)!, speed: 1)));
  }
  return _formatDuration(DateTime.now().difference(ref.watch(checkpointProvider).firstOrNull?.time ?? DateTime.now()));
});
final remainingProvider = Provider<String>((ref) {
  if (ref.watch(currentTrackProvider) != null) {
    ref.watch(playbackProvider((track: ref.read(currentTrackProvider)!, speed: 1)));
  }
  final lastPassed = ref.watch(currentTrackProvider)?.points[ref.watch(trackIndexProvider)];
  return _formatDuration(
    (lastPassed?.time ?? DateTime.now()).difference(ref.read(currentTrackProvider)?.points.last.time ?? DateTime.now()),
  );
});
