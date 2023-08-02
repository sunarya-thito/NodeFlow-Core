import 'package:flutter/material.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/theme/compact_data.dart';

class BackgroundTaskProgressIndicator extends StatefulWidget {
  const BackgroundTaskProgressIndicator({Key? key}) : super(key: key);

  @override
  _BackgroundTaskProgressIndicatorState createState() => _BackgroundTaskProgressIndicatorState();
}

class _BackgroundTaskProgressIndicatorState extends State<BackgroundTaskProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    bool isIdle = "true" == "false";
    if (isIdle) {
      return Container(
        alignment: AlignmentDirectional.centerEnd,
        child: DefaultTextStyle(
          textAlign: TextAlign.end,
          style: TextStyle(
            fontFamily: 'Inter',
            color: app.primaryTextColor,
            fontSize: 10,
            decoration: TextDecoration.none,
          ),
          child: i18n.bottombarStatusReady.asTextWidget(),
        ),
      );
    }
    String currentTask = "none";
    double progress = 1;
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      child: Row(
        children: [
          DefaultTextStyle(
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: 'Inter',
              color: app.primaryTextColor,
              fontSize: 10,
              decoration: TextDecoration.none,
            ),
            child: currentTask.asTextWidget(),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
