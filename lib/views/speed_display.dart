import 'package:blue_clay_rally/providers/app_state_provider.dart';
import 'package:blue_clay_rally/providers/time_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpeedDisplay extends ConsumerWidget {
  const SpeedDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(50)),
        color: t.cardColor.withAlpha(150)
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 25, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Target Speed:',
              style: t.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withAlpha(230),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${((ref.watch(currentTrackProvider)?.points[ref.watch(trackIndexProvider) ?? 0].speed ?? 0) * 2.23694).round()} mph',
              style: t.textTheme.headlineLarge?.copyWith(
                color: Colors.white.withAlpha(230),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
