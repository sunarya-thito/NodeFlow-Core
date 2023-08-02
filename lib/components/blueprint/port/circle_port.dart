import 'package:flutter/material.dart';

class CirclePort extends StatefulWidget {
  final double radius;
  final Color color, highlightColor;
  final bool highlight;
  final void Function(Offset) globalPositionReporter;

  const CirclePort({
    Key? key,
    required this.radius,
    required this.color,
    required this.highlight,
    required this.highlightColor,
    required this.globalPositionReporter,
  }) : super(key: key);

  @override
  _CirclePortState createState() => _CirclePortState();
}

class _CirclePortState extends State<CirclePort> {
  void _getGlobalPosition() {
    if (!mounted) return;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.localToGlobal(const Offset(5, 5));
    widget.globalPositionReporter(localPosition);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _getGlobalPosition());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _getGlobalPosition());
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _getGlobalPosition());
    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      child: CustomPaint(
        painter: CirclePortPainter(
          color: widget.color,
          highlight: widget.highlight,
          highlightColor: widget.highlightColor,
        ),
      ),
    );
  }
}

class CirclePortPainter extends CustomPainter {
  final Color color, highlightColor;
  final bool highlight;
  CirclePortPainter({
    required this.color,
    required this.highlight,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, fillPaint);
    if (highlight) {
      final strokePaint = Paint()
        ..color = highlightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      const double expansion = 0;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2 + expansion, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CirclePortPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.highlight != highlight;
  }
}
