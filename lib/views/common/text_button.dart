import 'package:blue_clay_rally/providers/screen_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DarkTextButton extends ConsumerWidget {
  const DarkTextButton({super.key, required this.text, required this.tooltip, required this.onPressed});

  final String tooltip, text;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(screenInfoProvider);
    final p = EdgeInsets.symmetric(
      horizontal: screen.sizeClass == SizeClass.compact ? 15 : 30,
      vertical: screen.sizeClass == SizeClass.compact ? 10 : 20,
    );
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          padding: p,
        ),
        child: Text(text, style: theme.textTheme.bodyLarge),
      ),
    );
  }
}
