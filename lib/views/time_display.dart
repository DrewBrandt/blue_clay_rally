import 'package:blue_clay_rally/providers/time_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimeDisplay extends ConsumerWidget {
  const TimeDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(50)),
        color: t.colorScheme.secondary.withAlpha(200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 3, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ref.watch(deltaProvider),
              style: t.textTheme.headlineLarge?.copyWith(color: t.colorScheme.onSecondary, fontSize: 40),
              textAlign: TextAlign.center,
            ),
            Tooltip(
              message: 'Elapsed / Remaining',
              child: Text(
                '${ref.watch(elapsedProvider)} / ${ref.watch(remainingProvider)}',
                style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
