import 'package:flutter/material.dart';
import 'package:nodeflow/components/toolbar/toolbar_group.dart';

import '../../ui_util.dart';

class Toolbar extends StatefulWidget {
  final List<ToolbarGroup> toolbars;
  const Toolbar({Key? key, required this.toolbars}) : super(key: key);

  @override
  ToolbarState createState() => ToolbarState();
}

class ToolbarState extends State<Toolbar> {
  static const double toolbarHeight = 32;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ...joinWidgets(
        widget.toolbars.where((element) => element.items.isNotEmpty).map((e) => ToolbarItemsViewport(items: e.items)).toList(),
        () => const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: VerticalDivider()),
      ),
    ]);
  }
}

class ToolbarItemsViewport extends StatefulWidget {
  final List<Widget> items;
  const ToolbarItemsViewport({Key? key, required this.items}) : super(key: key);

  @override
  _ToolbarItemsViewportState createState() => _ToolbarItemsViewportState();
}

class _ToolbarItemsViewportState extends State<ToolbarItemsViewport> {
  @override
  Widget build(BuildContext context) {
    return Row(children: widget.items.map((e) => Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: e)).toList());
  }
}
