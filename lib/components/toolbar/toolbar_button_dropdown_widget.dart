import 'package:flutter/material.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/theme/compact_data.dart';

import '../custom_control.dart';
import '../menu/custom_menu_anchor.dart';
import '../tooltip/tooltip_wrapper.dart';

class ToolbarButtonDropdownEntry {
  final String label;
  final Widget? icon;
  final void Function() onPressed;

  const ToolbarButtonDropdownEntry({required this.label, this.icon, required this.onPressed});
}

class ToolbarButtonDropdownWidget extends StatefulWidget {
  final Widget icon;
  final String? tooltip;
  final String? tooltipDescription;
  final Widget? tooltipIcon;
  final Widget Function(BuildContext context)? header, footer;
  final List<ToolbarButtonDropdownEntry> items;

  const ToolbarButtonDropdownWidget({
    Key? key,
    required this.icon,
    this.tooltip,
    this.tooltipDescription,
    this.tooltipIcon,
    this.header,
    this.footer,
    required this.items,
  }) : super(key: key);

  @override
  _ToolbarButtonDropdownWidgetState createState() => _ToolbarButtonDropdownWidgetState();
}

class _ToolbarButtonDropdownWidgetState extends State<ToolbarButtonDropdownWidget> {
  // final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    Widget customControl = CustomMenuAnchor(
      menuChildren: [
        if (widget.header != null) widget.header!(context),
        for (var i = 0; i < widget.items.length; i++)
          CustomMenuItemButton(
            leadingIcon: widget.items[i].icon,
            onPressed: widget.items[i].onPressed,
            child: widget.items[i].label.asTextWidget(),
          ),
        if (widget.footer != null) widget.footer!(context),
      ],
      child: CustomControl(
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
            child: IconTheme(data: IconThemeData(size: 16, color: app.primaryTextColor), child: widget.icon),
          );
        },
      ),
    );
    customControl = MenuTheme(
      data: MenuThemeData(
        style: MenuTheme.of(context).style!.copyWith(
              padding: MaterialStatePropertyAll(
                EdgeInsets.symmetric(vertical: 8),
              ),
            ),
      ),
      child: MenuButtonTheme(
        data: MenuButtonThemeData(
          style: MenuButtonTheme.of(context).style!.copyWith(
                padding: MaterialStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
        ),
        child: customControl,
      ),
    );
    if (widget.tooltip == null) return customControl;
    return TooltipWrapper(
      tooltip: TooltipWrapper.actionTooltip(widget.tooltip!, widget.tooltipDescription, widget.icon, null),
      child: customControl,
    );
  }
}
