// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkpoint.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Checkpoint {

 TrackPoint get tp; DateTime get time; int get idx; Duration get delta;
/// Create a copy of Checkpoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckpointCopyWith<Checkpoint> get copyWith => _$CheckpointCopyWithImpl<Checkpoint>(this as Checkpoint, _$identity);

  /// Serializes this Checkpoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Checkpoint&&(identical(other.tp, tp) || other.tp == tp)&&(identical(other.time, time) || other.time == time)&&(identical(other.idx, idx) || other.idx == idx)&&(identical(other.delta, delta) || other.delta == delta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tp,time,idx,delta);

@override
String toString() {
  return 'Checkpoint(tp: $tp, time: $time, idx: $idx, delta: $delta)';
}


}

/// @nodoc
abstract mixin class $CheckpointCopyWith<$Res>  {
  factory $CheckpointCopyWith(Checkpoint value, $Res Function(Checkpoint) _then) = _$CheckpointCopyWithImpl;
@useResult
$Res call({
 TrackPoint tp, DateTime time, int idx, Duration delta
});




}
/// @nodoc
class _$CheckpointCopyWithImpl<$Res>
    implements $CheckpointCopyWith<$Res> {
  _$CheckpointCopyWithImpl(this._self, this._then);

  final Checkpoint _self;
  final $Res Function(Checkpoint) _then;

/// Create a copy of Checkpoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tp = null,Object? time = null,Object? idx = null,Object? delta = null,}) {
  return _then(_self.copyWith(
tp: null == tp ? _self.tp : tp // ignore: cast_nullable_to_non_nullable
as TrackPoint,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,idx: null == idx ? _self.idx : idx // ignore: cast_nullable_to_non_nullable
as int,delta: null == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [Checkpoint].
extension CheckpointPatterns on Checkpoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Checkpoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Checkpoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Checkpoint value)  $default,){
final _that = this;
switch (_that) {
case _Checkpoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Checkpoint value)?  $default,){
final _that = this;
switch (_that) {
case _Checkpoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TrackPoint tp,  DateTime time,  int idx,  Duration delta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Checkpoint() when $default != null:
return $default(_that.tp,_that.time,_that.idx,_that.delta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TrackPoint tp,  DateTime time,  int idx,  Duration delta)  $default,) {final _that = this;
switch (_that) {
case _Checkpoint():
return $default(_that.tp,_that.time,_that.idx,_that.delta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TrackPoint tp,  DateTime time,  int idx,  Duration delta)?  $default,) {final _that = this;
switch (_that) {
case _Checkpoint() when $default != null:
return $default(_that.tp,_that.time,_that.idx,_that.delta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Checkpoint extends Checkpoint {
   _Checkpoint({required this.tp, required this.time, required this.idx, required this.delta}): super._();
  factory _Checkpoint.fromJson(Map<String, dynamic> json) => _$CheckpointFromJson(json);

@override final  TrackPoint tp;
@override final  DateTime time;
@override final  int idx;
@override final  Duration delta;

/// Create a copy of Checkpoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckpointCopyWith<_Checkpoint> get copyWith => __$CheckpointCopyWithImpl<_Checkpoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckpointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Checkpoint&&(identical(other.tp, tp) || other.tp == tp)&&(identical(other.time, time) || other.time == time)&&(identical(other.idx, idx) || other.idx == idx)&&(identical(other.delta, delta) || other.delta == delta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tp,time,idx,delta);

@override
String toString() {
  return 'Checkpoint(tp: $tp, time: $time, idx: $idx, delta: $delta)';
}


}

/// @nodoc
abstract mixin class _$CheckpointCopyWith<$Res> implements $CheckpointCopyWith<$Res> {
  factory _$CheckpointCopyWith(_Checkpoint value, $Res Function(_Checkpoint) _then) = __$CheckpointCopyWithImpl;
@override @useResult
$Res call({
 TrackPoint tp, DateTime time, int idx, Duration delta
});




}
/// @nodoc
class __$CheckpointCopyWithImpl<$Res>
    implements _$CheckpointCopyWith<$Res> {
  __$CheckpointCopyWithImpl(this._self, this._then);

  final _Checkpoint _self;
  final $Res Function(_Checkpoint) _then;

/// Create a copy of Checkpoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tp = null,Object? time = null,Object? idx = null,Object? delta = null,}) {
  return _then(_Checkpoint(
tp: null == tp ? _self.tp : tp // ignore: cast_nullable_to_non_nullable
as TrackPoint,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,idx: null == idx ? _self.idx : idx // ignore: cast_nullable_to_non_nullable
as int,delta: null == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

// dart format on
