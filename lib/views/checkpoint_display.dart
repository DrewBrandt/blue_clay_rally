import 'package:blue_clay_rally/models/checkpoint.dart';
import 'package:blue_clay_rally/providers/app_state_provider.dart';
import 'package:blue_clay_rally/utils/duration_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CheckpointDisplay extends ConsumerWidget {
  final int i;
  final Checkpoint c;
  const CheckpointDisplay({super.key, required this.i, required this.c});

  @override
  Widget build(BuildContext context, ref) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Colors.black.withAlpha(100),
        ),
        child: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Align(alignment: Alignment.centerLeft, child: Text(i == 0 ? 'Start' : 'Checkpoint $i')),
                  Align(child: Text(DateFormat('HH:mm').format(c.time))),
                  Align(alignment: Alignment.centerRight, child: Text(c.delta.toFormattedString())),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 10, top: 3, bottom: 3),
              child: IconButton.filledTonal(
                onPressed: () => ref.read(checkpointEditWindowProvider.notifier).state = i,
                icon: Icon(Icons.edit_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
