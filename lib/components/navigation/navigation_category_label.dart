import 'package:flutter/material.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/theme/compact_data.dart';

class NavigationCategoryLabel extends StatelessWidget {
  final String label;
  const NavigationCategoryLabel({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style:
          TextStyle(color: app(context).secondaryTextColor, fontSize: 12, decoration: TextDecoration.none, fontWeight: FontWeight.normal, fontFamily: 'Inter'),
      child: label.asTextWidget(),
    );
  }
}
