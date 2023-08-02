import 'package:flutter/material.dart';

class ExecutionPort extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final bool highlight;

  const ExecutionPort({
    Key? key,
    required this.width,
    required this.height,
    required this.color,
    required this.highlight,
  }) : super(key: key);

  @override
  _ExecutionPortState createState() => _ExecutionPortState();
}

class _ExecutionPortState extends State<ExecutionPort> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: ExecutionPortPainter(
          color: widget.color,
          highlight: widget.highlight,
        ),
      ),
    );
  }
}

class ExecutionPortPainter extends CustomPainter {
  final Color color;
  final bool highlight;
  ExecutionPortPainter({
    required this.color,
    required this.highlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // create rhombus like arrow
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 3 / 5, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width * 3 / 5, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, fillPaint);

    if (highlight) {
      final highlightPaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      const double expansion = 3;
      final highlightPath = Path()
        ..moveTo(0 - expansion, 0 - expansion)
        ..lineTo(size.width * 3 / 5 + expansion * 3 / 5, 0 - expansion)
        ..lineTo(size.width + expansion * 7 / 5, size.height / 2)
        ..lineTo(size.width * 3 / 5 + expansion * 3 / 5, size.height + expansion)
        ..lineTo(0 - expansion, size.height + expansion)
        ..close();
      canvas.drawPath(highlightPath, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ExecutionPortPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.highlight != highlight;
  }
}
