// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gps_packet.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GpsPacket {

 TrackPoint get tp; int? get index;
/// Create a copy of GpsPacket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GpsPacketCopyWith<GpsPacket> get copyWith => _$GpsPacketCopyWithImpl<GpsPacket>(this as GpsPacket, _$identity);

  /// Serializes this GpsPacket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GpsPacket&&(identical(other.tp, tp) || other.tp == tp)&&(identical(other.index, index) || other.index == index));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tp,index);

@override
String toString() {
  return 'GpsPacket(tp: $tp, index: $index)';
}


}

/// @nodoc
abstract mixin class $GpsPacketCopyWith<$Res>  {
  factory $GpsPacketCopyWith(GpsPacket value, $Res Function(GpsPacket) _then) = _$GpsPacketCopyWithImpl;
@useResult
$Res call({
 TrackPoint tp, int? index
});




}
/// @nodoc
class _$GpsPacketCopyWithImpl<$Res>
    implements $GpsPacketCopyWith<$Res> {
  _$GpsPacketCopyWithImpl(this._self, this._then);

  final GpsPacket _self;
  final $Res Function(GpsPacket) _then;

/// Create a copy of GpsPacket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tp = null,Object? index = freezed,}) {
  return _then(_self.copyWith(
tp: null == tp ? _self.tp : tp // ignore: cast_nullable_to_non_nullable
as TrackPoint,index: freezed == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [GpsPacket].
extension GpsPacketPatterns on GpsPacket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GpsPacket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GpsPacket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GpsPacket value)  $default,){
final _that = this;
switch (_that) {
case _GpsPacket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GpsPacket value)?  $default,){
final _that = this;
switch (_that) {
case _GpsPacket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TrackPoint tp,  int? index)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GpsPacket() when $default != null:
return $default(_that.tp,_that.index);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TrackPoint tp,  int? index)  $default,) {final _that = this;
switch (_that) {
case _GpsPacket():
return $default(_that.tp,_that.index);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TrackPoint tp,  int? index)?  $default,) {final _that = this;
switch (_that) {
case _GpsPacket() when $default != null:
return $default(_that.tp,_that.index);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GpsPacket implements GpsPacket {
   _GpsPacket({required this.tp, this.index});
  factory _GpsPacket.fromJson(Map<String, dynamic> json) => _$GpsPacketFromJson(json);

@override final  TrackPoint tp;
@override final  int? index;

/// Create a copy of GpsPacket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GpsPacketCopyWith<_GpsPacket> get copyWith => __$GpsPacketCopyWithImpl<_GpsPacket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GpsPacketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GpsPacket&&(identical(other.tp, tp) || other.tp == tp)&&(identical(other.index, index) || other.index == index));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tp,index);

@override
String toString() {
  return 'GpsPacket(tp: $tp, index: $index)';
}


}

/// @nodoc
abstract mixin class _$GpsPacketCopyWith<$Res> implements $GpsPacketCopyWith<$Res> {
  factory _$GpsPacketCopyWith(_GpsPacket value, $Res Function(_GpsPacket) _then) = __$GpsPacketCopyWithImpl;
@override @useResult
$Res call({
 TrackPoint tp, int? index
});




}
/// @nodoc
class __$GpsPacketCopyWithImpl<$Res>
    implements _$GpsPacketCopyWith<$Res> {
  __$GpsPacketCopyWithImpl(this._self, this._then);

  final _GpsPacket _self;
  final $Res Function(_GpsPacket) _then;

/// Create a copy of GpsPacket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tp = null,Object? index = freezed,}) {
  return _then(_GpsPacket(
tp: null == tp ? _self.tp : tp // ignore: cast_nullable_to_non_nullable
as TrackPoint,index: freezed == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
