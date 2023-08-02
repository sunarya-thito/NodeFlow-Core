import 'package:flutter/material.dart';

import '../theme/compact_data.dart';
import 'custom_control.dart';

class ButtonIcon extends StatefulWidget {
  final Widget icon;
  final Function()? onTap;
  final double? iconSize;
  const ButtonIcon({Key? key, required this.icon, this.onTap, this.iconSize}) : super(key: key);

  @override
  State<ButtonIcon> createState() => _ButtonIconState();
}

class _ButtonIconState extends State<ButtonIcon> {
  @override
  Widget build(BuildContext context) {
    return CustomControl(
      builder: (context, state) {
        return Container(
          child: IconTheme(data: IconThemeData(size: widget.iconSize), child: widget.icon),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: state == ControlState.hovered ? CompactData.of(context).theme.hoveredSurfaceColor : null,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
      onTap: widget.onTap,
    );
  }
}
