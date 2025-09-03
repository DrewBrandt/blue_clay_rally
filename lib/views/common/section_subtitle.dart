import 'package:flutter/material.dart';

class SectionSubTitle extends StatelessWidget {
  final String text;

  const SectionSubTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Text(text, style: t.textTheme.headlineSmall);
  }
}
