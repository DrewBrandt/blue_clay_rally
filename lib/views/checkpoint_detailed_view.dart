import 'package:blue_clay_rally/providers/app_state_provider.dart';
import 'package:blue_clay_rally/views/common/date_time_editor.dart';
import 'package:blue_clay_rally/views/common/icon_button.dart';
import 'package:blue_clay_rally/views/common/section_subtitle.dart';
import 'package:blue_clay_rally/views/common/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckpointEditor extends ConsumerWidget {
  const CheckpointEditor({super.key, required this.idx});

  final int idx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cp = ref.watch(checkpointSingleProvider(idx));
    final theme = Theme.of(context);
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
                Align(alignment: Alignment.center, child: SectionTitle('Edit Checkpoint')),
                Align(
                  alignment: Alignment.centerRight,
                  child: LightIconButton(tooltip: 'Close', iconData: Icons.close_rounded, onPressed: () {}),
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(color: theme.dividerColor, thickness: 1),
            SizedBox(height: 20),
            Align(alignment: Alignment.centerLeft, child: SectionSubTitle('Date/Time')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: DateTimeEditor(
                value: cp?.time ?? DateTime.now(),
                useYear: false,
                onChanged: (d) async {
                  await ref.read(appNotifierProvider.notifier).updateCheckpoint(cp!, cp.copyWith(time: d ?? cp.time));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
