import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/ui_util.dart';

import '../../hotkey.dart';
import '../../theme/compact_data.dart';

class TooltipWrapper extends StatefulWidget {
  // predefined tooltip styles
  static Widget Function(BuildContext) defaultTooltip(String label) {
    return (context) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: DefaultTextStyle(
          style: TextStyle(color: CompactData.of(context).theme.tooltipPrimaryTextColor, fontSize: 12, fontFamily: 'Inter'),
          child: label.asTextWidget(),
        ),
      );
    };
  }

  static Widget Function(BuildContext) descriptiveTooltip(String label, String description) {
    return (context) {
      return Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle(
                style: TextStyle(color: CompactData.of(context).theme.tooltipPrimaryTextColor, fontSize: 12, fontFamily: 'Inter'),
                child: label.asTextWidget(),
              ),
              const SizedBox(height: 4),
              DefaultTextStyle(
                style: TextStyle(color: CompactData.of(context).theme.tooltipSecondaryTextColor, fontSize: 12, fontFamily: 'Inter'),
                child: description.asTextWidget(),
              ),
            ],
          ));
    };
  }

  static Widget Function(BuildContext) actionTooltip(String label, String? description, Widget? icon, ShortcutKey? keybind) {
    return (context) {
      return Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              if (icon != null)
                IconTheme(
                  data: IconThemeData(size: 18, color: CompactData.of(context).theme.tooltipPrimaryTextColor),
                  child: icon,
                ),
              if (icon != null) const SizedBox(width: 8),
              IntrinsicWidth(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DefaultTextStyle(
                          style: TextStyle(color: CompactData.of(context).theme.tooltipPrimaryTextColor, fontSize: 12, fontFamily: 'Inter'),
                          child: label.asTextWidget(),
                        ),
                      ),
                      if (keybind != null) const SizedBox(width: 32),
                      if (keybind != null)
                        Text(keybind.toString(),
                            style: TextStyle(decoration: TextDecoration.none, color: CompactData.of(context).theme.tooltipSecondaryTextColor, fontSize: 12)),
                    ],
                  ),
                  if (description != null) const SizedBox(height: 4),
                  if (description != null)
                    DefaultTextStyle(
                      style: TextStyle(color: CompactData.of(context).theme.tooltipSecondaryTextColor, fontSize: 12, fontFamily: 'Inter'),
                      child: description.asTextWidget(),
                    ),
                ],
              )),
            ],
          ));
    };
  }

  final Widget Function(BuildContext context) tooltip;
  final Widget child;
  const TooltipWrapper({Key? key, required this.child, required this.tooltip}) : super(key: key);

  @override
  _TooltipWrapperState createState() => _TooltipWrapperState();
}

class _TooltipWrapperState extends State<TooltipWrapper> {
  static const int _tooltipDelay = 500;
  bool _shown = false;
  bool _hovered = false;
  OverlayEntry? _overlayEntry;

  ValueNotifier<Offset> position = ValueNotifier(Offset.zero);

  final FocusScopeNode _focusScopeNode = FocusScopeNode();

  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
    hide();
    super.dispose();
  }

  void _handlePointerEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      if (_shown) {
        hide();
      }
    }
  }

  Size _tooltipSize = Size.zero;

  void show(BuildContext context) {
    if (_overlayEntry != null || !mounted) {
      return;
    }
    _shown = true;
    _overlayEntry = OverlayEntry(builder: (context) {
      var size = context.localSize;
      if (size != _tooltipSize) {
        _tooltipSize = size;
        updatePosition(context, position.value);
      }
      return Positioned(
        left: position.value.dx,
        top: position.value.dy,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: app.tooltipBackgroundColor,
              border: Border.all(color: app.tooltipBorderColor),
            ),
            child: widget.tooltip(context),
          ),
        ),
      );
    });
    Overlay.of(context).insert(_overlayEntry!);
  }

  void updatePosition(BuildContext context, Offset globalPosition) {
    // clamp the global position to the screen
    var size = _tooltipSize;
    final Offset endPosition = globalPosition + Offset(size.width + 16, size.height + 16);
    final Size screenSize = MediaQuery.of(context).size;
    if (endPosition.dx > screenSize.width) {
      globalPosition = globalPosition + Offset(screenSize.width - endPosition.dx, 0);
    }
    if (endPosition.dy > screenSize.height) {
      globalPosition = globalPosition + Offset(0, screenSize.height - endPosition.dy);
    }
    position.value = globalPosition;
    if (_overlayEntry == null) {
      return;
    }
    _overlayEntry!.markNeedsBuild();
  }

  void hide() {
    if (_overlayEntry == null) {
      return;
    }
    _shown = false;
    _overlayEntry!.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        updatePosition(context, event.position + const Offset(16, 16));
        if (!_hovered) {
          _hovered = true;
          Future.delayed(const Duration(milliseconds: _tooltipDelay), () {
            if (_hovered && !_shown && mounted && !_focusScopeNode.hasFocus) {
              show(context);
            }
          });
        }
      },
      onHover: (event) {
        updatePosition(context, event.position + const Offset(16, 16));
      },
      onExit: (event) {
        _hovered = false;
        if (_shown) {
          hide();
        }
      },
      child: FocusScope(
        node: _focusScopeNode,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            hide();
          }
        },
        child: Listener(
          onPointerDown: (event) {
            _hovered = false;
            hide();
          },
          child: widget.child,
        ),
      ),
    );
  }
}
