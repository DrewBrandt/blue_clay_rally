import 'package:flutter/material.dart';

class LightIconButton extends StatelessWidget {
  const LightIconButton({super.key, required this.tooltip, required this.iconData, required this.onPressed});

  final String tooltip;
  final void Function()? onPressed;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(onPressed: onPressed, tooltip: tooltip, icon: Icon(size: 32, iconData));
  }
}
