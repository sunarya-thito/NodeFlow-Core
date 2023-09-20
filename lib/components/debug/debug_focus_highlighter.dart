import 'package:flutter/material.dart';

class DebugFocusHighlighter extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const DebugFocusHighlighter({Key? key, required this.child, this.enabled = true}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _DebugFocusHighlighterState();
  }
}

class _DebugFocusHighlighterState extends State<DebugFocusHighlighter> {
  Rect? rect;
  void _update() {
    if (mounted && widget.enabled) {
      setState(() {
        try {
          rect = FocusManager.instance.primaryFocus?.rect;
        } catch (e) {
          rect = null;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.enabled) FocusManager.instance.addListener(_update);
  }

  @override
  void didUpdateWidget(covariant DebugFocusHighlighter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        FocusManager.instance.addListener(_update);
      } else {
        FocusManager.instance.removeListener(_update);
      }
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (rect != null && widget.enabled)
          Positioned(
            left: rect!.left,
            top: rect!.top,
            width: rect!.width,
            height: rect!.height,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
