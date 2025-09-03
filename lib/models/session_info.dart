import 'package:blue_clay_rally/models/checkpoint.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_info.freezed.dart';
part 'session_info.g.dart';

@freezed
abstract class SessionInfo with _$SessionInfo {
  factory SessionInfo({
    required String trackFileType,
    required String trackFileName,
    required List<Checkpoint> cps,
    required bool started,
    required bool finished,
  }) = _SessionInfo;

  factory SessionInfo.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoFromJson(json);
}
