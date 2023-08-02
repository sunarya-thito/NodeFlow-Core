import 'package:flutter/material.dart';

class LabelParameter extends StatelessWidget {
  final Widget label;

  const LabelParameter({
    Key? key,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 16,
      ),
      child: label,
    );
  }
}
