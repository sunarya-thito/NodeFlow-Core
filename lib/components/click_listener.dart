import 'package:flutter/material.dart';

class ClickListener extends StatefulWidget {
  final HitTestBehavior behavior;
  final VoidCallback? onClick;
  final VoidCallback? onDoubleClick;
  final VoidCallback? onRightClick;
  final VoidCallback? onMiddleClick;
  final Widget child;

  const ClickListener({
    Key? key,
    this.behavior = HitTestBehavior.deferToChild,
    this.onClick,
    this.onDoubleClick,
    this.onRightClick,
    this.onMiddleClick,
    required this.child,
  }) : super(key: key);

  @override
  _ClickListenerState createState() => _ClickListenerState();
}

class _ClickListenerState extends State<ClickListener> {
  static const int maxDoubleClickDelay = 300;
  int _lastClick = -1;
  int _clickCount = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        int now = DateTime.now().millisecondsSinceEpoch;
        if (_lastClick == -1 || now - _lastClick < maxDoubleClickDelay) {
          _clickCount++;
        }
        if (_clickCount == 2) {
          _clickCount = 1;
          widget.onDoubleClick?.call();
        } else {
          widget.onClick?.call();
        }
        _lastClick = DateTime.now().millisecondsSinceEpoch;
      },
      onSecondaryTap: widget.onRightClick,
      onTertiaryTapDown: (_) => widget.onMiddleClick?.call(),
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction(
            onInvoke: (_) => widget.onClick?.call(),
          ),
        },
        child: widget.child,
      ),
    );
  }
}
