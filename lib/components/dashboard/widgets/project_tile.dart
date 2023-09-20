import 'package:flutter/material.dart';
import 'package:nodeflow/blueprint_util.dart';
import 'package:nodeflow/theme/compact_data.dart';
import 'package:nodeflow/ui_util.dart';

class ProjectTile extends StatelessWidget {
  final String title;
  final Widget? icon;

  const ProjectTile({Key? key, required this.title, this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var generateColor = ColorStorage.generateColor(title.hashCode, app(context).brightness);
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        border:
            Border.all(color: app(context).brightness == Brightness.dark ? generateColor.calculateBrighterColor(0.2) : generateColor.calculateDarkerColor(0.2)),
        borderRadius: BorderRadius.circular(8),
        color: generateColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            focusColor: app(context).focusedSurfaceColor,
            onTap: () {},
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  left: -30,
                  child: IconTheme(data: IconThemeData(size: 120, color: Colors.white.withOpacity(0.5)), child: icon ?? Icon(iconFromHashcode(title.hashCode))),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                Positioned(
                  top: 0,
                  right: -5,
                  child: IconButton(
                      onPressed: () {
                        print('more');
                      },
                      icon: const Icon(Icons.more_vert),
                      color: app(context).primaryTextColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
