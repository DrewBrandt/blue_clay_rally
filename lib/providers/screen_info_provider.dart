import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui' as ui;

enum SizeClass {
  compact,
  medium,
  expanded;

  bool operator >(SizeClass other) => index > other.index;
  bool operator <(SizeClass other) => index < other.index;
  bool operator >=(SizeClass other) => index >= other.index;
  bool operator <=(SizeClass other) => index <= other.index;
}

@immutable
class ScreenInfo {
  final Size size; // logical pixels
  final Orientation orientation;
  final SizeClass sizeClass;
  final bool fullscreen;
  const ScreenInfo(this.size, this.orientation, this.sizeClass, this.fullscreen);

  static SizeClass classify(double w, double h) {
    final d = w > h ? h : w;
    if (d < 600) return SizeClass.compact;
    if (d < 1200) return SizeClass.medium;
    return SizeClass.expanded;
  }

  ScreenInfo copyWith({Size? size, Orientation? orientation, bool? fullscreen}) {
    final s = size ?? this.size;
    final o = orientation ?? this.orientation;
    final f = fullscreen ?? this.fullscreen;
    return ScreenInfo(s, o, ScreenInfo.classify(s.width, s.height), f);
  }

  @override
  bool operator ==(Object other) =>
      other is ScreenInfo &&
      other.size == size &&
      other.orientation == orientation &&
      other.sizeClass == sizeClass &&
      other.fullscreen == fullscreen;

  @override
  int get hashCode => Object.hash(size, orientation, sizeClass);
}

class ScreenInfoController extends Notifier<ScreenInfo> with WidgetsBindingObserver, FullScreenListener {
  @override
  ScreenInfo build() {
    FullScreen.addListener(this);
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(dispose);

    final view = ui.PlatformDispatcher.instance.views.first;
    final logical = view.physicalSize / view.devicePixelRatio;
    // Orientation heuristic without context:
    final orientation = logical.width >= logical.height ? Orientation.landscape : Orientation.portrait;

    return ScreenInfo(
      Size(logical.width, logical.height),
      orientation,
      ScreenInfo.classify(logical.width, logical.height),
      FullScreen.isFullScreen,
    );
  }

  @override
  void didChangeMetrics() {
    final view = ui.PlatformDispatcher.instance.views.first;
    final logical = view.physicalSize / view.devicePixelRatio;
    final orientation = logical.width >= logical.height ? Orientation.landscape : Orientation.portrait;

    final next = ScreenInfo(
      Size(logical.width, logical.height),
      orientation,
      ScreenInfo.classify(logical.width, logical.height),
      state.fullscreen,
    );
    if (next != state) {
      state = next; // Only notifies listeners if something *actually* changed
    }
  }

  @override
  void onFullScreenChanged(bool enabled, SystemUiMode? systemUiMode) {
    state = state.copyWith(fullscreen: enabled);
  }

  Future<void> setFullScreen(bool enable) async {
    final wm = FullScreen.supportWindowManager ? WindowManager.instance : null;
    bool? state;
    if (wm != null) {
      state = await wm.isFullScreen();
    }
    FullScreen.setFullScreen(enable);
    if (wm != null) {
      final newState = await wm.isFullScreen();
      if(state != newState){
        onFullScreenChanged(newState, null);
      }
    }
  }

  void dispose() {
    FullScreen.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
  }
}

final screenInfoProvider = NotifierProvider<ScreenInfoController, ScreenInfo>(() => ScreenInfoController());
