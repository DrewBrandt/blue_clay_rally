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
        color: (ref.watch(deltaProvider).startsWith('-') ? const Color.fromARGB(255, 55, 102, 3) : const Color.fromARGB(255, 147, 40, 32)).withAlpha(250),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 25, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ref.watch(deltaProvider),
              style: t.textTheme.headlineLarge?.copyWith(color: Colors.white.withAlpha(230), fontSize: 40, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Tooltip(
              message: 'Elapsed / Remaining',
              child: Text(
                '${ref.watch(elapsedProvider)} / ${ref.watch(remainingProvider)}',
                style: t.textTheme.bodyLarge?.copyWith(color: Colors.white.withAlpha(230), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
