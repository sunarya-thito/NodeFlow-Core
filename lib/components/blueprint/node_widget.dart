import 'package:flutter/material.dart';
import 'package:nodeflow/components/blueprint/blueprint.dart';
import 'package:nodeflow/components/blueprint/port/circle_port.dart';
import 'package:nodeflow/components/widget_size_reporter.dart';
import 'package:nodeflow/theme/compact_data.dart';
import 'package:nodeflow/ui_util.dart';

import 'controller.dart';

class NodeWidget extends StatefulWidget {
  final BlueprintController controller;
  final BlueprintState blueprintState;
  final Size canvasSize;
  final Node node;
  final VoidCallback onNodeSelected;
  final void Function(Size size) sizeReporter;
  final Offset Function(Offset global) globalToLocal;
  final List<NodeParameter>? Function(NodeParameter parameter, PortType type) onLinkingStart;
  final void Function(NodeParameter parameter, PortType type, Offset end) onLinking;
  final void Function(NodeParameter parameter, PortType type) onLinkingCancel;
  final void Function(NodeParameter parameter, PortType type) onLinkingEnd;

  const NodeWidget({
    Key? key,
    required this.controller,
    required this.node,
    required this.canvasSize,
    required this.onNodeSelected,
    required this.sizeReporter,
    required this.globalToLocal,
    required this.onLinking,
    required this.onLinkingCancel,
    required this.onLinkingStart,
    required this.onLinkingEnd,
    required this.blueprintState,
  }) : super(key: key);

  @override
  _NodeWidgetState createState() => _NodeWidgetState();
}

class _ParameterWidget {
  final _ParameterWidget? previous;
  final NodeParameter parameter;
  final Widget widget;

  late final NodePortData inputData;
  late final NodePortData outputData;

  _ParameterWidget(this.previous, this.parameter, this.widget) {
    inputData = NodePortData(parameter, PortType.input);
    outputData = NodePortData(parameter, PortType.output);
  }

  double? _height;

  double computeTop() {
    if (previous == null) return 0;
    return previous!.computeTop() + previous!._height! + 1;
  }
}

class NodePortData {
  final NodeParameter source;
  final PortType type;

  List<NodeParameter>? target;
  NodePortData(this.source, this.type);
}

class _NodeWidgetState extends State<NodeWidget> {
  final List<_ParameterWidget> _parameterWidgets = [];

  @override
  void initState() {
    super.initState();
    _buildParameters();
    widget.node.addListener(_onNodeChanged);
  }

  void _onNodeChanged() {
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant NodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node != widget.node) {
      oldWidget.node.removeListener(_onNodeChanged);
      _buildParameters();
      widget.node.addListener(_onNodeChanged);
    }
  }

  @override
  void dispose() {
    widget.node.removeListener(_onNodeChanged);
    super.dispose();
  }

  void _buildParameters() {
    _parameterWidgets.clear();
    _ParameterWidget? previous;
    for (var group in widget.node.parameters) {
      for (var param in group.parameters) {
        late _ParameterWidget pw;
        Widget w = Builder(builder: (context) {
          return WidgetSizeReporter(
            onSizeChanged: (size) {
              pw._height = size.height;
              // add post frame callback to notify the link controller about the new size
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                setState(() {});
              });
            },
            child: param.provider.createWidget(param),
          );
        });
        _parameterWidgets.add(pw = previous = _ParameterWidget(previous, param, w));
      }
    }
  }

  double roundTo(double value, double step) {
    return (value / step).round() * step;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> parameterPorts = [];

    for (_ParameterWidget p in _parameterWidgets) {
      if (p.parameter.provider.hasInput && p._height != null) {
        Widget inputPort = Positioned(
          left: 9,
          top: p.computeTop() + p._height! / 2 - 5,
          child: Draggable<NodePortData>(
            data: p.inputData,
            feedback: Container(
              width: 5 * widget.controller.zoom * 2,
              height: 5 * widget.controller.zoom * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.parameter.provider.getInputColor(app.brightness) ?? app.executionColor,
              ),
            ),
            allowedButtonsFilter: (button) => button == 1,
            dragAnchorStrategy: (draggable, context, position) {
              return const Offset(5, 5) * widget.controller.zoom;
            },
            onDragStarted: () {
              var existing = widget.onLinkingStart(p.parameter, PortType.input);
              p.inputData.target = existing;
            },
            onDragUpdate: (details) {
              widget.blueprintState.handleDraggingCursor(details.globalPosition);
              widget.onLinking(p.parameter, PortType.input, widget.globalToLocal(details.globalPosition));
            },
            onDraggableCanceled: (velocity, offset) {
              widget.onLinkingCancel(p.parameter, PortType.input);
              p.inputData.target = null;
              widget.blueprintState.handleDraggingStop();
            },
            onDragEnd: (details) {
              if (details.wasAccepted) {
                widget.onLinkingEnd(p.parameter, PortType.input);
              } else {
                widget.onLinkingCancel(p.parameter, PortType.input);
              }
              widget.blueprintState.handleDraggingStop();
              p.inputData.target = null;
            },
            child: CirclePort(
              color: p.parameter.provider.getInputColor(app.brightness) ?? app.executionColor,
              highlightColor: widget.node.selected ? app.selectedNodeBorderColor : app.nodeBorderColor,
              radius: 5,
              highlight: true,
              globalPositionReporter: (position) {
                position = (widget.globalToLocal(position) - widget.controller.offset) / widget.controller.zoom - widget.canvasSize.center(Offset.zero);
                if (p.parameter.inputPosition == position) {
                  return;
                }
                p.parameter.inputPosition = position;
                widget.controller.linkController.notifyListeners();
              },
            ),
          ),
        );
        parameterPorts.add(inputPort);
      }
      if (p.parameter.provider.hasOutput && p._height != null) {
        Widget outputPort = Positioned(
          right: 9,
          top: p.computeTop() + p._height! / 2 - 5,
          child: Draggable<NodePortData>(
            data: p.outputData,
            allowedButtonsFilter: (button) => button == 1,
            dragAnchorStrategy: (draggable, context, position) {
              return const Offset(5, 5) * widget.controller.zoom;
            },
            onDragStarted: () {
              var existing = widget.onLinkingStart(p.parameter, PortType.output);
              p.outputData.target = existing;
            },
            onDragUpdate: (details) {
              widget.blueprintState.handleDraggingCursor(details.globalPosition);
              widget.onLinking(p.parameter, PortType.output, widget.globalToLocal(details.globalPosition));
            },
            onDraggableCanceled: (velocity, offset) {
              widget.onLinkingCancel(p.parameter, PortType.output);
              p.outputData.target = null;
              widget.blueprintState.handleDraggingStop();
            },
            onDragEnd: (details) {
              if (details.wasAccepted) {
                widget.onLinkingEnd(p.parameter, PortType.output);
              } else {
                widget.onLinkingCancel(p.parameter, PortType.output);
              }
              p.outputData.target = null;
              widget.blueprintState.handleDraggingStop();
            },
            feedback: Container(
              width: 5 * widget.controller.zoom * 2,
              height: 5 * widget.controller.zoom * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.parameter.provider.getInputColor(app.brightness) ?? app.executionColor,
              ),
            ),
            child: CirclePort(
              color: p.parameter.provider.getOutputColor(app.brightness) ?? app.executionColor,
              radius: 5,
              highlightColor: widget.node.selected ? app.selectedNodeBorderColor : app.nodeBorderColor,
              highlight: true,
              globalPositionReporter: (position) {
                position = (widget.globalToLocal(position) - widget.controller.offset) / widget.controller.zoom - widget.canvasSize.center(Offset.zero);
                if (p.parameter.outputPosition == position) {
                  return;
                }
                p.parameter.outputPosition = position;
                widget.controller.linkController.notifyListeners();
              },
            ),
          ),
        );
        parameterPorts.add(outputPort);
      }
      if ((p.parameter.provider.hasInput || p.parameter.provider.hasOutput) && p._height != null) {
        Row dragTargetContainer = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (p.parameter.provider.hasInput)
              Expanded(
                child: DragTarget<NodePortData>(
                  onWillAccept: (data) {
                    if (data == null) {
                      return false;
                    }
                    if (data.target != null) {
                      return data.type == PortType.input;
                    }
                    return data.type == PortType.output && data.source != p.parameter;
                  },
                  onAccept: (data) {
                    var target = data.target;
                    if (target != null) {
                      for (NodeParameter t in target) {
                        widget.controller.linkController.addLink(t, p.parameter);
                      }
                      return;
                    }
                    widget.controller.linkController.addLink(data.source, p.parameter);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return const SizedBox();
                    // return Container(
                    //   color: Colors.blue.withOpacity(0.2),
                    // );
                  },
                ),
              ),
            if (p.parameter.provider.hasOutput)
              Expanded(
                child: DragTarget<NodePortData>(
                  onWillAccept: (data) {
                    if (data == null) {
                      return false;
                    }
                    if (data.target != null) {
                      return data.type == PortType.output;
                    }
                    return data.type == PortType.input && data.source != p.parameter;
                  },
                  onAccept: (data) {
                    var target = data.target;
                    if (target != null) {
                      for (NodeParameter t in target) {
                        widget.controller.linkController.addLink(p.parameter, t);
                      }
                      return;
                    }
                    widget.controller.linkController.addLink(p.parameter, data.source);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return const SizedBox();
                    // return Container(
                    //   color: Colors.red.withOpacity(0.2),
                    // );
                  },
                ),
              ),
          ],
        );
        parameterPorts.add(Positioned(
          top: p.computeTop(),
          left: 0,
          right: 0,
          child: SizedBox(
            height: p._height!,
            child: dragTargetContainer,
          ),
        ));
      }
    }

    double? toGrid = widget.controller.snapToGrid;
    return Positioned(
      top: widget.controller.offset.dy + (widget.node.position.dy + widget.canvasSize.height / 2) * widget.controller.zoom,
      left: widget.controller.offset.dx + ((widget.node.position.dx - 15) + widget.canvasSize.width / 2) * widget.controller.zoom,
      child: Transform.scale(
        scale: widget.controller.zoom,
        alignment: Alignment.topLeft,
        origin: Offset.zero,
        child: WidgetSizeReporter(
          onSizeChanged: (size) {
            widget.sizeReporter(size - const Offset(30, 0) as Size);
          },
          child: FocusScope(
            onFocusChange: (value) {
              if (value) {
                widget.onNodeSelected();
              }
            },
            child: DefaultTextStyle(
              style: TextStyle(
                color: app.primaryTextColor,
                fontFamily: 'Inter',
                decoration: TextDecoration.none,
              ),
              child: GestureDetector(
                onTap: () {
                  widget.onNodeSelected();
                },
                onPanStart: (event) {
                  if (!widget.node.selected) {
                    widget.onNodeSelected();
                  }
                  // widget.controller.markAsDragging();
                },
                onPanUpdate: (event) {
                  // widget.node.position += event.delta;
                  widget.blueprintState.handleDraggingCursor(event.globalPosition, true)?.listen((event) {
                    widget.controller.shiftSelection(widget.node, -event / widget.controller.zoom);
                  });
                  widget.controller.shiftSelection(widget.node, event.delta);
                  // re-snap to grid
                },
                onPanEnd: (details) {
                  widget.blueprintState.handleDraggingStop();
                  // widget.controller.markAsUndragging();
                },
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          color: app.surfaceColor,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: widget.node.selected ? app.selectedNodeBorderColor : app.nodeBorderColor,
                            strokeAlign: BorderSide.strokeAlignOutside,
                            width: widget.node.selected ? 2 : 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: IntrinsicWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: joinWidgets(_parameterWidgets.map((e) => e.widget).toList(), () => const Divider()),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ...parameterPorts,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NodeFeedback extends StatefulWidget {
  final Offset Function(Offset) globalToLocal;
  final void Function(Offset position) onPositionChanged;
  final Widget child;

  const NodeFeedback({Key? key, required this.onPositionChanged, required this.child, required this.globalToLocal}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return NodeFeedbackState();
  }
}

/// NodeFeedback widget used as feedback for dragging node parameter's port
/// this widget constantly reports its position to the [onPositionChanged] callback
class NodeFeedbackState extends State<NodeFeedback> with SingleTickerProviderStateMixin {
  Offset? _lastPosition;
  late AnimationController _controller;

  void gatherPosition() {
    if (!mounted) {
      return;
    }
    RenderBox box = context.findRenderObject() as RenderBox;
    if (!box.hasSize) return;
    Offset position = widget.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
    if (_lastPosition == position) {
      return;
    }
    _lastPosition = position;
    widget.onPositionChanged(position);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16));
    _controller.addListener(() {
      gatherPosition();
    });
    _controller.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('didChangeDependencies');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NodeFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_lastPosition != null) {
      widget.onPositionChanged(_lastPosition!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
