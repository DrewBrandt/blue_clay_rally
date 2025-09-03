// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ble_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BleState {

 BleStatus get status; String? get deviceId; String? get message;
/// Create a copy of BleState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BleStateCopyWith<BleState> get copyWith => _$BleStateCopyWithImpl<BleState>(this as BleState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleState&&(identical(other.status, status) || other.status == status)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,status,deviceId,message);

@override
String toString() {
  return 'BleState(status: $status, deviceId: $deviceId, message: $message)';
}


}

/// @nodoc
abstract mixin class $BleStateCopyWith<$Res>  {
  factory $BleStateCopyWith(BleState value, $Res Function(BleState) _then) = _$BleStateCopyWithImpl;
@useResult
$Res call({
 BleStatus status, String? deviceId, String? message
});




}
/// @nodoc
class _$BleStateCopyWithImpl<$Res>
    implements $BleStateCopyWith<$Res> {
  _$BleStateCopyWithImpl(this._self, this._then);

  final BleState _self;
  final $Res Function(BleState) _then;

/// Create a copy of BleState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? deviceId = freezed,Object? message = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BleStatus,deviceId: freezed == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BleState].
extension BleStatePatterns on BleState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BleState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BleState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BleState value)  $default,){
final _that = this;
switch (_that) {
case _BleState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BleState value)?  $default,){
final _that = this;
switch (_that) {
case _BleState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BleStatus status,  String? deviceId,  String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleState() when $default != null:
return $default(_that.status,_that.deviceId,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BleStatus status,  String? deviceId,  String? message)  $default,) {final _that = this;
switch (_that) {
case _BleState():
return $default(_that.status,_that.deviceId,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BleStatus status,  String? deviceId,  String? message)?  $default,) {final _that = this;
switch (_that) {
case _BleState() when $default != null:
return $default(_that.status,_that.deviceId,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _BleState implements BleState {
   _BleState({required this.status, this.deviceId, this.message});
  

@override final  BleStatus status;
@override final  String? deviceId;
@override final  String? message;

/// Create a copy of BleState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BleStateCopyWith<_BleState> get copyWith => __$BleStateCopyWithImpl<_BleState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleState&&(identical(other.status, status) || other.status == status)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,status,deviceId,message);

@override
String toString() {
  return 'BleState(status: $status, deviceId: $deviceId, message: $message)';
}


}

/// @nodoc
abstract mixin class _$BleStateCopyWith<$Res> implements $BleStateCopyWith<$Res> {
  factory _$BleStateCopyWith(_BleState value, $Res Function(_BleState) _then) = __$BleStateCopyWithImpl;
@override @useResult
$Res call({
 BleStatus status, String? deviceId, String? message
});




}
/// @nodoc
class __$BleStateCopyWithImpl<$Res>
    implements _$BleStateCopyWith<$Res> {
  __$BleStateCopyWithImpl(this._self, this._then);

  final _BleState _self;
  final $Res Function(_BleState) _then;

/// Create a copy of BleState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? deviceId = freezed,Object? message = freezed,}) {
  return _then(_BleState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BleStatus,deviceId: freezed == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
