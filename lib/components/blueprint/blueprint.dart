import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:nodeflow/devstage.dart';
import 'package:nodeflow/theme/compact_data.dart';
import 'package:nodeflow/ui_util.dart';

import 'blueprint_link_painter.dart';
import 'controller.dart';
import 'node_widget.dart';

class BlueprintThemeData {
  final Color backgroundColor;
  final double majorGridSpacing, minorGridSpacing;
  final Color majorGridColor, minorGridColor;
  final Color selectedNodeBorderColor;
  final Color executionColor;
  final Color selectionColor;
  final Color selectionBorderColor;
  final Color nodeErrorColor;
  final Color nodeWarningColor;
  final Color nodeBubbleColor;

  const BlueprintThemeData({
    required this.backgroundColor,
    required this.majorGridSpacing,
    required this.minorGridSpacing,
    required this.majorGridColor,
    required this.minorGridColor,
    required this.selectedNodeBorderColor,
    required this.executionColor,
    required this.selectionColor,
    required this.selectionBorderColor,
    required this.nodeErrorColor,
    required this.nodeWarningColor,
    required this.nodeBubbleColor,
  });
}

class BlueprintTheme extends InheritedWidget {
  final BlueprintThemeData data;

  const BlueprintTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  static BlueprintThemeData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BlueprintTheme>()!.data;
  }

  @override
  bool updateShouldNotify(covariant BlueprintTheme oldWidget) {
    return data != oldWidget.data;
  }
}

Offset getPositionForNewNode(List<Node> nodes) {
  // new nodes are placed next to the last node at the right
  if (nodes.isEmpty) return Offset.zero;
  Node rightNode = nodes.first;
  for (var node in nodes) {
    if (node.position.dx > rightNode.position.dx) rightNode = node;
  }
  return rightNode.position + const Offset(kNewNodeSpacing, 0);
}

class Blueprint extends StatefulWidget {
  final bool readOnly;
  final SelectionMode selectionMode;
  final SelectionRule selectionRule;

  const Blueprint({
    Key? key,
    this.readOnly = false,
    this.selectionMode = SelectionMode.select,
    this.selectionRule = SelectionRule.grabWhole,
  }) : super(key: key);

  @override
  BlueprintState createState() => BlueprintState();
}

const kDefaultZoom = 1.0;
const kDefaultOffset = Offset.zero;
const kCanvasPadding = 200.0;
const kNewNodeSpacing = 50.0;

class LinkAnchor {
  final Color color;
  final Offset offset;
  final List<Offset> bendPoints;

  const LinkAnchor(this.color, this.offset, this.bendPoints);
}

class LinkSnapshot {
  final Offset? cursor;
  final List<LinkAnchor> anchors;

  const LinkSnapshot(this.cursor, this.anchors);

  LinkSnapshot updatePosition(Offset cursor) {
    return LinkSnapshot(cursor, anchors);
  }
}

enum SelectionMode {
  select,
  group;
}

enum SelectionRule {
  grabPart, // will select if selection intersects with the selectable object
  grabWhole, // will select if selection is fully contained in the selectable object
}

class SelectionSnapshot {
  final Offset start;
  final Offset end;
  final SelectionMode mode;

  const SelectionSnapshot(this.start, this.end, this.mode);

  SelectionSnapshot updateStart(Offset start) {
    return SelectionSnapshot(start, end, mode);
  }

  SelectionSnapshot updateEnd(Offset end) {
    return SelectionSnapshot(start, end, mode);
  }
}

class BlueprintState extends State<Blueprint> with SingleTickerProviderStateMixin {
  late BlueprintController controller = BlueprintController();
  late Ticker ticker;

  LinkSnapshot? _linkSnapshot;

  double _log2(double n) {
    return log(n) / log(2);
  }

  @override
  void initState() {
    super.initState();

    ticker = createTicker((elapsed) {
      var draggingPoint = _draggingPoint;
      if (draggingPoint != null) {
        if (_size == null) return;
        draggingPoint = context.globalToLocal(draggingPoint);
        var size = _size!;
        double threshold = min(max(size.width / 20, size.height / 20), 50);
        var offset = controller.offset;
        var dx = 0.0, dy = 0.0;
        if (draggingPoint.dx < threshold) {
          var delta = threshold - draggingPoint.dx;
          dx = 1.0 * pow(2.0, _log2(delta) - 1).clamp(0, 20);
        } else if (draggingPoint.dx > size.width - threshold) {
          var delta = draggingPoint.dx - (size.width - threshold);
          dx = (-1.0 * pow(2.0, _log2(delta) - 1)).clamp(-20, 0);
        }
        if (draggingPoint.dy < threshold) {
          var delta = threshold - draggingPoint.dy;
          dy = 1.0 * pow(2.0, _log2(delta) - 1).clamp(0, 20);
        } else if (draggingPoint.dy > size.height - threshold) {
          var delta = draggingPoint.dy - (size.height - threshold);
          dy = (-1.0 * pow(2.0, _log2(delta) - 1)).clamp(-20, 0);
        }
        _draggingCursor?.add(Offset(dx, dy));
        if (dx != 0 || dy != 0) {
          controller.offset = offset + Offset(dx, dy);
        }
      } else {
        ticker.stop();
      }
    });
    ticker.start();
    NodeProviderCategory category = NodeProviderCategory('testCategory', 'testCategoryDescription');

    controller.nodeController.addNode(TestProvider('test', 'name', 'description', category), position: const Offset(100, 100));
    controller.nodeController.addNode(TestProvider('test', 'name', 'description', category), position: const Offset(100, -100));
    controller.nodeController.addNode(TestProvider('test', 'name', 'description', category));
    // controller.nodeController
    //     .addNode(FieldAccessNodeProvider(JavaField('test', JavaClass('java.lang.Object', null, []), 0), 'test', 'testName', 'testDescription', category));
    // controller.nodeController.addNode(
    //     FieldAccessNodeProvider(JavaField('test', JavaClass('java.lang.Object', null, []), 0), 'test12', 'testName', 'testDescription', category),
    //     name: 'Testtest',
    //     position: const Offset(150, 100));
    // var link = controller.linkController
    //     .addLink(controller.nodeController.nodes[0].parameters[0].parameters[0], controller.nodeController.nodes[1].parameters[1].parameters[0]);
    // // link.addBendPoint(Bendpoint(50, 100));
    controller.addListener(update);
    _focusScopeNode = FocusNode(
      onKey: (node, event) {
        // check shift for _isMultiselecting
        if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
          if (event is RawKeyDownEvent) {
            controller.multiSelect = true;
            return KeyEventResult.handled;
          } else if (event is RawKeyUpEvent) {
            controller.multiSelect = false;
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
  }

  StreamController<Offset>? _draggingCursor;
  Offset? _draggingPoint;

  Stream<Offset>? handleDraggingCursor(Offset global, [bool enableDragListener = false]) {
    _draggingPoint = global;
    if (enableDragListener) _draggingCursor = StreamController<Offset>();
    if (!ticker.isActive) ticker.start();
    return _draggingCursor?.stream;
  }

  void handleDraggingStop() {
    _draggingCursor?.close();
    _draggingCursor = null;
    _draggingPoint = null;
  }

  @override
  void dispose() {
    controller.removeListener(update);
    ticker.dispose();
    super.dispose();
  }

  void update() {
    if (!mounted) return;
    setState(() {});
  }

  Offset _zoomOrigin = Offset.zero;
  bool _isDragging = false;
  bool _isZooming = false;
  Size? _size;

  late final FocusNode _focusScopeNode; // TODO move to widget's parameter

  bool _ignoreBackground = false;
  bool _isSelecting = false;

  final ValueNotifier<SelectionSnapshot?> _selectionSnapshot = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = constraints.biggest;
      return Container(
        decoration: BoxDecoration(
          color: BlueprintTheme.of(context).backgroundColor,
        ),
        child: GestureDetector(
          onTap: () {
            controller.clearSelection();
          },
          onPanStart: (details) {
            _isSelecting = true;
          },
          onPanUpdate: (event) {
            if (_isSelecting) {
              if (_selectionSnapshot.value == null) {
                _selectionSnapshot.value = SelectionSnapshot(event.localPosition, event.localPosition, widget.selectionMode);
              } else {
                _selectionSnapshot.value = _selectionSnapshot.value!.updateEnd(event.localPosition);
              }
              handleDraggingCursor(event.globalPosition, true)?.listen((event) {
                if (_selectionSnapshot.value != null) {
                  _selectionSnapshot.value = _selectionSnapshot.value!.updateStart(_selectionSnapshot.value!.start + event);
                }
              });
            }
          },
          onPanEnd: (details) {
            if (_selectionSnapshot.value != null) {
              if (widget.selectionMode == SelectionMode.select) {
                var sel = _selectionSnapshot.value!;
                Offset start = (sel.start - controller.offset) / controller.zoom - _size!.center(Offset.zero);
                Offset end = (sel.end - controller.offset) / controller.zoom - _size!.center(Offset.zero);
                var selectables = controller.findSelectables(Rect.fromPoints(start, end), widget.selectionRule);
                controller.selectAll(selectables);
              }
              handleDraggingStop();
              _selectionSnapshot.value = null;
            }
            _isSelecting = false;
          },
          onPanCancel: () {
            if (_selectionSnapshot.value != null) {
              _selectionSnapshot.value = null;
            }
            _isSelecting = false;
          },
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                Offset zoomOrigin = event.localPosition;
                double delta = (-event.scrollDelta.dy + -event.scrollDelta.dx) / 2;
                double prevZoom = controller.zoom;
                controller.zoom = (controller.zoom + delta / 400).clamp(0.5, 2.5);
                if (controller.zoom == prevZoom) return;
                // readjust offset to keep zoom origin in place
                controller.offset = zoomOrigin - (zoomOrigin - controller.offset) * controller.zoom / (controller.zoom - delta / 400);
              }
            },
            onPointerDown: (event) {
              _focusScopeNode.requestFocus();
              if (event.buttons == 4) {
                _isDragging = true;
              } else if (event.buttons == 2) {
                _zoomOrigin = event.localPosition;
                _isZooming = true;
              }
            },
            onPointerUp: (event) {
              _isDragging = false;
              _isZooming = false;
            },
            onPointerCancel: (event) {
              _isDragging = false;
              _isZooming = false;
            },
            onPointerMove: (event) {
              if (_isDragging) {
                controller.offset += event.delta;
              } else if (_isZooming) {
                double delta = (event.delta.dy + event.delta.dx) / 2;
                double prevZoom = controller.zoom;
                controller.zoom = (controller.zoom + delta / 100).clamp(0.5, 2.5);
                if (controller.zoom == prevZoom) return;
                // readjust offset to keep zoom origin in place
                controller.offset = _zoomOrigin - (_zoomOrigin - controller.offset) * controller.zoom / (controller.zoom - delta / 100);
              }
            },
            child: FocusableActionDetector(
              focusNode: _focusScopeNode,
              onFocusChange: (value) {
                if (!value) controller.multiSelect = false;
              },
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) {
                      return IgnorePointer(
                        ignoring: _ignoreBackground,
                        child: ClipRect(
                          child: CustomPaint(
                            painter: BlueprintBackgroundPainter(
                              theme: BlueprintTheme.of(context),
                              zoom: controller.zoom,
                              offset: controller.offset,
                            ),
                            foregroundPainter: _linkSnapshot == null ? null : LinkSnapshotPainter(_linkSnapshot!, controller),
                            child: BlueprintLinkLayer(controller: controller, brightness: app.brightness, blueprintState: this),
                          ),
                        ),
                      );
                    },
                  ),
                  OverlayEntry(
                    builder: (context) {
                      return Listener(
                        onPointerDown: (event) {
                          setState(() {
                            _ignoreBackground = true;
                          });
                        },
                        onPointerUp: (event) {
                          setState(() {
                            _ignoreBackground = false;
                          });
                        },
                        onPointerCancel: (event) {
                          setState(() {
                            _ignoreBackground = false;
                          });
                        },
                        child: LayoutBuilder(builder: (context, constraints) {
                          return Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: controller.nodeController.nodes
                                .map((e) => NodeWidget(
                                      controller: controller,
                                      blueprintState: this,
                                      onLinkingStart: (parameter, type) {
                                        if (!controller.multiSelect) {
                                          List<NodeLink> existing = [];
                                          for (NodeLink link in controller.linkController.links) {
                                            if ((type == PortType.input && link.to == parameter) || (type == PortType.output && link.from == parameter)) {
                                              existing.add(link);
                                            }
                                          }
                                          if (existing.isNotEmpty) {
                                            controller.linkController.removeLinks(existing);
                                            _linkSnapshot = LinkSnapshot(
                                                null,
                                                existing.map((e) {
                                                  return LinkAnchor(
                                                      (type == PortType.input
                                                              ? e.from.provider.getInputColor(app.brightness)
                                                              : e.to.provider.getOutputColor(app.brightness)) ??
                                                          app.executionColor,
                                                      (type == PortType.input ? e.from.outputPosition : e.to.inputPosition) ?? Offset.zero,
                                                      []);
                                                }).toList());
                                            setState(() {});
                                            return existing.map((e) => type == PortType.input ? e.from : e.to).toList();
                                          }
                                        }
                                        _linkSnapshot = LinkSnapshot(null, [
                                          LinkAnchor(
                                              (type == PortType.input
                                                      ? parameter.provider.getInputColor(app.brightness)
                                                      : parameter.provider.getOutputColor(app.brightness)) ??
                                                  app.executionColor,
                                              (type == PortType.input ? parameter.inputPosition : parameter.outputPosition) ?? Offset.zero,
                                              [])
                                        ]);
                                        setState(() {});
                                        return null;
                                      },
                                      onLinkingCancel: (parameter, type) {
                                        setState(() {
                                          _linkSnapshot = null;
                                        });
                                      },
                                      onLinking: (parameter, type, end) {
                                        setState(() {
                                          _linkSnapshot = _linkSnapshot!.updatePosition(end);
                                        });
                                      },
                                      onLinkingEnd: (parameter, type) {
                                        setState(() {
                                          _linkSnapshot = null;
                                        });
                                      },
                                      sizeReporter: (size) {
                                        e.size = size;
                                      },
                                      node: e,
                                      canvasSize: constraints.biggest,
                                      globalToLocal: context.globalToLocal,
                                      onNodeSelected: () {
                                        controller.select(e);
                                      },
                                    ))
                                .toList(),
                          );
                        }),
                      );
                    },
                  ),
                  if (widget.selectionMode == SelectionMode.select)
                    OverlayEntry(
                      builder: (context) {
                        return ValueListenableBuilder(
                          valueListenable: _selectionSnapshot,
                          builder: (context, value, child) {
                            if (value == null) return const SizedBox();
                            Offset position = Offset(
                              min(value.start.dx, value.end.dx),
                              min(value.start.dy, value.end.dy),
                            );
                            Offset end = Offset(
                              max(value.start.dx, value.end.dx),
                              max(value.start.dy, value.end.dy),
                            );
                            BlueprintThemeData theme = BlueprintTheme.of(context);
                            return IgnorePointer(
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: position.dy,
                                    left: position.dx,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme.selectionColor,
                                        border: Border.all(color: theme.selectionBorderColor, width: 1),
                                      ),
                                      width: end.dx - position.dx,
                                      height: end.dy - position.dy,
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  OverlayEntry(
                    builder: (context) {
                      return IgnorePointer(
                        child: CustomPaint(
                          painter: BlueprintForegroundPainter(
                            borderColor: _focusScopeNode.hasFocus ? app.focusedSurfaceColor : null,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class BlueprintForegroundPainter extends CustomPainter {
  Color? borderColor;

  BlueprintForegroundPainter({this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (borderColor == null) return;
    final paint = Paint()..color = borderColor!;

    // draw manually per sides
    const double thickness = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, thickness), paint);
    canvas.drawRect(Rect.fromLTWH(0, 0, thickness, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - thickness, 0, thickness, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(0, size.height - thickness - 1, size.width, thickness), paint);
  }

  @override
  bool shouldRepaint(covariant BlueprintForegroundPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor;
  }
}

class BlueprintBackgroundPainter extends CustomPainter {
  final BlueprintThemeData theme;
  final double zoom;
  final Offset offset;

  const BlueprintBackgroundPainter({
    required this.theme,
    this.zoom = kDefaultZoom,
    this.offset = kDefaultOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double zoom = this.zoom;
    final paint = Paint()
      ..color = theme.minorGridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final majorPaint = Paint()
      ..color = theme.majorGridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    zoom = zoom.clamp(0.1, 5);

    final majorGridSpacing = theme.majorGridSpacing * zoom;
    final minorGridSpacing = theme.minorGridSpacing * zoom;

    Offset offset = this.offset + size.center(Offset.zero) * zoom;

    final leftGrid = offset.dx % majorGridSpacing - majorGridSpacing;
    final topGrid = offset.dy % majorGridSpacing - majorGridSpacing;
    final rightGrid = size.width;
    final bottomGrid = size.height;

    for (var x = leftGrid; x <= rightGrid; x += minorGridSpacing) {
      if ((x - leftGrid) % majorGridSpacing == 0) continue;
      canvas.drawLine(
        Offset(x, topGrid),
        Offset(x, bottomGrid),
        paint,
      );
    }

    for (var y = topGrid; y <= bottomGrid; y += minorGridSpacing) {
      // if y is a major grid line, skip it
      if ((y - topGrid) % majorGridSpacing == 0) continue;
      canvas.drawLine(
        Offset(leftGrid, y),
        Offset(rightGrid, y),
        paint,
      );
    }

    for (var x = leftGrid; x <= rightGrid; x += majorGridSpacing) {
      canvas.drawLine(
        Offset(x, topGrid),
        Offset(x, bottomGrid),
        majorPaint,
      );
    }

    for (var y = topGrid; y <= bottomGrid; y += majorGridSpacing) {
      canvas.drawLine(
        Offset(leftGrid, y),
        Offset(rightGrid, y),
        majorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BlueprintBackgroundPainter oldDelegate) {
    return oldDelegate.theme != theme || oldDelegate.zoom != zoom || oldDelegate.offset != offset;
  }
}

class LinkSnapshotPainter extends CustomPainter {
  final BlueprintController controller;
  final LinkSnapshot snapshot;

  LinkSnapshotPainter(this.snapshot, this.controller);

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshot.cursor == null) return;
    for (LinkAnchor anchor in snapshot.anchors) {
      final paint = Paint()
        ..color = anchor.color
        ..strokeWidth = 2 * controller.zoom
        ..style = PaintingStyle.stroke;
      var offset = anchor.offset;
      offset = controller.offset + (offset + size.center(Offset.zero)) * controller.zoom;
      canvas.drawLine(snapshot.cursor!, offset, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LinkSnapshotPainter oldDelegate) {
    return oldDelegate.snapshot != snapshot || oldDelegate.controller != controller;
  }
}
