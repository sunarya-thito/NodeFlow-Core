import 'package:flutter/material.dart';

class NavigationSideBar extends StatefulWidget {
  final List<Widget> children;
  const NavigationSideBar({Key? key, required this.children}) : super(key: key);

  @override
  _NavigationSideBarState createState() => _NavigationSideBarState();
}

class _NavigationSideBarState extends State<NavigationSideBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.children,
      ),
    );
  }
}
