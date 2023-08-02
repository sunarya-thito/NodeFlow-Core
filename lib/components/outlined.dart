import 'package:flutter/material.dart';
import 'package:nodeflow/theme/compact_data.dart';

class Outlined extends StatelessWidget {
  final Widget child;

  const Outlined({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: app(context).dividerColor, strokeAlign: BorderSide.strokeAlignOutside, style: BorderStyle.solid, width: 1),
      ),
      child: child,
    );
  }
}
