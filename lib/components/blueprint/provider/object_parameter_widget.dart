import 'package:flutter/material.dart';

class ObjectParameterWidget extends StatefulWidget {
  final Alignment alignment;
  final Widget text;

  const ObjectParameterWidget({
    Key? key,
    required this.alignment,
    required this.text,
  }) : super(key: key);

  @override
  _ObjectParameterWidgetState createState() => _ObjectParameterWidgetState();
}

class _ObjectParameterWidgetState extends State<ObjectParameterWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
