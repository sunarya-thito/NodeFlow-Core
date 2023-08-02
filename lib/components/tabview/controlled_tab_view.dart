import 'package:flutter/material.dart';
import 'package:nodeflow/components/tabview/tab_view.dart';

class TabViewController extends ChangeNotifier {
  final List<TabEntry> _entries = [];
  int _focusedTabIndex = -1;

  TabViewController(List<TabEntry>? entries) {
    if (entries != null) {
      _entries.addAll(entries);
    }
  }

  int get focusedTabIndex => _focusedTabIndex.clamp(0, _entries.length - 1);
  TabEntry get focusedTab => _entries[_focusedTabIndex];

  set focusedTabIndex(int value) {
    if (_focusedTabIndex != value) {
      _focusedTabIndex = value;
      notifyListeners();
    }
  }

  void add(TabEntry entry) {
    if (_entries.contains(entry)) {
      return;
    }
    _entries.add(entry);
    notifyListeners();
  }

  void insert(int index, TabEntry entry) {
    if (_entries.contains(entry)) {
      return;
    }
    _entries.insert(index, entry);
    notifyListeners();
  }

  void remove(TabEntry entry) {
    if (!_entries.contains(entry)) {
      return;
    }
    _entries.remove(entry);
    notifyListeners();
  }

  void removeAt(int index) {
    _entries.removeAt(index);
    notifyListeners();
  }

  void addAll(Iterable<TabEntry> entries) {
    _entries.addAll(entries);
    notifyListeners();
  }

  void insertAll(int index, Iterable<TabEntry> entries) {
    _entries.insertAll(index, entries);
    notifyListeners();
  }

  void moveAt(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) {
      return;
    }
    final entry = _entries.removeAt(oldIndex);
    _entries.insert(newIndex, entry);
    notifyListeners();
  }

  void move(TabEntry entry, int newIndex) {
    final oldIndex = _entries.indexOf(entry);
    if (oldIndex == newIndex) {
      return;
    }
    _entries.remove(entry);
    _entries.insert(newIndex, entry);
    notifyListeners();
  }
}

class ControlledTabView extends StatefulWidget {
  final TabViewController controller;
  final Function(TabEntry removed)? onTabRemoved;
  final Function(TabEntry entry, int target)? onTabMoved;
  final Widget? leading, trailing;
  final Widget Function(BuildContext context) emptyViewBuilder;
  const ControlledTabView({
    Key? key,
    required this.controller,
    this.onTabRemoved,
    this.onTabMoved,
    this.leading,
    this.trailing,
    required this.emptyViewBuilder,
  }) : super(key: key);

  @override
  _ControlledTabViewState createState() => _ControlledTabViewState();
}

class _ControlledTabViewState extends State<ControlledTabView> {
  TabViewController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TabView(
      tabs: controller._entries,
      focusedTabIndex: controller.focusedTabIndex,
      onTabFocused: (index) {
        controller.focusedTabIndex = index;
      },
      onTabClosed: (index) {
        controller.removeAt(index);
      },
      onTabSwap: (source, target) {
        controller.move(source, target);
      },
      trailing: widget.trailing,
      leading: widget.leading,
      emptyViewBuilder: widget.emptyViewBuilder,
    );
  }
}
