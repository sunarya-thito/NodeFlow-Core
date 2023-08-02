import 'package:flutter/material.dart';

class TitleParameter extends StatelessWidget {
  final Widget title;
  final Widget? subTitle;
  final Widget? icon;

  const TitleParameter({
    Key? key,
    required this.title,
    this.subTitle,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
