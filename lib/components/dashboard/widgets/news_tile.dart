import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nodeflow/components/click_listener.dart';
import 'package:nodeflow/components/dashboard/dashboard.dart';
import 'package:nodeflow/router.dart';
import 'package:nodeflow/theme/compact_data.dart';

class NewsTile extends StatefulWidget {
  final String title;
  final String contentSnapshot;
  final String author; // must be from github!!!
  final int timestamp;
  final bool last;

  const NewsTile({
    Key? key,
    required this.title,
    required this.contentSnapshot,
    required this.author,
    required this.timestamp,
    this.last = false, // last means, we should show it as "and more..."
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NewsTileState();
  }
}

class _NewsTileState extends State<NewsTile> {
  String _formattedTimeStamp() {
    // format to Locale
    String localeName = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMEd(localeName).format(DateTime.fromMillisecondsSinceEpoch(widget.timestamp));
  }

  @override
  Widget build(BuildContext context) {
    Widget w = Container(
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
            enableFeedback: !widget.last,
            onTap: widget.last ? null : () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          _formattedTimeStamp(),
                          style: TextStyle(fontSize: 12, color: app.secondaryTextColor),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 8,
                              child: Image.network(
                                'https://github.com/${widget.author}.png',
                                isAntiAlias: true,
                                filterQuality: FilterQuality.high,
                                scale: 0.000001,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.author,
                                style: TextStyle(color: app.secondaryTextColor, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.arrow_forward_ios),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.last) {
      w = Stack(
        children: [
          w,
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    app.backgroundColor.withOpacity(0.5),
                    app.backgroundColor.withOpacity(1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ClickListener(
                behavior: HitTestBehavior.translucent,
                onClick: () {
                  context.replacePaths([KeyPath(pageChangeLogs.value)]);
                },
                child: Center(
                  child: Text(i18n.newsMore),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return w;
  }
}
