import 'package:flutter/widgets.dart';

enum SplitPaneOrientation {
  horizontal,
  vertical,
}

class SplitPaneController extends ChangeNotifier {
  double _position;
  SplitPaneOrientation _orientation;
  bool _resizable;
  bool _reverse;

  SplitPaneState? _attachedState;

  SplitPaneController({
    double position = 0,
    SplitPaneOrientation orientation = SplitPaneOrientation.horizontal,
    bool resizable = true,
    bool reverse = false,
  })  : _position = position,
        _orientation = orientation,
        _resizable = resizable,
        _reverse = reverse;

  double get position => _position;
  SplitPaneOrientation get orientation => _orientation;
  bool get resizable => _resizable;
  bool get reverse => _reverse;

  void _attach(SplitPaneState state) {
    if (_attachedState != null) {
      throw Exception('SplitPaneController is already attached to a SplitPaneState');
    }
    _attachedState = state;
  }

  void _detach() {
    if (_attachedState == null) {
      throw Exception('SplitPaneController is not attached to a SplitPaneState');
    }
    _attachedState = null;
  }

  double _validatePosition(double position) {
    if (_attachedState != null) {
      final double? firstMinSize = _reverse ? _attachedState!.widget.second!.minSize : _attachedState!.widget.first!.minSize;
      final double? secondMinSize = _reverse ? _attachedState!.widget.first!.minSize : _attachedState!.widget.second!.minSize;
      final double? firstMaxSize = _reverse ? _attachedState!.widget.second!.maxSize : _attachedState!.widget.first!.maxSize;
      final double? secondMaxSize = _reverse ? _attachedState!.widget.first!.maxSize : _attachedState!.widget.second!.maxSize;
      final double size = _attachedState!._size;
      if (firstMinSize != null) {
        if (position < firstMinSize) {
          position = firstMinSize;
        }
      } else if (secondMinSize != null) {
        if (position > size - secondMinSize) {
          position = size - secondMinSize;
        }
      }
      if (firstMaxSize != null) {
        if (position > firstMaxSize) {
          position = firstMaxSize;
        }
      } else if (secondMaxSize != null) {
        if (position < size - secondMaxSize) {
          position = size - secondMaxSize;
        }
      }
      // check if position exceeds the slider bounds
      if (position < _attachedState!.widget.sliderSize / 2) {
        position = _attachedState!.widget.sliderSize / 2;
      } else if (position > size - _attachedState!.widget.sliderSize / 2) {
        position = size - _attachedState!.widget.sliderSize / 2;
      }
    }
    return position;
  }

  void _revalidatePosition() {
    var position = _validatePosition(_position);
    if (position != _position) {
      _position = position;
    }
  }

  set position(double position) {
    // reposition to respect min/max sizes of both first and second
    // if they both have minimum sizes, but the sum of their minimum sizes is greater than the total size, then we use only
    // the first's minimum size, same for maximum sizes
    // if only one has a minimum size, then we use that one
    _position = _validatePosition(position);
    notifyListeners();
  }

  set orientation(SplitPaneOrientation orientation) {
    if (_orientation == orientation) {
      return;
    }
    _orientation = orientation;
    notifyListeners();
  }

  set resizable(bool resizable) {
    if (_resizable == resizable) {
      return;
    }
    _resizable = resizable;
    notifyListeners();
  }

  set reverse(bool reverse) {
    if (_reverse == reverse) {
      return;
    }
    _reverse = reverse;
    notifyListeners();
  }
}

class SplitPane extends StatefulWidget {
  final SplitPaneController? controller;
  final SplitPaneItem? first;
  final SplitPaneItem? second;
  final double sliderSize;
  final Color? backgroundColor;

  const SplitPane({
    Key? key,
    this.controller,
    required this.first,
    required this.second,
    this.sliderSize = 6,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SplitPaneState();
  }
}

class SplitPaneItem {
  final Widget child;
  final double? minSize;
  final double? maxSize;

  const SplitPaneItem({
    required this.child,
    this.minSize,
    this.maxSize,
  });
}

class SplitPaneState extends State<SplitPane> {
  late SplitPaneController _controller;
  double _size = 0;

  void _update() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SplitPaneController();
    _controller._attach(this);
    _controller.addListener(_update);
  }

  @override
  void didUpdateWidget(covariant SplitPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_update);
      _controller._detach();
      _controller = widget.controller ?? SplitPaneController();
      _controller._attach(this);
      _controller.addListener(_update);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_update);
    _controller._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.second == null || widget.first == null) {
      return widget.first?.child ??
          widget.second?.child ??
          Container(
            color: widget.backgroundColor,
          );
    }
    return Container(
      color: widget.backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          double oldSize = _size;
          _size = _controller.orientation == SplitPaneOrientation.horizontal ? constraints.maxWidth : constraints.maxHeight;
          if (oldSize != _size) {
            _controller._revalidatePosition();
          }
          var gestureDetector = GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) {
              if (!_controller.resizable) {
                return;
              }
              if (_controller.reverse) {
                if (_controller.orientation == SplitPaneOrientation.horizontal) {
                  _controller.position -= details.delta.dx;
                } else {
                  _controller.position -= details.delta.dy;
                }
              } else {
                if (_controller.orientation == SplitPaneOrientation.horizontal) {
                  _controller.position += details.delta.dx;
                } else {
                  _controller.position += details.delta.dy;
                }
              }
            },
            child: MouseRegion(
              cursor: _controller.resizable
                  ? _controller.orientation == SplitPaneOrientation.horizontal
                      ? SystemMouseCursors.resizeLeftRight
                      : SystemMouseCursors.resizeUpDown
                  : MouseCursor.defer,
            ),
          );
          return Stack(
            children: [
              // first child
              !_controller.reverse
                  ? Positioned(
                      left: 0,
                      top: 0,
                      width: _controller.orientation == SplitPaneOrientation.horizontal ? _controller.position : constraints.maxWidth,
                      height: _controller.orientation == SplitPaneOrientation.vertical ? _controller.position : constraints.maxHeight,
                      child: widget.first!.child,
                    )
                  : Positioned(
                      left: 0,
                      top: 0,
                      width: _controller.orientation == SplitPaneOrientation.horizontal ? _size - _controller.position : constraints.maxWidth,
                      height: _controller.orientation == SplitPaneOrientation.vertical ? _size - _controller.position : constraints.maxHeight,
                      child: widget.first!.child,
                    ),
              // second child
              !_controller.reverse
                  ? Positioned(
                      right: 0,
                      bottom: 0,
                      width: _controller.orientation == SplitPaneOrientation.horizontal ? _size - _controller.position : constraints.maxWidth,
                      height: _controller.orientation == SplitPaneOrientation.vertical ? _size - _controller.position : constraints.maxHeight,
                      child: widget.second!.child,
                    )
                  : Positioned(
                      right: 0,
                      bottom: 0,
                      width: _controller.orientation == SplitPaneOrientation.horizontal ? _controller.position : constraints.maxWidth,
                      height: _controller.orientation == SplitPaneOrientation.vertical ? _controller.position : constraints.maxHeight,
                      child: widget.second!.child,
                    ),
              // Slider
              !_controller.reverse
                  ? Positioned(
                      left: _controller.orientation == SplitPaneOrientation.horizontal ? _controller.position - widget.sliderSize / 2 : 0,
                      top: _controller.orientation == SplitPaneOrientation.vertical ? _controller.position - widget.sliderSize / 2 : 0,
                      width: _controller.orientation == SplitPaneOrientation.horizontal ? widget.sliderSize : constraints.maxWidth,
                      height: _controller.orientation == SplitPaneOrientation.vertical ? widget.sliderSize : constraints.maxHeight,
                      child: gestureDetector,
                    )
                  : Positioned(
                      right: _controller.orientation == SplitPaneOrientation.horizontal ? _controller.position - widget.sliderSize / 2 : 0,
                      bottom: _controller.orientation == SplitPaneOrientation.vertical ? _controller.position - widget.sliderSize / 2 : 0,
                      width: _controller.orientation == SplitPaneOrientation.horizontal ? widget.sliderSize : constraints.maxWidth,
                      height: _controller.orientation == SplitPaneOrientation.vertical ? widget.sliderSize : constraints.maxHeight,
                      child: gestureDetector,
                    ),
            ],
          );
        },
      ),
    );
  }
}
