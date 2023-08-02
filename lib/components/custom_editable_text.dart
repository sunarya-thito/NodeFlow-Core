import 'package:flutter/material.dart';

class CustomEditableText extends StatefulWidget {
  final TextEditingController controller;
  final Widget child;
  final FocusNode? focusNode;
  const CustomEditableText({Key? key, required this.child, required this.controller, this.focusNode}) : super(key: key);

  @override
  State<CustomEditableText> createState() => _CustomEditableTextState();
}

class _CustomEditableTextState extends State<CustomEditableText> {
  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: implement build
    // return ContextMenu(
    //   focusNode: widget.focusNode,
    //   // intentBuilder: () => ,
    //   child: widget.child,
    // );
  }
}
