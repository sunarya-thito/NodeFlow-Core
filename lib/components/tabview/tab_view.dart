import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nodeflow/components/tabview/tab_header.dart';
import 'package:nodeflow/components/tabview/tab_view_theme.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../theme/compact_data.dart';
import '../menu/custom_menu_anchor.dart';
import '../toolbar/toolbar_button_widget.dart';

class TabEntry {
  final String label;
  final TabHeader tabHeader;
  final Widget Function(BuildContext context) tabContentBuilder;
  final bool pinned;
  final VoidCallback? onTabClose, onTabFocused, onTabUnfocused;

  const TabEntry({
    required this.label,
    required this.tabHeader,
    required this.tabContentBuilder,
    this.pinned = false,
    this.onTabClose,
    this.onTabFocused,
    this.onTabUnfocused,
  });
}

class TabView extends StatefulWidget {
  static Widget defaultEmptyViewBuilder(BuildContext context) {
    return Container(
      color: CompactData.of(context).theme.backgroundColor,
    );
  }

  final Widget? leading, trailing;
  final List<TabEntry> tabs;
  final int focusedTabIndex;
  final Widget Function(BuildContext context) emptyViewBuilder;
  final void Function(TabEntry source, int target)? onTabSwap;
  final void Function(int index)? onTabFocused;
  final void Function(int index)? onTabClosed;
  final FocusScopeNode? focusNode;

  const TabView({
    Key? key,
    this.focusNode,
    required this.tabs,
    required this.focusedTabIndex,
    this.emptyViewBuilder = defaultEmptyViewBuilder,
    this.onTabSwap,
    this.leading,
    this.trailing,
    this.onTabFocused,
    this.onTabClosed,
  }) : super(key: key);

  @override
  _TabViewState createState() => _TabViewState();
}

class _IndexedEntry {
  final _TabViewState state;
  final int index;
  final TabEntry entry;
  VoidCallback? triggerRecalculatePosition;
  bool visible = false;
  final Key key;
  Size size = Size.zero;

  _IndexedEntry(this.state, this.index, this.entry) : key = ValueKey(index);
}

class _TabViewState extends State<TabView> {
  late FocusScopeNode _focusNode;

  final ScrollController _scrollController = ScrollController();

  final CustomMenuController _menuController = CustomMenuController();

  final List<_IndexedEntry> indexedEntries = [];

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusScopeNode();
    rebuildIndexedEntries();
  }

  @override
  void didUpdateWidget(covariant TabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs != widget.tabs) {
      rebuildIndexedEntries();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void rebuildIndexedEntries() {
    indexedEntries.clear();
    for (var i = 0; i < widget.tabs.length; i++) {
      indexedEntries.add(_IndexedEntry(this, i, widget.tabs[i]));
    }
    indexedEntries.sort((a, b) {
      if (a.entry.pinned && !b.entry.pinned) {
        return -1;
      } else if (!a.entry.pinned && b.entry.pinned) {
        return 1;
      } else {
        return a.index.compareTo(b.index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) {
      return widget.emptyViewBuilder(context);
    }
    var safeIndex = widget.focusedTabIndex.clamp(0, widget.tabs.length - 1);
    var theme = TabViewTheme.of(context).tabViewStyle;
    return FocusScope(
      node: _focusNode,
      onFocusChange: (hasFocus) {
        setState(() {});
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.tabs.isNotEmpty)
            Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.headerBackgroundColor?.resolve({
                        if (_focusNode.hasFocus) MaterialState.focused,
                      }),
                      border: Border(
                        bottom: BorderSide(color: app.dividerColor, width: 1),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: theme.headerHeight.resolve({}),
                  child: GestureDetector(
                    onTap: () {
                      _focusNode.requestFocus();
                    },
                    child: DragTarget<TabEntryWrapper>(
                      onAccept: (data) {
                        widget.onTabSwap?.call(data.entry, widget.tabs.length);
                      },
                      builder: (context, candidateData, rejectedData) {
                        double candidateWidth = 0;
                        for (var data in candidateData) {
                          if (data != null) {
                            candidateWidth += data.width;
                          }
                        }
                        return Row(
                          children: [
                            if (widget.leading != null) const SizedBox(width: 8),
                            if (widget.leading != null) widget.leading!,
                            if (widget.leading != null) const SizedBox(width: 8),
                            Expanded(
                              child: Listener(
                                onPointerSignal: (event) {
                                  if (event is PointerScrollEvent) {
                                    _scrollController
                                        .jumpTo((_scrollController.offset + event.scrollDelta.dy).clamp(0.0, _scrollController.position.maxScrollExtent));
                                  }
                                },
                                child: ScrollConfiguration(
                                  behavior:
                                      const ScrollBehavior().copyWith(overscroll: false, physics: const NeverScrollableScrollPhysics(), scrollbars: false),
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: candidateWidth > 0 ? widget.tabs.length + 1 : widget.tabs.length,
                                    itemBuilder: (context, index) {
                                      if (index >= indexedEntries.length) {
                                        if (candidateWidth > 0) {
                                          return Container(
                                            width: candidateWidth,
                                            height: theme.headerHeight.resolve({}),
                                            color: TabHeaderTheme.of(context).tabHeaderStyle.placeholderColor?.resolve({}),
                                          );
                                        }
                                        return const SizedBox();
                                      }
                                      var entry = indexedEntries[index];
                                      return VisibilityDetector(
                                        key: entry.key,
                                        onVisibilityChanged: (info) {
                                          if (info.visibleFraction == 1) {
                                            entry.visible = true;
                                          } else {
                                            entry.visible = false;
                                          }
                                        },
                                        child: TabHeaderData(
                                          index: entry.index,
                                          entry: entry.entry,
                                          viewFocused: _focusNode.hasFocus,
                                          pinned: entry.entry.pinned,
                                          focused: entry.index == safeIndex,
                                          child: entry.entry.tabHeader,
                                          onTabClose: () {
                                            entry.entry.onTabClose?.call();
                                            widget.onTabClosed?.call(entry.index);
                                          },
                                          onTabFocused: () {
                                            _focusNode.requestFocus();
                                            if (widget.focusedTabIndex >= 0 && widget.focusedTabIndex < widget.tabs.length) {
                                              entry.entry.onTabUnfocused?.call();
                                            }
                                            widget.onTabFocused?.call(entry.index);
                                            entry.entry.onTabFocused?.call();
                                          },
                                          onTabSwap: (source, target) {
                                            widget.onTabSwap?.call(source, target);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            if ((_scrollController.hasClients &&
                                    _scrollController.positions.any((element) => element.hasContentDimensions && element.maxScrollExtent > 0)) ||
                                widget.trailing != null)
                              const SizedBox(width: 16),
                            if (_scrollController.hasClients &&
                                _scrollController.positions.any((element) => element.hasContentDimensions && element.maxScrollExtent > 0))
                              CustomMenuAnchor(
                                controller: _menuController,
                                menuChildren: [
                                  for (var entry in indexedEntries)
                                    if (!entry.visible)
                                      CustomMenuItemButton(
                                        child: Text(entry.entry.label),
                                        onPressed: () {
                                          entry.entry.onTabFocused?.call();
                                        },
                                      ),
                                ],
                                child: ToolbarButtonWidget(
                                  showIconOnTooltip: false,
                                  label: i18n.tabsShowHidden, // TODO localize
                                  onPressed: () {
                                    _menuController.open();
                                  },
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                ),
                              ),
                            if (widget.trailing != null) const SizedBox(width: 2),
                            if (widget.trailing != null) widget.trailing!,
                            if ((_scrollController.hasClients &&
                                    _scrollController.positions.any((element) => element.hasContentDimensions && element.maxScrollExtent > 0)) ||
                                widget.trailing != null)
                              const SizedBox(width: 4),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          Expanded(
              child: ClipRect(
            child: widget.tabs[safeIndex].tabContentBuilder(context),
          )),
        ],
      ),
    );
  }
}
