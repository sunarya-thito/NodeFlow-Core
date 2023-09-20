import 'package:flutter/material.dart';

class NavigationTopBar extends StatefulWidget {
  final List<Widget> children;
  const NavigationTopBar({Key? key, required this.children}) : super(key: key);

  @override
  _NavigationTopBarState createState() => _NavigationTopBarState();
}

class _NavigationTopBarState extends State<NavigationTopBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: EdgeInsets.only(top: 12, bottom: 12, left: 28, right: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.children,
      ),
    );
  }
}
