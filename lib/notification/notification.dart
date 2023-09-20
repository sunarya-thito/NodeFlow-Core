import 'package:flutter/material.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/i18n.dart';

abstract class AppNotification extends Notification {
  Widget build(BuildContext context);
}

class SimpleAppNotification extends Notification {
  final Widget icon;
  final I18nString title;
  final I18nString message;
  final List<Widget> actions;
  final VoidCallback? onDismissed;

  SimpleAppNotification({
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const [],
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismissed,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            icon,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title(context.i18n).asTextWidget(
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                message(context.i18n).asTextWidget(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
