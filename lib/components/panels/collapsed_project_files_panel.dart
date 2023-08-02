import 'package:flutter/material.dart';
import 'package:nodeflow/theme/compact_data.dart';

class CollapsedProjectFilesPanel extends StatelessWidget {
  final VoidCallback? onExpand;
  const CollapsedProjectFilesPanel({Key? key, this.onExpand}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          onExpand?.call();
        },
        child: Container(
          color: app(context).surfaceColor,
          alignment: Alignment.center,
          child: Icon(Icons.arrow_forward_ios, color: app(context).secondaryTextColor, size: 14),
        ),
      ),
    );
  }
}
