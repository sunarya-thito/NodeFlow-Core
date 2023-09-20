import 'package:flutter/material.dart';
import 'package:nodeflow/theme/compact_data.dart';

class NavigationButton extends StatefulWidget {
  final Widget icon;
  final Widget label;
  final Widget? badge;
  final void Function() onTap;
  final bool selected;
  const NavigationButton({
    Key? key,
    required this.icon,
    required this.label,
    this.badge,
    this.selected = false,
    required this.onTap,
  }) : super(key: key);

  @override
  NavigationButtonState createState() => NavigationButtonState();
}

class NavigationButtonState extends State<NavigationButton> {
  bool hovered = false;
  bool focused = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (event) {
          setState(() {
            hovered = event;
          });
        },
        onShowFocusHighlight: (event) {
          setState(() {
            focused = event;
          });
        },
        actions: {
          ActivateIntent: CallbackAction(onInvoke: (event) {
            widget.onTap();
            return null;
          }),
        },
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: widget.selected ? app.selectedColor : null,
              // color: Colors.red,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                  color: focused
                      ? app.focusedSurfaceColor
                      : hovered && !widget.selected
                          ? app.secondaryTextColor
                          : Colors.transparent,
                  width: focused ? 2 : 1,
                  strokeAlign: BorderSide.strokeAlignOutside),
            ),
            child: Row(
              children: [
                IconTheme(data: IconThemeData(size: 16, color: widget.selected ? app.selectedTextColor : app.primaryTextColor), child: widget.icon),
                SizedBox(
                  width: 18,
                ),
                Expanded(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: widget.selected ? app.selectedTextColor : app.primaryTextColor,
                    ),
                    child: widget.label,
                  ),
                ),
                if (widget.badge != null) widget.badge!,
              ],
            )),
      ),
    );
  }
}
