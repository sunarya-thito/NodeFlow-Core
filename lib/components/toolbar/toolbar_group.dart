import 'package:flutter/material.dart';

class ToolbarGroup extends StatefulWidget {
  final List<Widget> items;

  const ToolbarGroup({Key? key, required this.items}) : super(key: key);

  @override
  _ToolbarGroupState createState() => _ToolbarGroupState();
}

class _ToolbarGroupState extends State<ToolbarGroup> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...widget.items,
        const VerticalDivider(),
      ],
    );
  }
}
