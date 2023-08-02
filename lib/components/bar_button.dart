import 'package:flutter/material.dart';
import 'package:nodeflow/theme/compact_data.dart';

import 'custom_control.dart';

class BarButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  const BarButton({Key? key, required this.child, this.onTap, this.selected = false}) : super(key: key);

  @override
  _BarButtonState createState() => _BarButtonState();
}

class _BarButtonState extends State<BarButton> {
  @override
  Widget build(BuildContext context) {
    return CustomControl(
      onTap: widget.onTap,
      builder: (context, state) {
        return Opacity(
          opacity: state == ControlState.disabled ? 0.3 : 1.0,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: widget.selected
                ? app.backgroundColor
                : state == ControlState.hovered || state == ControlState.focused
                    ? app.hoveredSurfaceColor
                    : null,
            child: DefaultTextStyle(
              style: TextStyle(color: app.primaryTextColor, fontSize: 12, fontFamily: 'Inter'),
              child: IconTheme(
                data: IconThemeData(color: app.primaryTextColor, size: 16),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
