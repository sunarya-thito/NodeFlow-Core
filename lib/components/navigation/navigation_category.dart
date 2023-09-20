import 'package:flutter/material.dart';

class NavigationCategory extends StatefulWidget {
  final Widget label;
  final List<Widget> children;
  const NavigationCategory({Key? key, required this.label, required this.children}) : super(key: key);

  @override
  _NavigationCategoryState createState() => _NavigationCategoryState();
}

class _NavigationCategoryState extends State<NavigationCategory> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 18, bottom: 24),
      child: Wrap(
        runSpacing: 2,
        children: [
          Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 12), child: widget.label),
          ...widget.children,
        ],
      ),
    );
  }
}
