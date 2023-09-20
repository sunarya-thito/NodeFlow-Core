import 'package:flutter/material.dart';
import 'package:nodeflow/components/dashboard/widgets/tutorial_item.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/theme/compact_data.dart';

class TutorialsPage extends StatefulWidget {
  const TutorialsPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TutorialsPageState();
  }
}

class _TutorialsPageState extends State<TutorialsPage> {
  @override
  Widget build(BuildContext context) {
    List<Widget> list = [
      TutorialItem(
        title: 'My Tutorial',
        author: 'sunarya-thito',
        imageUrl: 'https://i.ibb.co/KyWYyqd/2023-08-17-18-55-26.png',
        description: 'In this tutorial, we will learn how to create a simple project.',
      ),
      TutorialItem(title: 'My Second Tutorial', author: 'sunarya-thito'),
    ];
    return Material(
      color: Colors.transparent,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: i18n.tutorialPage.asTextWidget(
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
