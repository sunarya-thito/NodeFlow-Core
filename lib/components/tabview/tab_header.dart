import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nodeflow/components/tabview/tab_view.dart';
import 'package:nodeflow/components/tabview/tab_view_theme.dart';
import 'package:nodeflow/theme/compact_data.dart';
import 'package:nodeflow/ui_util.dart';

import '../custom_control.dart';

class TabHeaderData extends InheritedWidget {
  final int index;
  final TabEntry entry;
  final bool focused, viewFocused, pinned;
  final VoidCallback onTabClose, onTabFocused;
  final void Function(TabEntry source, int target) onTabSwap;

  const TabHeaderData({
    Key? key,
    required this.index,
    required this.entry,
    required this.focused,
    required this.pinned,
    required this.viewFocused,
    required Widget child,
    required this.onTabClose,
    required this.onTabFocused,
    required this.onTabSwap,
  }) : super(key: key, child: child);

  static TabHeaderData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabHeaderData>()!;
  }

  @override
  bool updateShouldNotify(TabHeaderData oldWidget) {
    return focused != oldWidget.focused || viewFocused != oldWidget.viewFocused;
  }
}

class TabHeader extends StatefulWidget {
  final Widget? icon;
  final Widget label;
  final bool closeable;

  const TabHeader({Key? key, this.icon, required this.label, this.closeable = true}) : super(key: key);

  @override
  _TabHeaderState createState() => _TabHeaderState();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'TabHeader{icon: $icon, label: $label, closeable: $closeable}';
  }
}

class TabEntryWrapper {
  final int index;
  final TabEntry entry;
  final double width;
  // final TabViewLocation? location;

  TabEntryWrapper(this.index, this.entry, this.width);
}

class _TabHeaderState extends State<TabHeader> {
  bool _hovered = false;
  bool _dragTargetStart = false;
  @override
  Widget build(BuildContext context) {
    var headerData = TabHeaderData.of(context);
    var isFocused = headerData.focused;
    var isViewFocused = headerData.viewFocused;
    var isPinned = headerData.pinned;
    var theme = TabHeaderTheme.of(context).tabHeaderStyle;
    return Draggable<TabEntryWrapper>(
      data: TabEntryWrapper(headerData.index, headerData.entry, max(64, context.localSize.width)),
      childWhenDragging: const SizedBox(),
      hitTestBehavior: HitTestBehavior.translucent,
      feedback: Container(
        color: theme.backgroundColor?.resolve({MaterialState.hovered}),
        height: max(12, context.localSize.height),
        child: buildContainer(isPinned, context),
      ),
      onDragStarted: () {
        headerData.onTabFocused();
      },
      child: DragTarget<TabEntryWrapper>(
        hitTestBehavior: HitTestBehavior.translucent,
        onMove: (details) {
          setState(() {
            _hovered = false;
          });
        },
        onAccept: (data) {
          setState(() {
            // headerData.onTabSwap(
            //     data.entry, data.index < headerData.index && TabViewGroupData.of(context)?.location == data.location ? headerData.index - 1 : headerData.index);
            _dragTargetStart = false;
            _hovered = false;
          });
        },
        onWillAccept: (data) {
          if (data?.entry != headerData.entry) {
            setState(() {
              _dragTargetStart = true;
            });
            return true;
          }
          return false;
        },
        onLeave: (data) {
          setState(() {
            _dragTargetStart = false;
            _hovered = false;
          });
        },
        builder: (context, candidateData, rejectedData) {
          return buildDragTarget(headerData, context, theme, isFocused, isViewFocused, isPinned, candidateData);
        },
      ),
    );
  }

  Widget buildDragTarget(TabHeaderData headerData, BuildContext context, TabHeaderStyle theme, bool isFocused, bool isViewFocused, bool isPinned,
      List<TabEntryWrapper?> candidateData) {
    var mouseRegion = MouseRegion(
      onEnter: (event) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (event) {
        setState(() {
          _hovered = false;
        });
      },
      child: GestureDetector(
        onTap: () {
          headerData.onTabFocused();
          Scrollable.ensureVisible(context, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart);
          Scrollable.ensureVisible(context, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.backgroundColor?.resolve(_dragTargetStart
                      ? {}
                      : {
                          if (isFocused) MaterialState.selected,
                          if (isViewFocused) MaterialState.focused,
                          if (_hovered) MaterialState.hovered,
                        }),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.outlineColor?.resolve(_dragTargetStart
                              ? {}
                              : {
                                  if (isViewFocused && !_dragTargetStart) MaterialState.focused,
                                  if (isFocused && !_dragTargetStart) MaterialState.selected,
                                  if (_hovered && !_dragTargetStart) MaterialState.hovered,
                                }) ??
                          Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
            buildContainer(isPinned, context),
          ],
        ),
      ),
    );
    if (candidateData.isEmpty) {
      return mouseRegion;
    }
    double candidateWidth = 0;
    for (var data in candidateData) {
      if (data == null) continue;
      candidateWidth += data.width;
    }
    return IgnorePointer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildPlaceholder(context, candidateWidth, theme),
          mouseRegion,
        ],
      ),
    );
  }

  Container buildPlaceholder(BuildContext context, double width, TabHeaderStyle style) {
    return Container(
      width: width,
      color: style.placeholderColor?.resolve({}),
    );
  }

  Container buildContainer(bool isPinned, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (widget.icon != null) IconTheme(data: IconThemeData(size: 14, color: app.primaryTextColor), child: widget.icon!),
          if (widget.icon != null) const SizedBox(width: 8),
          DefaultTextStyle(
            style: TextStyle(
              fontFamily: 'Inter',
              color: app.primaryTextColor,
              fontSize: 12,
            ),
            child: widget.label,
          ),
          if (widget.closeable || isPinned) const SizedBox(width: 8),
          if (isPinned) Icon(Icons.push_pin, size: 12, color: app.secondaryTextColor),
          if (widget.closeable && !isPinned)
            CustomControl(
              builder: (context, state) {
                if (state == ControlState.hovered) {
                  return Icon(
                    Icons.close,
                    size: 14,
                    color: app.primaryTextColor,
                  );
                }
                return Icon(
                  Icons.close,
                  size: 14,
                  color: app.secondaryTextColor,
                );
              },
              onTap: () {
                TabHeaderData.of(context).onTabClose();
              },
            ),
        ],
      ),
    );
  }
}
