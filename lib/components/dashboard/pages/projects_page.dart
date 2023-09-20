import 'package:flutter/material.dart';
import 'package:nodeflow/components/dashboard/widgets/project_list_tile.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/theme/compact_data.dart';
import 'package:nodeflow/ui_util.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ProjectsPageState();
  }
}

class _ProjectsPageState extends State<ProjectsPage> {
  @override
  Widget build(BuildContext context) {
    List<Widget> list = [
      ProjectListTile(title: 'Test Project', description: 'Simple Description', icon: Icon(iconFromHashcode(1))),
      ProjectListTile(title: 'Test Project 2', icon: Icon(iconFromHashcode(2))),
      ProjectListTile(
          title: 'Test Project 3', description: 'Lorem Ipsum dolor sit amet consectetur lorem ipsum dolor sit amet', icon: Icon(iconFromHashcode(3))),
      ProjectListTile(title: 'Test Project 4', description: 'Simple Description', icon: Icon(iconFromHashcode(4))),
    ];
    return Material(
      color: Colors.transparent,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: i18n.projectPage.asTextWidget(
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            );
          }
          return list[index - 1];
        },
        separatorBuilder: (context, index) {
          return const SizedBox(height: 8);
        },
        itemCount: list.length + 1,
      ),
    );
  }
}
