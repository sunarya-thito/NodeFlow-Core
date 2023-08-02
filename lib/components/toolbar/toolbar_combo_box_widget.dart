import 'package:flutter/material.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/theme/compact_data.dart';

import '../menu/custom_menu_anchor.dart';
import '../tooltip/tooltip_wrapper.dart';

class ToolbarComboBoxEntry<T> {
  final String label;
  final Widget? icon;
  final T value;

  const ToolbarComboBoxEntry({required this.label, this.icon, required this.value});
}

class ToolbarComboBoxWidget<T> extends StatefulWidget {
  final Widget Function(BuildContext context)? header, footer;
  final String placeholder;
  final String? tooltip;
  final String? tooltipDescription;
  final Widget? tooltipIcon;
  final int selectedIndex;
  final List<ToolbarComboBoxEntry<T>> items;
  final void Function(int selectedIndex)? onChangeSelected;
  final CustomMenuController? controller;

  const ToolbarComboBoxWidget({
    Key? key,
    this.header,
    this.footer,
    required this.placeholder,
    this.tooltip,
    this.tooltipDescription,
    this.tooltipIcon,
    this.selectedIndex = -1,
    required this.items,
    this.onChangeSelected,
    this.controller,
  }) : super(key: key);

  @override
  _ToolbarComboBoxWidgetState createState() => _ToolbarComboBoxWidgetState();
}

class _ToolbarComboBoxWidgetState extends State<ToolbarComboBoxWidget> {
  late CustomMenuController _controller;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? CustomMenuController();
  }

  @override
  void didUpdateWidget(covariant ToolbarComboBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller = widget.controller ?? CustomMenuController();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currentValue = widget.selectedIndex;
    Widget container = Focus(
      focusNode: _focusNode,
      child: GestureDetector(
        onTap: () {
          if (_controller.isOpen) {
            _controller.close();
          } else {
            _controller.open();
          }
        },
        onTapDown: (details) {
          _focusNode.requestFocus();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: MenuTheme(
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
              child: CustomMenuAnchor(
                controller: _controller,
                menuChildren: [
                  if (widget.header != null) widget.header!(context),
                  for (var i = 0; i < widget.items.length; i++)
                    CustomMenuItemButton(
                      leadingIcon: widget.items[i].icon,
                      child: widget.items[i].label.asTextWidget(),
                      onPressed: () {
                        widget.onChangeSelected?.call(i);
                      },
                    ),
                  if (widget.footer != null) widget.footer!(context),
                ],
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: app.dividerColor, width: 1)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                      children: currentValue < 0
                          ? [
                              DefaultTextStyle(
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: app.secondaryTextColor,
                                  fontSize: 12,
                                ),
                                child: widget.placeholder.asTextWidget(),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                color: widget.items.isEmpty ? app.secondaryTextColor : app.primaryTextColor,
                                size: 16,
                              ),
                            ]
                          : [
                              if (widget.items[widget.selectedIndex].icon != null)
                                IconTheme(
                                  data: IconThemeData(
                                    size: 14,
                                    color: app.primaryTextColor,
                                  ),
                                  child: Opacity(opacity: widget.onChangeSelected == null ? 0.3 : 1, child: widget.items[widget.selectedIndex].icon!),
                                ),
                              const SizedBox(width: 4),
                              DefaultTextStyle(
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: widget.onChangeSelected == null ? app.secondaryTextColor : app.primaryTextColor,
                                  fontSize: 12,
                                ),
                                child: widget.items[widget.selectedIndex].label.asTextWidget(),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                color: widget.onChangeSelected == null ? app.secondaryTextColor : app.primaryTextColor,
                                size: 12,
                              ),
                            ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.tooltip != null) {
      container = TooltipWrapper(
        tooltip: TooltipWrapper.actionTooltip(widget.tooltip!, widget.tooltipDescription, widget.tooltipIcon, null),
        child: container,
      );
    }
    return container;
  }
}
