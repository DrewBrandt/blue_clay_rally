import 'package:blue_clay_rally/models/checkpoint.dart';
import 'package:blue_clay_rally/providers/app_state_provider.dart';
import 'package:blue_clay_rally/utils/duration_ext.dart';
import 'package:blue_clay_rally/views/common/icon_button.dart';
import 'package:blue_clay_rally/views/common/section_subtitle.dart';
import 'package:blue_clay_rally/views/common/text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class FinishSummary extends ConsumerWidget {
  const FinishSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cps = ref.watch(checkpointProvider);
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.black.withAlpha(150)),
      width: 500,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text('Summary', style: theme.textTheme.headlineLarge),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: LightIconButton(tooltip: 'Close', iconData: Icons.close_rounded, onPressed: () {
                            ref.read(finishProvider.notifier).state = false;

                  }),
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(color: theme.dividerColor, thickness: 1),
            SizedBox(height: 20),
            Row(
              children: [
                SectionSubTitle('Points'),
                Spacer(),
                LightIconButton(
                  tooltip: 'Export Checkpoint JSON',
                  iconData: MdiIcons.fileExportOutline,
                  onPressed: () {
                ref.read(appNotifierProvider.notifier).exportJson(suggestedName: 'RCR_session');
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  for (int i = 1; i < cps.length; i++) _pointRow(cps[i], Theme.of(context).textTheme),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(width: 60, child: Divider(color: theme.dividerColor, thickness: 2)),
                  ),
                  Stack(
                    children: [
                      Align(alignment: Alignment.centerLeft, child: Text('Total points:', style: Theme.of(context).textTheme.headlineSmall,)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${cps.fold<int>(0, (s, cp) => s + cp.delta.inMinutes.abs())}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Divider(color: theme.dividerColor, thickness: 1),
            SizedBox(height: 20),
            Row(children: [
              DarkTextButton(text: 'Export GPX', tooltip: 'Export the driven track as a GPX file', onPressed: () {
              }),
              Spacer(),
              DarkTextButton(text: 'Export CSV', tooltip: 'Export the driven track as a CSV file', onPressed: () {
                ref.read(appNotifierProvider.notifier).exportCsv(suggestedName: 'RCR_session');
              }),
            ],)
          ],
        ),
      ),
    );
  }
}

Widget _pointRow(Checkpoint cp, TextTheme textTheme) {
  return Stack(
    children: [
      Align(alignment: Alignment.centerLeft, child: Text(DateFormat('HH:mm').format(cp.time))),
      Align(alignment: Alignment.center, child: Text(cp.delta.toFormattedString())),
      Align(
        alignment: Alignment.centerRight,
        child: Text(
          cp.delta.inMinutes.abs().toString(),
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}

final finishProvider = StateProvider<bool>((_) => false);