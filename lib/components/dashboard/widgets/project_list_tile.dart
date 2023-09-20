import 'package:flutter/material.dart';
import 'package:nodeflow/theme/compact_data.dart';

class ProjectListTile extends StatefulWidget {
  final String title;
  final String? description;
  final Widget icon;

  const ProjectListTile({
    Key? key,
    required this.title,
    this.description,
    required this.icon,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ProjectListTileState();
  }
}

class _ProjectListTileState extends State<ProjectListTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: app.surfaceColor,
        border: Border.all(color: app.dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconTheme(
                    data: IconThemeData(size: 40, color: app.secondaryTextColor),
                    child: widget.icon,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(fontSize: 18),
                        ),
                        if (widget.description != null)
                          Text(
                            widget.description!,
                            style: TextStyle(fontSize: 12, color: app.secondaryTextColor),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.more_horiz),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
