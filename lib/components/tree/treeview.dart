import 'dart:math';

import 'package:adaptive_scrollbar/adaptive_scrollbar.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nodeflow/components/widget_size_reporter.dart';

import '../../theme/compact_data.dart';
import '../click_listener.dart';

class SimpleTreeItemLayout extends StatelessWidget {
  final Widget? leading;
  final Widget child;

  const SimpleTreeItemLayout({Key? key, this.leading, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) leading!,
        if (leading != null) const SizedBox(width: 4),
        child,
      ],
    );
  }
}

class ExpandNotification extends Notification {}

class TreeData<T> extends ChangeNotifier {
  final T data;
  final List<TreeData<T>> _children;
  TreeData<T>? _parent;
  late bool _expanded;
  late bool _selected;
  late bool _movable;
  final FocusNode _focusNode = FocusNode();
  final VoidCallback? onOpenRequested;
  TreeData(this.data, {bool expanded = false, bool selected = false, List<TreeData<T>>? children, bool movable = true, this.onOpenRequested})
      : _children = children ?? [],
        _expanded = expanded,
        _movable = movable,
        _selected = selected {
    for (final child in _children) {
      assert(child._parent == null);
      child._parent = this;
      child.addListener(notifyListeners);
    }
  }

  // to string
  @override
  String toString() {
    return 'TreeData{data: $data}';
  }

  bool get movable => _movable;
  set movable(bool value) {
    if (_movable != value) {
      _movable = value;
      notifyListeners();
    }
  }

  bool get expanded => _expanded;
  set expanded(bool value) {
    if (_expanded != value) {
      _expanded = value;
    }
  }

  bool get visible => _parent == null || (_parent!.expanded && _parent!.visible);

  bool get selected => _selected;
  set selected(bool value) {
    if (_selected != value) {
      _selected = value;
      // if (_selected) {
      //   _focusNode.requestFocus();
      // } else {
      //   _focusNode.unfocus();
      // }
      notifyListeners();
    }
  }

  void _addChild(TreeData<T> child) {
    assert(child._parent == null);
    child._parent = this;
    _children.add(child);
    child.addListener(notifyListeners);
  }

  void _removeChild(TreeData<T> child) {
    assert(child._parent == this);
    child._parent = null;
    _children.remove(child);
    child.removeListener(notifyListeners);
  }

  List<TreeData<T>> get children => List.unmodifiable(_children);
}

class TreeDataController<T> extends ChangeNotifier {
  TreeData<T> _root;
  final Widget Function(BuildContext context, TreeData<T> data) childBuilder;

  TreeDataController({
    required TreeData<T> root,
    required this.childBuilder,
  }) : _root = root {
    root.addListener(notifyListeners);
  }

  TreeData<T> get root => _root;

  void _openSelected(TreeData<T> parent) {
    if (parent.selected && parent.visible) {}
  }

  set root(TreeData<T> value) {
    _root.removeListener(notifyListeners);
    _root = value;
    _root.addListener(notifyListeners);
    notifyListeners();
  }

  @override
  void dispose() {
    _root.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  bool _unselectAll(TreeData<T> parent) {
    bool hasFocus = false;
    for (final child in parent.children) {
      if (child.selected) {
        child._selected = false;
        hasFocus = true;
      }
      hasFocus |= _unselectAll(child);
    }
    return hasFocus;
  }

  void collapse(TreeItem<T> item) {
    var data = item.data;
    data._expanded = false;
    // unselect all children
    bool hasSelected = _unselectAll(data);
    // if has selected child, select parent
    if (hasSelected) {
      data._selected = true;
    }
    data.notifyListeners();
  }

  void onMove(TreeItem<T>? parent, TreeItem<T> item, TreeItem<T>? targetParent) {
    TreeData<T> parentData = parent == null ? root : parent.data;
    TreeData<T> targetParentData = targetParent == null ? root : targetParent.data;
    TreeData<T> data = item.data;
    parentData._removeChild(data);
    targetParentData._addChild(data);
    // check if T is Comparable
    if (T is Comparable) {
      targetParentData._children.sort((a, b) => (a.data as Comparable).compareTo(b.data));
    }
  }

  void onExpanded(TreeItem<T> item, bool expanded) {
    if (expanded) {
      expand(item);
    } else {
      collapse(item);
    }
  }

  void onSelected(Iterable<TreeItem<T>> toSelect, Iterable<TreeItem<T>> toUnselect) {
    for (final item in toSelect) {
      item.data.selected = true;
    }
    for (final item in toUnselect) {
      item.data.selected = false;
    }
  }

  void expand(TreeItem<T> item) {
    item.data.expanded = true;
  }

  void _clearSelection(TreeData<T> data) {
    data._selected = false;
    for (final child in data._children) {
      _clearSelection(child);
    }
  }

  void onClearSelection() {
    _clearSelection(_root);
    notifyListeners();
  }
}

class TreeTheme extends InheritedWidget {
  static TreeThemeData createDefault(BuildContext context) {
    CompactData data = CompactData.of(context);
    return TreeThemeData(
      backgroundColor: data.theme.surfaceColor,
      itemTheme: TreeItemThemeData(
        expandIconSize: const MaterialStatePropertyAll(kTreeItemExpandIconSize),
        childrenIndent: kTreeItemIndent,
        backgroundColor: MaterialStateColor.resolveWith(
          (states) {
            if (states.contains(MaterialState.dragged)) {
              return data.theme.selectedTreeColor;
            }
            if (states.contains(MaterialState.hovered) && states.contains(MaterialState.selected)) {
              return data.theme.hoveredSelectedTreeColor;
            }
            if (states.contains(MaterialState.selected)) {
              if (!states.contains(MaterialState.focused)) {
                return data.theme.unfocusedSelectedTreeColor;
              }
              return data.theme.selectedTreeColor;
            }
            if (states.contains(MaterialState.hovered)) {
              return data.theme.hoveredTreeColor;
            }
            return Colors.transparent;
          },
        ),
        border: MaterialStateProperty.resolveWith(
          (states) {
            return const Border();
          },
        ),
        textStyle: MaterialStateTextStyle.resolveWith(
          (states) {
            return TextStyle(
              fontFamily: 'Inter',
              color: data.theme.primaryTextColor,
              fontSize: 12,
              decoration: TextDecoration.none,
              fontWeight: FontWeight.normal,
            );
          },
        ),
        padding: const MaterialStatePropertyAll(
          EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        ),
      ),
    );
  }

  final TreeThemeData data;
  const TreeTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  static TreeThemeData of(BuildContext context) {
    final TreeTheme? result = context.dependOnInheritedWidgetOfExactType<TreeTheme>();
    assert(result != null, 'No TreeTheme found in context');
    return result!.data;
  }

  @override
  bool updateShouldNotify(TreeTheme oldWidget) => data != oldWidget.data;
}

class TreeThemeData {
  final Color backgroundColor;
  final EdgeInsets padding;
  final TreeItemThemeData itemTheme;
  final double indent;

  const TreeThemeData({
    this.backgroundColor = Colors.transparent,
    this.padding = const EdgeInsets.all(0),
    this.indent = kTreeItemIndent,
    required this.itemTheme,
  });
}

class TreeItemThemeData {
  final MaterialStateColor backgroundColor;
  final MaterialStateProperty<Border> border;
  final MaterialStateTextStyle textStyle;
  final MaterialStateProperty<EdgeInsets> padding;
  final double childrenIndent;
  final MaterialStateProperty<double> expandIconSize;

  const TreeItemThemeData({
    required this.backgroundColor,
    required this.border,
    required this.textStyle,
    required this.padding,
    required this.childrenIndent,
    required this.expandIconSize,
  });
}

class TreeItem<T> extends StatefulWidget {
  final TreeView<T> tree;
  final TreeItem<T>? parent;
  final TreeData<T> data;
  final Widget child;
  final bool draggable;
  final bool expandable;
  final void Function(TreeItem<T> item, bool) onSelected;
  final void Function() onSelectAbove;
  final void Function() onSelectBelow;
  final FocusNode focusNode;

  const TreeItem({
    Key? key,
    required this.focusNode,
    required this.data,
    required this.child,
    this.expandable = false,
    this.draggable = false,
    this.parent,
    required this.tree,
    required this.onSelected,
    required this.onSelectAbove,
    required this.onSelectBelow,
  }) : super(key: key);

  void dispatchSelected(bool selected) {
    onSelected(this, selected);
  }

  @override
  _TreeItemState createState() => _TreeItemState();
}

class _TreeItemState<T> extends State<TreeItem<T>> {
  bool _hovered = false;

  void _update() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.data.removeListener(_update);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TreeItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      oldWidget.data.removeListener(_update);
      widget.data.addListener(_update);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.data.addListener(_update);
  }

  int calculateDepth() {
    int depth = 0;
    TreeItem<T>? parent = widget.parent;
    while (parent != null) {
      depth++;
      parent = parent.parent;
    }
    return depth;
  }

  double? width;

  @override
  Widget build(BuildContext context) {
    TreeThemeData theme = TreeTheme.of(context);
    return WidgetSizeReporter(
      onSizeChanged: (size) {
        width = size.width;
      },
      child: Focus(
        onFocusChange: (value) {
          if (value) {
            widget.dispatchSelected(true);
          }
          setState(() {});
        },
        onKey: (node, event) {
          if (event is RawKeyDownEvent) {
            if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
              // collapse
              if (widget.data.expanded) {
                // data.state.widget.onExpanded?.call(widget, false);
                widget.tree.controller.onExpanded(widget, false);
                context.dispatchNotification(ExpandNotification());
                return KeyEventResult.handled;
              }
            }
            if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
              // expand
              if (!widget.data.expanded) {
                widget.tree.controller.onExpanded(widget, true);
                context.dispatchNotification(ExpandNotification());
                return KeyEventResult.handled;
              }
            }
            if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
              widget.onSelectAbove();
              return KeyEventResult.handled;
            }
            if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
              widget.onSelectBelow();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        focusNode: widget.focusNode,
        child: DragTarget<TreeItem<T>>(
          hitTestBehavior: HitTestBehavior.translucent,
          onWillAccept: (d) {
            if (d != null) {
              var canMoveHandler = widget.tree.canMove;
              if (canMoveHandler != null) {
                return canMoveHandler(d.parent, d, widget);
              }
            }
            return false;
          },
          onAccept: (d) {
            var moveHandler = widget.tree.controller.onMove;
            if (d.parent != widget && d != widget) {
              // prevent the tree item to be moved to its child or its child's child and so on
              TreeItem? widgetParent = widget;
              while (widgetParent != null) {
                if (widgetParent == d) {
                  return;
                }
                widgetParent = widgetParent.parent;
              }
              moveHandler(d.parent, d, widget);
              context.dispatchNotification(ExpandNotification());
            }
          },
          builder: (context, candidateData, rejectedData) {
            var mouseRegion = MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: ClickListener(
                behavior: HitTestBehavior.translucent,
                onClick: () {
                  // _focusNode.requestFocus();
                  widget.focusNode.requestFocus();
                },
                onDoubleClick: () {
                  if (widget.expandable) {
                    widget.tree.controller.onExpanded(widget, !widget.data.expanded);
                    // dispatch ExpandNotification
                    context.dispatchNotification(ExpandNotification());
                  }
                  var openHandler = widget.data.onOpenRequested;
                  if (openHandler != null) {
                    openHandler();
                  }
                },
                child: Container(
                  padding: theme.itemTheme.padding.resolve({
                    if (widget.data.selected) MaterialState.selected,
                    if (_hovered) MaterialState.hovered,
                    if (candidateData.isNotEmpty) MaterialState.dragged,
                    if (widget.focusNode.hasFocus) MaterialState.focused,
                  }),
                  decoration: BoxDecoration(
                    color: theme.itemTheme.backgroundColor.resolve({
                      if (widget.data.selected) MaterialState.selected,
                      if (_hovered) MaterialState.hovered,
                      if (candidateData.isNotEmpty) MaterialState.dragged,
                      if (widget.focusNode.hasFocus) MaterialState.focused,
                    }),
                    border: theme.itemTheme.border.resolve({
                      if (widget.data.selected) MaterialState.selected,
                      if (_hovered) MaterialState.hovered,
                      if (candidateData.isNotEmpty) MaterialState.dragged,
                      if (widget.focusNode.hasFocus) MaterialState.focused,
                    }),
                  ),
                  child: DefaultTextStyle(
                    style: theme.itemTheme.textStyle.resolve({
                      if (widget.data.selected) MaterialState.selected,
                      if (_hovered) MaterialState.hovered,
                      if (candidateData.isNotEmpty) MaterialState.dragged,
                    }),
                    child: Container(
                      padding: EdgeInsets.only(left: theme.indent * calculateDepth()),
                      child: Row(
                        children: [
                          !widget.expandable
                              ? SizedBox(
                                  width: theme.itemTheme.expandIconSize.resolve({
                                    if (widget.data.selected) MaterialState.selected,
                                    if (_hovered) MaterialState.hovered,
                                    if (candidateData.isNotEmpty) MaterialState.dragged,
                                    if (widget.focusNode.hasFocus) MaterialState.focused,
                                  }),
                                  height: theme.itemTheme.expandIconSize.resolve({
                                    if (widget.data.selected) MaterialState.selected,
                                    if (_hovered) MaterialState.hovered,
                                    if (candidateData.isNotEmpty) MaterialState.dragged,
                                    if (widget.focusNode.hasFocus) MaterialState.focused,
                                  }))
                              : GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    widget.tree.controller.onExpanded(widget, !widget.data.expanded);
                                    // dispatch ExpandNotification
                                    context.dispatchNotification(ExpandNotification());
                                  },
                                  child: Icon(
                                    widget.data.expanded ? Icons.expand_more : Icons.chevron_right,
                                    size: theme.itemTheme.expandIconSize.resolve(
                                      {
                                        if (widget.data.selected) MaterialState.selected,
                                        if (_hovered) MaterialState.hovered,
                                        if (candidateData.isNotEmpty) MaterialState.dragged,
                                        if (widget.focusNode.hasFocus) MaterialState.focused,
                                      },
                                    ),
                                  ),
                                ),
                          const SizedBox(width: 4),
                          widget.child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            if (widget.draggable) {
              var draggable = Draggable<TreeItem<T>>(
                data: widget,
                feedback: Builder(builder: (context) {
                  return Opacity(
                    opacity: 0.8,
                    child: Container(
                      width: width,
                      padding: theme.itemTheme.padding.resolve({MaterialState.hovered}),
                      decoration: BoxDecoration(
                        color: theme.itemTheme.backgroundColor.resolve({MaterialState.hovered}),
                        border: theme.itemTheme.border.resolve({MaterialState.hovered}),
                      ),
                      child: DefaultTextStyle(
                        style: theme.itemTheme.textStyle.resolve({MaterialState.hovered}),
                        child: Container(
                          padding: EdgeInsets.only(left: theme.indent * calculateDepth()),
                          child: widget.child,
                        ),
                      ),
                    ),
                  );
                }),
                child: mouseRegion,
              );
              return draggable;
            }
            return mouseRegion;
          },
        ),
      ),
    );
  }
}

const double kTreeItemIndent = 20;
const double kTreeItemExpandIconSize = 16;

enum TreeItemSelection {
  disable,
  single,
  multiple;
}

class TreeView<T> extends StatefulWidget {
  final TreeItemSelection selection;
  final TreeDataController<T> controller;
  final void Function(TreeItem item)? onOpenRequested;
  final bool Function(TreeItem? parent, TreeItem item, TreeItem? targetParent)? canMove;
  final bool showRoot;

  const TreeView({
    Key? key,
    required this.controller,
    this.selection = TreeItemSelection.multiple,
    this.onOpenRequested,
    this.canMove,
    this.showRoot = false,
  }) : super(key: key);

  @override
  TreeViewState<T> createState() => TreeViewState<T>();
}

class TreeViewState<T> extends State<TreeView<T>> {
  final List<TreeItem<T>> _flattenItems = [];

  @override
  void initState() {
    super.initState();
    _rebuildFlattenItems();
  }

  void _rebuildFlattenItems() {
    _flattenItems.clear();
    if (widget.showRoot) {
      _flatten(_flattenItems, null, widget.controller.root);
    } else {
      for (var child in widget.controller.root.children) {
        _flatten(_flattenItems, null, child);
      }
    }
  }

  TreeItem<T>? findExisting(TreeData<T> data) {
    for (var i in _flattenItems) {
      if (i.data == data) {
        return i;
      }
    }
    return null;
  }

  void _flatten(List<TreeItem<T>> list, TreeItem<T>? parent, TreeData<T> item) {
    final int index = list.length;
    var treeItem = TreeItem<T>(
      focusNode: item._focusNode,
      tree: widget,
      expandable: item.children.isNotEmpty,
      draggable: item.movable,
      parent: parent,
      data: item,
      onSelectAbove: () {
        _focusNode.previousFocus();
      },
      onSelectBelow: () {
        _focusNode.nextFocus();
      },
      onSelected: (TreeItem<T> item, bool selected) {
        if (_multiSelecting) {
          _startDragIndex = index;
          widget.controller.onSelected([item], []);
        } else {
          if (_dragSelecting) {
            widget.controller.onSelected(
              _flattenItems.whereIndexed((i, element) => max(_startDragIndex, index) >= i && i >= min(_startDragIndex, index)),
              _flattenItems.whereNotIndexed((i, element) => max(_startDragIndex, index) >= i && i >= min(_startDragIndex, index)),
            );
          } else {
            _startDragIndex = index;
            widget.controller.onSelected([item], _flattenItems.whereNotIndexed((i, element) => index == i));
          }
        }
      },
      child: FocusTraversalOrder(
        order: NumericFocusOrder(index.toDouble()),
        child: Builder(
          builder: (context) {
            return widget.controller.childBuilder(context, item);
          },
        ),
      ),
    );
    list.add(
      treeItem,
    );
    if (item.expanded) {
      for (var child in item.children) {
        _flatten(list, treeItem, child);
      }
    }
  }

  bool _multiSelecting = false;
  bool _dragSelecting = false;
  int _startDragIndex = -1;

  final _focusNode = FocusScopeNode(debugLabel: 'TreeView');
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    TreeThemeData theme = TreeTheme.of(context);
    return NotificationListener<ExpandNotification>(
      onNotification: (notification) {
        setState(() {
          _rebuildFlattenItems();
        });
        return true;
      },
      child: GestureDetector(
        onTap: () {
          // if (_focusNode.hasFocus) {
          //   widget.controller.onClearSelection();
          // }
          _focusNode.requestFocus();
        },
        child: FocusScope(
          onFocusChange: (value) {
            setState(() {});
          },
          node: _focusNode,
          onKey: (node, event) {
            // check multi selecting
            if (event is RawKeyDownEvent) {
              if (event.isKeyPressed(LogicalKeyboardKey.controlLeft) || event.isKeyPressed(LogicalKeyboardKey.controlRight)) {
                if (widget.selection == TreeItemSelection.multiple) {
                  _multiSelecting = true;
                }
              }
              if (event.isKeyPressed(LogicalKeyboardKey.shiftLeft) || event.isKeyPressed(LogicalKeyboardKey.shiftRight)) {
                if (widget.selection == TreeItemSelection.multiple) {
                  _dragSelecting = true;
                }
              }
              if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
                widget.controller._openSelected(widget.controller.root);
                return KeyEventResult.handled;
              }
              if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
                if (!_dragSelecting) {
                  _startDragIndex = (_startDragIndex - 1).clamp(0, _flattenItems.length - 1);
                  // TODO refresh selection
                }
                return KeyEventResult.handled;
              }
              if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
                if (!_dragSelecting) {
                  _startDragIndex = (_startDragIndex + 1).clamp(0, _flattenItems.length - 1);
                  // TODO refresh selection
                }
                return KeyEventResult.handled;
              }
            }
            if (event is RawKeyUpEvent) {
              if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
                _dragSelecting = false;
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.controlLeft || event.logicalKey == LogicalKeyboardKey.controlRight) {
                _multiSelecting = false;
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: DragTarget<TreeItem<T>>(
            onWillAccept: (data) {
              if (data != null && data.parent != null) {
                var canMoveHandler = widget.canMove;
                if (canMoveHandler != null) {
                  return canMoveHandler(data.parent, data, null);
                }
              }
              return false;
            },
            onAccept: (data) {
              widget.controller.onMove(data.parent, data, null);
              setState(() {
                _rebuildFlattenItems();
              });
            },
            hitTestBehavior: HitTestBehavior.translucent,
            builder: (context, candidateData, rejectedData) {
              return LayoutBuilder(builder: (context, constraints) {
                ScrollbarThemeData barTheme = Theme.of(context).scrollbarTheme;
                // return Container(
                //   child: ListView.builder(
                //     itemBuilder: (context, index) {
                //       return SizedBox(
                //         width: 400,
                //         child: _flattenItems[index],
                //       );
                //     },
                //     itemCount: _flattenItems.length,
                //   ),
                // );
                return Container(
                  color: theme.backgroundColor,
                  child: AdaptiveScrollbar(
                    controller: _verticalScrollController,
                    sliderDefaultColor: barTheme.thumbColor?.resolve({}) ?? Colors.transparent,
                    sliderActiveColor: barTheme.thumbColor?.resolve({MaterialState.focused}) ?? Colors.transparent,
                    sliderSpacing: EdgeInsets.zero,
                    width: barTheme.thickness?.resolve({}) ?? 8,
                    underColor: barTheme.trackColor?.resolve({}) ?? Colors.transparent,
                    child: AdaptiveScrollbar(
                      controller: _horizontalScrollController,
                      position: ScrollbarPosition.bottom,
                      sliderDefaultColor: barTheme.thumbColor?.resolve({}) ?? Colors.transparent,
                      sliderActiveColor: barTheme.thumbColor?.resolve({MaterialState.focused}) ?? Colors.transparent,
                      sliderSpacing: EdgeInsets.zero,
                      width: barTheme.thickness?.resolve({}) ?? 8,
                      underColor: barTheme.trackColor?.resolve({}) ?? Colors.transparent,
                      child: ScrollConfiguration(
                        behavior: ScrollBehavior().copyWith(scrollbars: false, physics: ImplicitScrollPhysics()),
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            controller: _verticalScrollController,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: IntrinsicWidth(
                                child: FocusTraversalGroup(
                                  policy: OrderedTraversalPolicy(),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: _flattenItems,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }
}

class ImplicitScrollPhysics extends ScrollPhysics {
  @override
  bool get allowImplicitScrolling => false;
}
