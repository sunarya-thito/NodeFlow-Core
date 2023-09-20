import 'package:flutter/material.dart';
import 'package:nodeflow/components/locale_widget.dart';

class NavigationLabel extends StatelessWidget {
  final String label;
  const NavigationLabel({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return label.asBuilderWidget((context, i18n) => Text(
          i18n,
          style: const TextStyle(fontSize: 16, decoration: TextDecoration.none, fontWeight: FontWeight.normal),
        ));
  }
}
