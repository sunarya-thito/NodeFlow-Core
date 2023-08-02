import 'package:flutter/material.dart';
import 'package:nodeflow/theme/compact_data.dart';

class Breadcrumbs extends StatefulWidget {
  final List<Widget> children;

  const Breadcrumbs({
    Key? key,
    required this.children,
  }) : super(key: key);

  @override
  _BreadcrumbsState createState() => _BreadcrumbsState();
}

class _BreadcrumbsState extends State<Breadcrumbs> {
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: 'Inter',
        color: app.primaryTextColor,
        fontSize: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < widget.children.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: widget.children[i],
                ),
                if (i < widget.children.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Container(
                      width: 6,
                      child: CustomPaint(
                        painter: _CustomBreadcrumbsArrowPainter(
                          color: app.breadcrumbSeparatorColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CustomBreadcrumbsArrowPainter extends CustomPainter {
  final Color color;

  const _CustomBreadcrumbsArrowPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CustomBreadcrumbsArrowPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
