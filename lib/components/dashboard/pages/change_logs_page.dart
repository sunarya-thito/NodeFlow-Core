import 'package:flutter/material.dart';
import 'package:nodeflow/components/locale_widget.dart';

import '../widgets/news_tile.dart';

class ChangeLogsPage extends StatefulWidget {
  const ChangeLogsPage({Key? key}) : super(key: key);

  @override
  _ChangeLogsPageState createState() => _ChangeLogsPageState();
}

class _ChangeLogsPageState extends State<ChangeLogsPage> {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: 'Change Logs'.asTextWidget(
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    );
                  }
                  return news[index - 1];
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 8);
                },
                itemCount: news.length + 1),
          ),
        ],
      ),
    );
  }
}
