import 'dart:math';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:nodeflow/components/blueprint/blueprint.dart';
import 'package:nodeflow/theme/compact_data.dart';
import 'package:nodeflow/ui_util.dart';

import 'controller.dart';

class BlueprintLinkLayer extends StatefulWidget {
  final BlueprintController controller;
  final BlueprintState blueprintState;
  final Brightness brightness;

  const BlueprintLinkLayer({
    super.key,
    required this.controller,
    required this.blueprintState,
    required this.brightness,
  });

  @override
  _BlueprintLinkLayerState createState() => _BlueprintLinkLayerState();
}

(int, Offset) _closestPointOnLine(int index, Offset start, Offset end, Offset point) {
  double a = point.dx - start.dx;
  double b = point.dy - start.dy;
  double c = end.dx - start.dx;
  double d = end.dy - start.dy;
  double dot = a * c + b * d;
  double lenSq = c * c + d * d;
  double param = dot / lenSq;
  double xx, yy;
  if (param < 0 || (start.dx == end.dx && start.dy == end.dy)) {
    xx = start.dx;
    yy = start.dy;
  } else if (param > 1) {
    xx = end.dx;
    yy = end.dy;
  } else {
    xx = start.dx + param * c;
    yy = start.dy + param * d;
  }
  var offset = Offset(xx, yy);
  return (index, offset);
}

double _distanceToLine(Offset start, Offset end, Offset point) {
  double a = point.dx - start.dx;
  double b = point.dy - start.dy;
  double c = end.dx - start.dx;
  double d = end.dy - start.dy;
  double dot = a * c + b * d;
  double lenSq = c * c + d * d;
  double param = dot / lenSq;
  double xx, yy;
  if (param < 0 || (start.dx == end.dx && start.dy == end.dy)) {
    xx = start.dx;
    yy = start.dy;
  } else if (param > 1) {
    xx = end.dx;
    yy = end.dy;
  } else {
    xx = start.dx + param * c;
    yy = start.dy + param * d;
  }
  double dx = point.dx - xx;
  double dy = point.dy - yy;
  return sqrt(dx * dx + dy * dy);
}

class _BlueprintLinkLayerState extends State<BlueprintLinkLayer> with SingleTickerProviderStateMixin {
  List<NodeLink> get links => widget.controller.linkController.links;
  late double tick;
  late Ticker ticker;
  Duration lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    tick = 0;
    ticker = createTicker((elapsed) {
      bool refresh = false;
      for (final l in links) {
        var link = l.state;
        if (link.isHovering && link.arrowSize < 1) {
          link.arrowSize += 0.1;
        } else if (link.arrowSize > 0) {
          link.arrowSize -= 0.1;
        }
        if (link.arrowSize > 0) refresh = true;
      }
      if (!refresh) {
        ticker.stop();
        return;
      }
      setState(() {
        _handleDrag();
        tick += (elapsed - lastTick).inMilliseconds / 16; // 60 fps
      });
      lastTick = elapsed;
    });
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  bool _pointerDown = false;
  PointerDownEvent? _pointerTapHandle;
  bool _dragging = false;
  Offset? _draggingPoint;
  int? _draggingIndex;

  void _checkMousePosition(Offset globalPos) {
    for (final link in links) {
      if (link.from.outputPosition == null || link.to.inputPosition == null) continue;
      List<Offset> linePoints = [link.from.outputPosition!, ...link.bendPoints.map((e) => e.offset), link.to.inputPosition!];
      for (int i = 0; i < linePoints.length - 1; i++) {
        var start = linePoints[i];
        var end = linePoints[i + 1];
        var distance = _distanceToLine(start, end, globalPos);
        if (distance < (link.state.isHovering ? 3 : 2) * widget.controller.zoom + 4) {
          (int, Offset) closestPoint = _closestPointOnLine(i, start, end, globalPos);
          link.state.isHovering = true;
          link.state.cursorOffset = closestPoint.$2;
          link.state.midpointIndex = closestPoint.$1;
          if (!ticker.isActive) {
            ticker.start();
          }
          break;
        }
        link.state.isHovering = false;
      }
    }
  }

  void _onTap(PointerEvent event, Size size) {
    NodeLink? hoveredLink = links.firstWhereOrNull((element) => element.state.isHovering);
    if (hoveredLink != null) {
      var position = (event.localPosition - widget.controller.offset) / widget.controller.zoom - size.center(Offset.zero);
      if (event.buttons == 2) {
        var index = hoveredLink.state.midpointIndex;
        if (index < 0 || index >= hoveredLink.bendPoints.length) return;
        var offset = hoveredLink.bendPoints[index];
        var distance = (offset.offset - position).distance;
        if (distance >= 8) return;
        // remove the midpoint
        setState(() {
          hoveredLink.state.cursorOffset = null;
          hoveredLink.removeBendPointAt(index);
          _checkMousePosition(event.position);
        });
        return;
      }
      _dragging = true;
      for (int i = 0; i < hoveredLink.bendPoints.length; i++) {
        var midpoint = hoveredLink.bendPoints[i];
        if ((midpoint.offset - position).distance < 8) {
          _draggingIndex = i;
          if (!midpoint.selected) widget.controller.select(midpoint);
          break;
        }
      }
      // widget.controller.markAsDragging();
    }
  }

  PointerMoveEvent? _moveEvent;
  Size? _size;
  void _handleDrag() {
    if (_moveEvent == null || _size == null) return;
    var hoveringLink = links.firstWhereOrNull((element) => element.state.arrowSize > 0);
    if (_dragging && hoveringLink != null && _moveEvent!.buttons == 1) {
      var position = (_moveEvent!.localPosition - widget.controller.offset) / widget.controller.zoom - _size!.center(Offset.zero);
      if (_draggingIndex != null) {
        List<Bendpoint> midpoints = hoveringLink.bendPoints;
        // midpoints[_draggingIndex!].offset = position;
        Offset delta = position - midpoints[_draggingIndex!].offset;
        widget.controller.shiftSelection(midpoints[_draggingIndex!], delta);
        // replace the hovering link with a new one
        setState(() {
          hoveringLink.state.cursorOffset = position;
          widget.blueprintState.handleDraggingCursor(_moveEvent!.position);
        });
      } else {
        // List<Bendpoint> midpoints = hoveringLink!.link.midpoints;
        if (_draggingPoint == null) {
          _draggingPoint = position;
          var bendpoint = Bendpoint.fromOffset(hoveringLink.state.cursorOffset!);
          hoveringLink.insertBendPoint(hoveringLink.state.midpointIndex, bendpoint);
          _draggingIndex = hoveringLink.state.midpointIndex;
          widget.controller.select(bendpoint);
        } else {
          throw 'Impossible unless something is wrong';
          // _draggingPoint = position;
          // // midpoints[hoveringLink!.offset.index].offset = _draggingPoint!;
          // Offset delta = _draggingPoint! - hoveringLink!.offset.offset;
          // widget.controller.shiftSelection(delta);
        }
        setState(() {
          hoveringLink.state.cursorOffset = _draggingPoint!;
          widget.blueprintState.handleDraggingCursor(_moveEvent!.position);
        });
      }
    }
  }

  bool _exitAfterUp = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      var size = constraints.biggest;
      _size = size;
      return MouseRegion(
        hitTestBehavior: HitTestBehavior.translucent,
        onHover: (event) {
          if (_pointerDown) return;
          var globalPos = (event.localPosition - widget.controller.offset) / widget.controller.zoom - size.center(Offset.zero);
          _checkMousePosition(globalPos);
        },
        onEnter: (event) {
          if (_pointerDown) return;
          var globalPos = (event.localPosition - widget.controller.offset) / widget.controller.zoom - size.center(Offset.zero);
          _checkMousePosition(globalPos);
        },
        onExit: (event) {
          if (_pointerDown) {
            _exitAfterUp = true;
            return;
          }
          for (var link in links) {
            link.state.isHovering = false;
          }
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            _pointerDown = true;
            _pointerTapHandle = event;
          },
          onPointerMove: (event) {
            if (_pointerTapHandle != null && event.delta.distanceSquared > 0) {
              _onTap(_pointerTapHandle!, size);
              _pointerTapHandle = null;
            }
            _moveEvent = event;
            _handleDrag();
          },
          onPointerCancel: (e) {
            if (_pointerTapHandle != null) {
              _pointerTapHandle = null;
            }
            _pointerDown = false;
            _dragging = false;
            _draggingPoint = null;
            _draggingIndex = null;
            _moveEvent = null;
            widget.blueprintState.handleDraggingStop();
          },
          onPointerUp: (e) {
            if (_exitAfterUp) {
              _exitAfterUp = false;
              for (var link in links) {
                link.state.isHovering = false;
              }
            }
            if (_pointerTapHandle != null) {
              _onTap(_pointerTapHandle!, size);
              _pointerTapHandle = null;
            }
            _pointerDown = false;
            _dragging = false;
            _draggingPoint = null;
            _draggingIndex = null;
            _moveEvent = null;
            widget.blueprintState.handleDraggingStop();
          },
          child: CustomPaint(
            foregroundPainter: BlueprintLinkPainter(
              controller: widget.controller,
              canvasSize: size,
              tick: tick,
              globalToLocal: context.globalToLocal,
              brightness: app.brightness,
              theme: BlueprintTheme.of(context),
            ),
            child: BlueprintTapInterceptorWidget(
              controller: widget.controller,
              canvasSize: size,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                onPanUpdate: (details) {},
                onPanStart: (details) {},
                onPanEnd: (details) {},
              ),
            ),
          ),
        ),
      );
    });
  }
}

class BlueprintTapInterceptorWidget extends SingleChildRenderObjectWidget {
  final BlueprintController controller;
  final Size canvasSize;

  const BlueprintTapInterceptorWidget({
    super.key,
    required this.controller,
    required this.canvasSize,
    required Widget child,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return BlueprintTapInterceptor(
      controller: controller,
      canvasSize: canvasSize,
    );
  }

  @override
  void updateRenderObject(BuildContext context, BlueprintTapInterceptor renderObject) {
    renderObject
      ..controller = controller
      ..canvasSize = canvasSize;
  }
}

class BlueprintTapInterceptor extends RenderProxyBox {
  BlueprintController controller;
  Size canvasSize;

  BlueprintTapInterceptor({
    required this.controller,
    required this.canvasSize,
  });

  Offset transformToGlobal(Offset offset, Size canvasSize) {
    offset = controller.offset + (offset + canvasSize.center(Offset.zero)) * controller.zoom;
    return offset;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required ui.Offset position}) {
    if (hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return hitTestChildren(result, position: position);
    } else {
      return false;
    }
  }

  @override
  bool hitTestSelf(ui.Offset position) {
    for (final link in controller.linkController.links) {
      if (link.from.outputPosition == null || link.to.inputPosition == null) continue;
      for (final bendpoint in link.bendPoints) {
        var transformed = transformToGlobal(bendpoint.offset, canvasSize);
        if ((transformed - position).distance < 8) {
          return true;
        }
      }
      List<Offset> linePoints = [
        transformToGlobal(link.from.outputPosition!, canvasSize),
        ...link.bendPoints.map((e) => transformToGlobal(e.offset, canvasSize)),
        transformToGlobal(link.to.inputPosition!, canvasSize),
      ];
      for (int i = 0; i < linePoints.length - 1; i++) {
        var start = linePoints[i];
        var end = linePoints[i + 1];
        var distance = _distanceToLine(start, end, position);
        if (distance < (link.state.isHovering ? 3 : 2) * controller.zoom + 4) {
          return true;
        }
      }
    }
    return false;
  }
}

class BlueprintLinkPainter extends CustomPainter {
  final BlueprintController controller;
  List<NodeLink> get links => controller.linkController.links;
  final Size canvasSize;
  final double tick;
  final Offset Function(Offset global) globalToLocal;
  final Brightness brightness;
  final BlueprintThemeData theme;

  const BlueprintLinkPainter({
    required this.controller,
    required this.tick,
    required this.globalToLocal,
    required this.canvasSize,
    required this.brightness,
    required this.theme,
  });

  @override
  bool? hitTest(ui.Offset position) {
    return false;
  }

  Offset transformToGlobal(Offset offset, Size canvasSize) {
    offset = controller.offset + (offset + canvasSize.center(Offset.zero)) * controller.zoom;
    return offset;
  }

  Offset roundTo(Offset offset, double step) {
    return Offset(
      (offset.dx / step).round() * step,
      (offset.dy / step).round() * step,
    );
  }

  Offset resnapToClosest(double? step, Offset midpoint, Offset start, Offset end) {
    if (step == null) return midpoint;
    double diffStartX = (midpoint.dx - start.dx).abs();
    double diffStartY = (midpoint.dy - start.dy).abs();
    double diffEndX = (midpoint.dx - end.dx).abs();
    double diffEndY = (midpoint.dy - end.dy).abs();
    if (diffStartX < step) {
      midpoint = Offset(start.dx, midpoint.dy);
    }
    if (diffStartY < step) {
      midpoint = Offset(midpoint.dx, start.dy);
    }
    if (diffEndX < step) {
      midpoint = Offset(end.dx, midpoint.dy);
    }
    if (diffEndY < step) {
      midpoint = Offset(midpoint.dx, end.dy);
    }
    return midpoint;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final link in links) {
      if (link.from.outputPosition == null || link.to.inputPosition == null) continue;
      final transformedStart = transformToGlobal(link.from.outputPosition!, size);
      final transformedEnd = transformToGlobal(link.to.inputPosition!, size);
      final paint = Paint()
        ..shader = ui.Gradient.linear(
          transformedStart,
          transformedEnd,
          [
            link.from.getOutputColor(brightness) ?? theme.executionColor,
            link.to.getInputColor(brightness) ?? theme.executionColor,
          ],
        )
        ..strokeWidth = 2 * controller.zoom
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (link.state.isHovering) {
        paint.strokeWidth = 2 * controller.zoom + 2 * link.state.arrowSize;
      }

      final path = Path();
      path.moveTo(transformedStart.dx, transformedStart.dy);
      for (var midpoint in link.bendPoints) {
        Offset transformedMidpoint = controller.offset + (midpoint.offset + size.center(Offset.zero)) * controller.zoom;
        path.lineTo(transformedMidpoint.dx, transformedMidpoint.dy);
      }
      path.lineTo(transformedEnd.dx, transformedEnd.dy);
      canvas.drawPath(path, paint);

      // draw circles for midpoints (where the circles are the same color as the line)
      for (var midpoint in link.bendPoints) {
        Offset transformedMidpoint = transformToGlobal(midpoint.offset, size);
        path.lineTo(transformedMidpoint.dx, transformedMidpoint.dy);
        canvas.drawCircle(transformedMidpoint, 2 * controller.zoom, paint);
        if (midpoint.selected) {
          const double expansion = 5;
          final Paint paint = Paint()
            ..color = theme.executionColor
            ..strokeWidth = 2 * controller.zoom
            ..style = PaintingStyle.stroke;
          canvas.drawCircle(transformedMidpoint, 2 * controller.zoom + expansion, paint);
        }
      }
    }
    var hoveringLink = links.firstWhereOrNull((element) => element.state.arrowSize > 0);
    if (hoveringLink != null && hoveringLink.state.arrowSize > 0) {
      var offset = hoveringLink.state.cursorOffset;
      var start = transformToGlobal(hoveringLink.from.outputPosition!, size);
      var end = transformToGlobal(hoveringLink.to.inputPosition!, size);

      var outputColor = hoveringLink.from.getOutputColor(brightness);
      var inputColor = hoveringLink.to.getInputColor(brightness);
      if (offset != null) {
        var transformedOffset = transformToGlobal(offset, size);
        canvas.drawCircle(
            transformedOffset,
            5 * controller.zoom * hoveringLink.state.arrowSize.clamp(0, 1),
            Paint()
              ..shader = ui.Gradient.linear(
                start,
                end,
                [
                  outputColor ?? theme.executionColor,
                  inputColor ?? theme.executionColor,
                ],
              ));
      }
      // draw a arrow animation through the link (ticks are used to animate the arrow), the arrow is shaped triangle using createTriangle function
      // the arrow is not single triangle, but it follows the link path like ants, with specific gap/distances between each triangle
      var arrowPaint = Paint()
        ..shader = ui.Gradient.linear(
          start,
          end,
          [
            outputColor ?? theme.executionColor,
            inputColor ?? theme.executionColor,
          ],
        );
      var arrowPath = Path();
      arrowPath.moveTo(start.dx, start.dy);
      for (var midpoint in hoveringLink.bendPoints) {
        var transformedMidpoint = transformToGlobal(midpoint.offset, size);
        arrowPath.lineTo(transformedMidpoint.dx, transformedMidpoint.dy);
      }
      arrowPath.lineTo(end.dx, end.dy);
      ui.PathMetrics metrics = arrowPath.computeMetrics();
      ui.PathMetric? metric = metrics.firstOrNull;
      if (metric != null) {
        double distance = metric.length;
        double gap = 40 * controller.zoom;
        double remainder = distance % gap;
        int division = distance ~/ gap;
        gap += remainder / division;
        for (double i = 0; i < distance; i += gap) {
          var animatedI = (i + tick * controller.zoom) % distance;
          var distanceFromEnd = distance - animatedI;
          var limit = 20 * controller.zoom;
          var zoomed = min(animatedI.clamp(0, limit) / limit, distanceFromEnd.clamp(0, limit) / limit);
          var tangentForOffset = metric.getTangentForOffset(animatedI);
          var pos = tangentForOffset!.position;
          var rotation = tangentForOffset.angle;
          // rotation is counter-clockwise, so we need to convert it to clockwise
          rotation = -rotation + pi / 2;
          canvas.drawPath(createTriangle(rotation, hoveringLink.state.arrowSize.clamp(0, 1) * 6 * controller.zoom * zoomed).shift(pos), arrowPaint);
        }
      }
    }
  }

  Path createTriangle(double rotation, [double radius = 4]) {
    var path = Path();
    path.moveTo(0, -radius);
    path.lineTo(radius, radius);
    path.lineTo(-radius, radius);
    path.close();
    path = path.transform(Matrix4.rotationZ(
      // debug for 90 degree
      rotation,
    ).storage);
    return path;
  }

  @override
  bool shouldRepaint(covariant BlueprintLinkPainter oldDelegate) {
    return oldDelegate.links != links ||
        oldDelegate.tick != tick ||
        oldDelegate.controller.zoom != controller.zoom ||
        oldDelegate.controller.offset != controller.offset ||
        oldDelegate.theme != theme;
  }
}
