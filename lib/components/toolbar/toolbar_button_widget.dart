import 'package:flutter/material.dart';
import 'package:nodeflow/theme/compact_data.dart';

import '../../hotkey.dart';
import '../custom_control.dart';
import '../tooltip/tooltip_wrapper.dart';

class ToolbarButtonWidget extends StatefulWidget {
  final String label;
  final String? description;
  final void Function()? onPressed;
  final Widget icon;
  final ShortcutKey? shortcut;
  final bool showIconOnTooltip;

  const ToolbarButtonWidget(
      {Key? key, required this.label, this.description, required this.onPressed, required this.icon, this.shortcut, this.showIconOnTooltip = true})
      : super(key: key);

  @override
  _ToolbarButtonWidgetState createState() => _ToolbarButtonWidgetState();
}

class _ToolbarButtonWidgetState extends State<ToolbarButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return TooltipWrapper(
      tooltip: TooltipWrapper.actionTooltip(widget.label, widget.description, widget.showIconOnTooltip ? widget.icon : null, widget.shortcut),
      child: CustomControl(
        onTap: widget.onPressed,
        builder: (context, state) {
          return Container(
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
          );
        },
      ),
    );
  }
}
