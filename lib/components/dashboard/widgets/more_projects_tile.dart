import 'package:flutter/material.dart';
import 'package:nodeflow/blueprint_util.dart';
import 'package:nodeflow/components/dashboard/dashboard.dart';
import 'package:nodeflow/router.dart';
import 'package:nodeflow/theme/compact_data.dart';

class MoreProjectsTile extends StatelessWidget {
  const MoreProjectsTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    int more = 3;
    var generateColor = ColorStorage.generateColor(more, app(context).brightness);
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: app(context).brightness == Brightness.dark ? generateColor.calculateBrighterColor(0.2) : generateColor.calculateDarkerColor(0.2)),
        gradient: LinearGradient(
          colors: [
            generateColor,
            generateColor.withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
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
              context.replacePaths([KeyPath(pageMyProjects.value)]);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      more.toString(),
                      style: TextStyle(fontSize: 32),
                    ),
                    Text(i18n(context).projectsMore),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
