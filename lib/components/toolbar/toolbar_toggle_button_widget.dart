import 'package:flutter/material.dart';
import 'package:nodeflow/hotkey.dart';
import 'package:nodeflow/theme/compact_data.dart';

import '../custom_control.dart';
import '../tooltip/tooltip_wrapper.dart';

class ToolbarToggleButtonWidget extends StatefulWidget {
  final String label;
  final String? description;
  final void Function()? onPressed;
  final Widget icon;
  final ShortcutKey? shortcut;
  final bool selected;

  const ToolbarToggleButtonWidget(
      {Key? key, required this.label, this.description, required this.onPressed, required this.icon, this.shortcut, this.selected = false})
      : super(key: key);

  @override
  _ToolbarToggleButtonWidgetState createState() => _ToolbarToggleButtonWidgetState();
}

class _ToolbarToggleButtonWidgetState extends State<ToolbarToggleButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return TooltipWrapper(
      tooltip: TooltipWrapper.actionTooltip(widget.label, widget.description, widget.icon, widget.shortcut),
      child: CustomControl(
        onTap: widget.onPressed,
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
              color: widget.selected ? app.focusedSurfaceColor : null,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: state == ControlState.down
                    ? app.buttonDown
                    : state == ControlState.hovered
                        ? app.buttonHovered
                        : null,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Opacity(
                opacity: state == ControlState.disabled ? 0.3 : 1,
                child: IconTheme(data: IconThemeData(size: 16, color: app.primaryTextColor), child: widget.icon),
              ),
            ),
          );
        },
      ),
    );
  }
}
