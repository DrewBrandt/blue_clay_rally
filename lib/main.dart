// ignore_for_file: provider_scope
import 'dart:async';
import 'dart:io';
import 'package:blue_clay_rally/providers/andoid_gps_provider.dart';
import 'package:blue_clay_rally/providers/app_state_provider.dart';
import 'package:blue_clay_rally/providers/ble_provider.dart';
import 'package:blue_clay_rally/providers/screen_info_provider.dart';
import 'package:blue_clay_rally/views/checkpoint_detailed_view.dart';
import 'package:blue_clay_rally/views/finish_sumary.dart';
import 'package:blue_clay_rally/views/map.dart';
import 'package:blue_clay_rally/views/side_bar.dart';
import 'package:blue_clay_rally/views/speed_display.dart';
import 'package:blue_clay_rally/views/time_display.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FullScreen.ensureInitialized();
  runApp(const ProviderScope(child: AppRoot()));
}

class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});
  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> with WidgetsBindingObserver {
  StreamSubscription? _gpsSub;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Defer until after first frame so plugins are attached to an Activity.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartGps();
    });
  }

  Future<void> _maybeStartGps() async {
    if (_started) return;
    _started = true;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        _gpsSub = await androidGps(ref); // your hardened version
      } catch (e, st) {
        // optional: log
      }
    }
  }

  // Optional: pause/resume GPS with app lifecycle to be nice on battery
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeStartGps();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive) {
      _gpsSub?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gpsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MyApp(); // keep MyApp a plain (Consumer)Widget with no side effects
  }
}


class MyApp extends ConsumerWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb && Platform.isAndroid) {
      androidGps(ref);
    }
    return MaterialApp(
      title: 'Side Sheet Demo',
      theme: ThemeData.light(useMaterial3: true), // default light
      darkTheme: ThemeData.dark(useMaterial3: true), // default dark
      themeMode: ThemeMode.dark, // use system setting (light/dark)
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePage();
}

class _HomePage extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin, FullScreenListener {
  late final AnimationController _ctrl;
  late final Animation<Offset> _offset;
  bool _open = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offset = Tween(
      end: const Offset(1, 0),
      begin: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    FullScreen.removeListener(this);
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    !_open ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screen = ref.watch(screenInfoProvider);
    final sheetWidth =
        screen.orientation == Orientation.portrait &&
            screen.sizeClass == SizeClass.compact
        ? screen.size.width
        : 500.0;
    final following = ref.watch(followProvider);
    final double fabSize = switch (ref.watch(screenInfoProvider).sizeClass) {
      SizeClass.compact => 40,
      SizeClass.medium => 60,
      SizeClass.expanded => 80,
    };
    final fabRadius = fabSize / 2.4;

    return SafeArea(
      left: !screen.fullscreen,
      right: !screen.fullscreen,
      top: !screen.fullscreen,
      bottom: !screen.fullscreen,
      child: Scaffold(
        backgroundColor: Colors.white30,
        body: Stack(
          children: [
            MapDisplay(),
            // Time display
            Align(
              alignment: Alignment.topCenter + Alignment(0, .1),
              child: TimeDisplay(),
            ),
            Align(
              alignment: Alignment.bottomCenter + Alignment(0, -.1),
              child: SpeedDisplay(),
            ),
            // Side sheet
            Positioned(
              right: 0,
              top: 0,
              bottom: 0, // <-- pins to full height
              width: sheetWidth,
              child: SlideTransition(
                position: _offset,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: theme.dividerColor)),
                    color: Colors.black.withAlpha(150),
                  ),
                  child: SideBar(theme: theme),
                ),
              ),
            ),

            // Floating action button
            Positioned(
              bottom: 24,
              right: 24,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: _open
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.all(
                      Radius.circular(fabRadius),
                    ),
                  ),
                ),
                onPressed: _toggle,
                tooltip: 'Toggle config panel',
                icon: Icon(
                  size: fabSize,
                  color: _open
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onPrimary,
                  _open
                      ? Icons.keyboard_double_arrow_right_rounded
                      : Icons.keyboard_double_arrow_left_rounded,
                ),
              ),
            ),
            // Floating action button
            Positioned(
              bottom: 24,
              left: 24,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.all(
                      Radius.circular(fabRadius),
                    ),
                  ),
                ),
                onPressed: () =>
                    ref.read(followProvider.notifier).state = !following,
                tooltip: 'Toggle GPS Follow',
                icon: Icon(
                  size: fabSize,
                  color: theme.colorScheme.onPrimary,
                  following
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
                ),
              ),
            ),
            if (ref.watch(finishProvider))
              Align(alignment: Alignment.center, child: FinishSummary()),
            if (!ref.watch(finishProvider) &&
                ref.watch(checkpointEditWindowProvider) != null)
              Align(
                alignment: Alignment.center,
                child: CheckpointEditor(
                  idx: ref.read(checkpointEditWindowProvider)!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DismissIntent extends Intent {
  const DismissIntent();
}
