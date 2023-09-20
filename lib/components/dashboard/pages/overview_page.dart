import 'package:flutter/material.dart';
import 'package:nodeflow/components/dashboard/widgets/news_tile.dart';
import 'package:nodeflow/components/dashboard/widgets/project_tile.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/router.dart';

import '../dashboard.dart';
import '../widgets/more_projects_tile.dart';
import '../widgets/new_project_tile.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({Key? key}) : super(key: key);

  @override
  _OverviewPageState createState() => _OverviewPageState();
}

// with keep alive
class _OverviewPageState extends State<OverviewPage> {
  @override
  Widget build(BuildContext context) {
    List<Widget> news = [
      NewsTile(title: 'NodeFlow 3', contentSnapshot: 'Whats new in NodeFlow 3?', author: 'sunarya-thito', timestamp: DateTime.now().millisecondsSinceEpoch),
      NewsTile(title: 'NodeFlow 2', contentSnapshot: 'Whats new in NodeFlow 3?', author: 'sunarya-thito', timestamp: DateTime.now().millisecondsSinceEpoch),
      NewsTile(title: 'NodeFlow Alpha', contentSnapshot: 'Whats new in NodeFlow 3?', author: 'sunarya-thito', timestamp: DateTime.now().millisecondsSinceEpoch),
      NewsTile(
          title: 'NodeFlow Closed-Beta',
          contentSnapshot: 'Whats new in NodeFlow 3?',
          author: 'sunarya-thito',
          timestamp: DateTime.now().millisecondsSinceEpoch),
      NewsTile(
          title: 'NodeFlow Job Openings',
          contentSnapshot: 'Whats new in NodeFlow 3?',
          author: 'sunarya-thito',
          timestamp: DateTime.now().millisecondsSinceEpoch),
      NewsTile(
          last: true,
          title: 'NodeFlow',
          contentSnapshot: 'Whats new in NodeFlow 3?',
          author: 'sunarya-thito',
          timestamp: DateTime.now().millisecondsSinceEpoch),
    ];
    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                'Recent Projects'.asTextWidget(
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                Spacer(),
                TextButton(
                    onPressed: () {
                      context.replacePaths([KeyPath(pageMyProjects.value)]);
                    },
                    child: 'View All'.asTextWidget()),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ProjectTile(
                    title:
                        'Project 1 This is a long text that is more than 24 characters and should wrap more than the widget height cause its really really long'),
                ProjectTile(title: 'Project 2'),
                ProjectTile(title: 'Project 3'),
                ProjectTile(title: 'Project 4'),
                MoreProjectsTile(),
                NewProjectTile(),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                'News Feed'.asTextWidget(
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                Spacer(),
                TextButton(
                    onPressed: () {
                      context.replacePaths([KeyPath(pageChangeLogs.value)]);
                    },
                    child: 'View All'.asTextWidget()),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              // TODO do not use shrinkWrap, instead, replace this with a ListView combined with this
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return news[index];
              },
              separatorBuilder: (context, index) {
                return const SizedBox(height: 8);
              },
              itemCount: news.length,
            )
          ],
        ),
      ),
    );
  }
}
