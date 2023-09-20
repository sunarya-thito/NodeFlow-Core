import 'package:flutter/material.dart';
import 'package:nodeflow/theme/compact_data.dart';

class TutorialItem extends StatefulWidget {
  final String title;
  final String? description;
  final String? imageUrl;
  final String author;

  const TutorialItem({
    Key? key,
    required this.title,
    this.description,
    this.imageUrl,
    required this.author,
  }) : super(key: key);

  @override
  _TutorialItemState createState() => _TutorialItemState();
}

class _TutorialItemState extends State<TutorialItem> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          if (widget.imageUrl != null)
            Positioned.fill(
              child: FittedBox(
                child: Image.network(widget.imageUrl!),
                fit: BoxFit.cover,
              ),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: widget.imageUrl == null ? app.surfaceColor : app.surfaceColor.withOpacity(0.8),
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
                                      style: TextStyle(fontSize: 12, color: app.secondaryTextColor),
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
                          icon: Icon(Icons.open_in_new),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
