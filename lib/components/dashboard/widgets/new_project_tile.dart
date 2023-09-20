import 'package:flutter/material.dart';
import 'package:nodeflow/theme/compact_data.dart';

import '../../page_holder.dart';
import '../pages/new_project_page.dart';

class NewProjectTile extends StatelessWidget {
  const NewProjectTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: app(context).dividerColor),
        color: app(context).surfaceColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Material(
          color: Colors.transparent,
          borderOnForeground: true,
          child: InkWell(
            focusColor: app(context).focusedSurfaceColor,
            onTap: () {
              // TODO new project dialog
              SubNavigator.of(context).go(NewProjectPage());
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IconTheme(data: IconThemeData(size: 40, color: Colors.white.withOpacity(0.5)), child: Icon(Icons.add)),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Text(i18n(context).projectsNew),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
