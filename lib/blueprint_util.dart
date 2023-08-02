import 'dart:math';

import 'package:flutter/material.dart';

// /// Returns the relative position of the bend point to the from port.
// /// The vector is relative to the from port, so that the x and y components are relative to the from port.
// Offset getRelativePosition(Offset from, Offset to, Offset bendPoint) {
//   Offset diff = to - from;
//   Offset relative = bendPoint - from;
//   return Offset((relative.dx / diff.dx).clamp(0, 1), (relative.dy / diff.dy).clamp(0, 1));
// }
//
// /// Returns the absolute position of the bend point.
// /// [from] is the absolute position of the from port.
// /// [to] is the absolute position of the to port.
// /// [bendPoint] is the relative position of the bend point from [to] to [from].
// Offset getAbsolutePosition(Offset from, Offset to, Offset bendPoint) {
//   Offset diff = to - from;
//   var result = from + Offset(bendPoint.dx * diff.dx, bendPoint.dy * diff.dy);
//   return Offset(result.dx.clamp(min(from.dx, to.dx), max(from.dx, to.dx)), result.dy.clamp(min(from.dy, to.dy), max(from.dy, to.dy)));
// }

class IdStorage {
  int _nextId = 0;

  void setNextId(int nextId) {
    _nextId = nextId;
  }

  int getNextId() {
    return _nextId;
  }

  String requestId() {
    return (_nextId++).toString();
  }
}

extension ColorExtension on Color {
  Color calculateBrighterColor(double factor) {
    return Color.fromARGB(
      alpha,
      red + ((255 - red) * factor).toInt(),
      green + ((255 - green) * factor).toInt(),
      blue + ((255 - blue) * factor).toInt(),
    );
  }

  Color calculateDarkerColor(double factor) {
    return Color.fromARGB(
      alpha,
      (red * factor).toInt(),
      (green * factor).toInt(),
      (blue * factor).toInt(),
    );
  }
}

class ColorStorage {
  static Color generateColor(int hashCode, Brightness brightness) {
    Random random = Random(hashCode);
    final hue = random.nextInt(360);
    const saturation = 0.5;
    final lightness = brightness == Brightness.light ? 0.5 : 0.3;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), saturation, lightness).toColor();
  }
}
