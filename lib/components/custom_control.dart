import 'package:flutter/material.dart';

enum ControlState {
  normal,
  hovered,
  focused,
  down,
  disabled;
}

class CustomControl extends StatefulWidget {
  final void Function()? onTap;
  final void Function(TapDownDetails)? onTapTertiary;
  final void Function(bool)? onHover;
  final void Function(bool)? onFocused;
  final MouseCursor cursor;
  final Widget Function(BuildContext context, ControlState state) builder;
  const CustomControl({
    Key? key,
    this.onTap,
    this.onHover,
    this.onFocused,
    required this.builder,
    this.cursor = SystemMouseCursors.click,
    this.onTapTertiary,
  }) : super(key: key);

  @override
  _CustomControlState createState() => _CustomControlState();
}

class _CustomControlState extends State<CustomControl> {
  bool _hovered = false;
  bool _down = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTapDown: (e) => setState(() => _down = true),
      onTertiaryTapDown: widget.onTapTertiary,
      child: MouseRegion(
        cursor: widget.onTap == null ? MouseCursor.defer : widget.cursor,
        onEnter: (e) {
          if (widget.onHover != null) widget.onHover!(true);
          setState(() => _hovered = true);
        },
        onExit: (e) {
          if (widget.onHover != null) widget.onHover!(false);
          setState(() => _hovered = false);
        },
        child: Focus(
            onFocusChange: (f) {
              if (widget.onFocused != null) widget.onFocused!(f);
              setState(() => _focused = f);
            },
            child: widget.builder(
                context,
                widget.onTap == null
                    ? ControlState.disabled
                    : _down
                        ? ControlState.down
                        : _hovered
                            ? ControlState.hovered
                            : _focused
                                ? ControlState.focused
                                : ControlState.normal)),
      ),
    );
  }
}
