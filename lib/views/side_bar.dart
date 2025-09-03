import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blue_clay_rally/models/gps_packet.dart';
import 'package:blue_clay_rally/providers/ble_provider.dart';
import 'package:blue_clay_rally/providers/fake_gps_provider.dart';
import 'package:blue_clay_rally/providers/gps_packet_provider.dart';
import 'package:blue_clay_rally/providers/screen_info_provider.dart';
import 'package:blue_clay_rally/views/ble_device_display.dart';
import 'package:blue_clay_rally/views/checkpoint_display.dart';
import 'package:blue_clay_rally/providers/app_state_provider.dart';
import 'package:blue_clay_rally/views/common/icon_button.dart';
import 'package:blue_clay_rally/views/common/section_subtitle.dart';
import 'package:blue_clay_rally/views/common/section_title.dart';
import 'package:blue_clay_rally/views/common/text_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SideBar extends ConsumerWidget {
  const SideBar({super.key, required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final si = ref.watch(appNotifierProvider);
    final screen = ref.watch(screenInfoProvider);
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        child: Column(
          children: [
            Stack(
              children: [
                Align(
                  alignment: screen.sizeClass == SizeClass.compact
                      ? Alignment.centerLeft
                      : Alignment.center,
                  child: SectionTitle('Configuration'),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: LightIconButton(
                    tooltip: 'Toggle Fullscreen',
                    iconData: !screen.fullscreen
                        ? Icons.open_in_full_rounded
                        : Icons.close_fullscreen_rounded,
                    onPressed: () async {
                      await ref
                          .read(screenInfoProvider.notifier)
                          .setFullScreen(!screen.fullscreen);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Slider(
              max: ref.watch(fakeGpsProvider)?.points.length.toDouble() ?? 1.0,
              min: 1.0,
              value: (ref.watch(fakeGpsIndexProvider) ?? 0 + 1).toDouble(),
              onChanged: (val) {
                final tp = ref.watch(fakeGpsProvider)?.points[val.toInt() - 1];
                ref
                    .read(gpsPacketProvider.notifier)
                    .update(tp == null ? null : GpsPacket(tp: tp, index: null));
                ref.watch(fakeGpsIndexProvider.notifier).state = val.toInt();
              },
            ),
            SizedBox(height: 20),
            Divider(color: theme.dividerColor, thickness: 1),

            SizedBox(height: 20),
            if (ref.watch(screenInfoProvider).orientation ==
                Orientation.landscape)
              Row(
                children: [
                  Text('Current File:'),
                  Spacer(),
                  Text(ref.watch(appNotifierProvider)?.trackFileName ?? 'None'),
                ],
              )
            else
              Column(
                children: [
                  Text('Current File:'),
                  Text(ref.watch(appNotifierProvider)?.trackFileName ?? 'None'),
                ],
              ),
            SizedBox(height: 20),
            Row(
              children: [
                Visibility(
                  visible: ref.watch(hasPreviousSessionProvider),
                  child: DarkTextButton(
                    text:
                        screen.orientation == Orientation.portrait &&
                            screen.sizeClass == SizeClass.compact
                        ? 'Restore'
                        : 'Restore Data',
                    tooltip: 'Restore Data from a previously started track',
                    onPressed: () => {
                      ref.read(appNotifierProvider.notifier).loadPrevious(),
                    },
                  ),
                ),
                Spacer(),
                DarkTextButton(
                  tooltip: 'Load a new file or reload the current one',
                  onPressed: () async {
                    final session = ref.watch(appNotifierProvider);
                    if (session != null &&
                        session.started &&
                        !session.finished) {
                      var result = await showAlertDialog(
                        context,
                        'Are you sure you want to load a new file?\nThis will cause to lose all of your current data',
                      );
                      if (!result) return;
                    }
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles();
                    if (!context.mounted) return;
                    if (result != null) {
                      PlatformFile file = result.files.first;
                      Uint8List bytes;
                      if (!kIsWeb && file.bytes == null) {
                        bytes = await File(file.path!).readAsBytes();
                      } else if (file.bytes != null) {
                        bytes = file.bytes!;
                      } else {
                        final bb = BytesBuilder();
                        await for (final chunk in file.readStream!) {
                          bb.add(chunk);
                        }
                        bytes = bb.takeBytes();
                      }

                      ref
                          .read(appNotifierProvider.notifier)
                          .loadNewFile(
                            utf8.decode(bytes),
                            file.name,
                            file.extension!,
                          );
                    }
                  },
                  text:
                      screen.orientation == Orientation.portrait &&
                          screen.sizeClass == SizeClass.compact
                      ? 'New'
                      : 'Load New',
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(color: theme.dividerColor, thickness: 1),
            SizedBox(height: 20),
            // ----
            Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SectionSubTitle('Checkpoints'),
                ),
                if (si != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (si.started)
                          LightIconButton(
                            tooltip: 'Finish Track',
                            onPressed: () {},
                            iconData: MdiIcons.flagCheckered,
                          ),
                        SizedBox(width: 10),
                        if (!si.finished)
                          LightIconButton(
                            tooltip: !si.started
                                ? 'Start track'
                                : 'Add Checkpoint',
                            onPressed: () {
                              ref
                                  .watch(appNotifierProvider.notifier)
                                  .setCheckpoint();
                            },
                            iconData: si.started
                                ? Icons.timer_outlined
                                : Icons.play_arrow_rounded,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 350,
              child: ListView.builder(
                itemCount: ref.watch(appNotifierProvider)?.cps.length ?? 0,
                itemBuilder: (context, i) {
                  return CheckpointDisplay(
                    i: i,
                    c: ref.watch(appNotifierProvider)!.cps[i],
                  );
                },
              ),
            ),
            // -------
            SizedBox(height: 20),
            Divider(color: theme.dividerColor, thickness: 1),
            SizedBox(height: 20),
            Stack(
              children: [
                SectionSubTitle('Bluetooth'),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton.filled(
                    tooltip: 'Scan for devices',
                    onPressed: () {
                      ref.read(bleProvider.notifier).startScan();
                    },
                    icon: Icon(Icons.refresh_rounded, size: 32),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: ListView.builder(
                itemCount: ref.watch(deviceProvider).length,
                itemBuilder: (context, i) {
                  return BleDeviceDisplay(
                    i: i,
                    b: ref.watch(deviceProvider).elementAt(i),
                  );
                },
              ),
            ),
            // -------
            SizedBox(height: 20),
            Divider(color: theme.dividerColor, thickness: 1),
            SizedBox(height: 20),
            DarkTextButton(
              tooltip: 'Reset Progress to the currently closest track point',
              onPressed: () {
                ref.read(gpsPacketProvider.notifier).fixProgress();
              },
              text: 'Fix Progress',
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showAlertDialog(BuildContext context, String message) async {
  // set up the buttons
  Widget cancelButton = ElevatedButton(
    child: Text("Cancel"),
    onPressed: () {
      // returnValue = false;
      Navigator.of(context).pop(false);
    },
  );
  Widget continueButton = ElevatedButton(
    child: Text("Continue"),
    onPressed: () {
      // returnValue = true;
      Navigator.of(context).pop(true);
    },
  ); // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Do you want to continue?"),
    content: Text(message),
    actions: [cancelButton, continueButton],
  ); // show the dialog
  final result = await showDialog<bool?>(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
  return result ?? false;
}
