import 'package:flutter/material.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/components/tooltip/tooltip_wrapper.dart';
import 'package:nodeflow/hotkey.dart';

import '../theme/compact_data.dart';
import 'bar_button.dart';

class BottomBarTab extends StatelessWidget {
  final bool selected;
  final String tooltip;
  final ShortcutKey shortcutKey;
  final Widget icon;
  final String title;
  final VoidCallback onTap;

  const BottomBarTab({
    Key? key,
    required this.selected,
    required this.tooltip,
    required this.shortcutKey,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TooltipWrapper(
      tooltip: TooltipWrapper.actionTooltip(tooltip, null, null, shortcutKey),
      child: BarButton(
        selected: selected,
        child: Row(
          children: [
            IconTheme(
              data: IconThemeData(
                color: CompactData.of(context).theme.primaryTextColor,
                size: 16,
              ),
              child: icon,
            ),
            const SizedBox(width: 4),
            DefaultTextStyle(
              style: TextStyle(
                fontFamily: 'Inter',
                color: CompactData.of(context).theme.primaryTextColor,
                fontSize: 12,
              ),
              child: title.asTextWidget(),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
