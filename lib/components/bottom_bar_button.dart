import 'package:flutter/material.dart';
import 'package:nodeflow/components/tooltip/tooltip_wrapper.dart';
import 'package:nodeflow/theme/compact_data.dart';
import 'package:nodeflow/ui_util.dart';

import 'background_task_progress_indicator.dart';
import 'bar_button.dart';

class BottomBarButton extends StatelessWidget {
  final bool isOpened;

  const BottomBarButton({
    Key? key,
    required this.isOpened,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TooltipWrapper(
      tooltip: TooltipWrapper.defaultTooltip(i18n(context).tooltipBackgroundTasks),
      child: Builder(builder: (context) {
        var windowAnchor = context.localToGlobal(Offset(context.localSize.width, 0));
        return BarButton(
          selected: isOpened,
          child: const BackgroundTaskProgressIndicator(),
          onTap: () {
            // nodeflow.getContext<ActionContext>().executeActionByKey(
            //     context,
            //     AppActions.actionShowBackgroundTasks,
            //     IntentMenuAnchor(
            //       left: windowAnchor.dx - kWindowBackgroundTasksWidth,
            //       bottom: kBottomBarHeight,
            //     ));
          },
        );
      }),
    );
  }
}
