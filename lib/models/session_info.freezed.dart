// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionInfo {

 String get trackFileType; String get trackFileName; List<Checkpoint> get cps; bool get started; bool get finished;
/// Create a copy of SessionInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionInfoCopyWith<SessionInfo> get copyWith => _$SessionInfoCopyWithImpl<SessionInfo>(this as SessionInfo, _$identity);

  /// Serializes this SessionInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionInfo&&(identical(other.trackFileType, trackFileType) || other.trackFileType == trackFileType)&&(identical(other.trackFileName, trackFileName) || other.trackFileName == trackFileName)&&const DeepCollectionEquality().equals(other.cps, cps)&&(identical(other.started, started) || other.started == started)&&(identical(other.finished, finished) || other.finished == finished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trackFileType,trackFileName,const DeepCollectionEquality().hash(cps),started,finished);

@override
String toString() {
  return 'SessionInfo(trackFileType: $trackFileType, trackFileName: $trackFileName, cps: $cps, started: $started, finished: $finished)';
}


}

/// @nodoc
abstract mixin class $SessionInfoCopyWith<$Res>  {
  factory $SessionInfoCopyWith(SessionInfo value, $Res Function(SessionInfo) _then) = _$SessionInfoCopyWithImpl;
@useResult
$Res call({
 String trackFileType, String trackFileName, List<Checkpoint> cps, bool started, bool finished
});




}
/// @nodoc
class _$SessionInfoCopyWithImpl<$Res>
    implements $SessionInfoCopyWith<$Res> {
  _$SessionInfoCopyWithImpl(this._self, this._then);

  final SessionInfo _self;
  final $Res Function(SessionInfo) _then;

/// Create a copy of SessionInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trackFileType = null,Object? trackFileName = null,Object? cps = null,Object? started = null,Object? finished = null,}) {
  return _then(_self.copyWith(
trackFileType: null == trackFileType ? _self.trackFileType : trackFileType // ignore: cast_nullable_to_non_nullable
as String,trackFileName: null == trackFileName ? _self.trackFileName : trackFileName // ignore: cast_nullable_to_non_nullable
as String,cps: null == cps ? _self.cps : cps // ignore: cast_nullable_to_non_nullable
as List<Checkpoint>,started: null == started ? _self.started : started // ignore: cast_nullable_to_non_nullable
as bool,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionInfo].
extension SessionInfoPatterns on SessionInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionInfo value)  $default,){
final _that = this;
switch (_that) {
case _SessionInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionInfo value)?  $default,){
final _that = this;
switch (_that) {
case _SessionInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String trackFileType,  String trackFileName,  List<Checkpoint> cps,  bool started,  bool finished)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionInfo() when $default != null:
return $default(_that.trackFileType,_that.trackFileName,_that.cps,_that.started,_that.finished);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String trackFileType,  String trackFileName,  List<Checkpoint> cps,  bool started,  bool finished)  $default,) {final _that = this;
switch (_that) {
case _SessionInfo():
return $default(_that.trackFileType,_that.trackFileName,_that.cps,_that.started,_that.finished);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String trackFileType,  String trackFileName,  List<Checkpoint> cps,  bool started,  bool finished)?  $default,) {final _that = this;
switch (_that) {
case _SessionInfo() when $default != null:
return $default(_that.trackFileType,_that.trackFileName,_that.cps,_that.started,_that.finished);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionInfo implements SessionInfo {
   _SessionInfo({required this.trackFileType, required this.trackFileName, required final  List<Checkpoint> cps, required this.started, required this.finished}): _cps = cps;
  factory _SessionInfo.fromJson(Map<String, dynamic> json) => _$SessionInfoFromJson(json);

@override final  String trackFileType;
@override final  String trackFileName;
 final  List<Checkpoint> _cps;
@override List<Checkpoint> get cps {
  if (_cps is EqualUnmodifiableListView) return _cps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cps);
}

@override final  bool started;
@override final  bool finished;

/// Create a copy of SessionInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionInfoCopyWith<_SessionInfo> get copyWith => __$SessionInfoCopyWithImpl<_SessionInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionInfo&&(identical(other.trackFileType, trackFileType) || other.trackFileType == trackFileType)&&(identical(other.trackFileName, trackFileName) || other.trackFileName == trackFileName)&&const DeepCollectionEquality().equals(other._cps, _cps)&&(identical(other.started, started) || other.started == started)&&(identical(other.finished, finished) || other.finished == finished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trackFileType,trackFileName,const DeepCollectionEquality().hash(_cps),started,finished);

@override
String toString() {
  return 'SessionInfo(trackFileType: $trackFileType, trackFileName: $trackFileName, cps: $cps, started: $started, finished: $finished)';
}


}

/// @nodoc
abstract mixin class _$SessionInfoCopyWith<$Res> implements $SessionInfoCopyWith<$Res> {
  factory _$SessionInfoCopyWith(_SessionInfo value, $Res Function(_SessionInfo) _then) = __$SessionInfoCopyWithImpl;
@override @useResult
$Res call({
 String trackFileType, String trackFileName, List<Checkpoint> cps, bool started, bool finished
});




}
/// @nodoc
class __$SessionInfoCopyWithImpl<$Res>
    implements _$SessionInfoCopyWith<$Res> {
  __$SessionInfoCopyWithImpl(this._self, this._then);

  final _SessionInfo _self;
  final $Res Function(_SessionInfo) _then;

/// Create a copy of SessionInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trackFileType = null,Object? trackFileName = null,Object? cps = null,Object? started = null,Object? finished = null,}) {
  return _then(_SessionInfo(
trackFileType: null == trackFileType ? _self.trackFileType : trackFileType // ignore: cast_nullable_to_non_nullable
as String,trackFileName: null == trackFileName ? _self.trackFileName : trackFileName // ignore: cast_nullable_to_non_nullable
as String,cps: null == cps ? _self._cps : cps // ignore: cast_nullable_to_non_nullable
as List<Checkpoint>,started: null == started ? _self.started : started // ignore: cast_nullable_to_non_nullable
as bool,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
