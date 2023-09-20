import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

/// Animates its child into a visible state (opacity, scale,offset and angle)
class Entry extends StatelessWidget {
  /// The child to animate
  final Widget child;

  final Duration delay;

  final Duration duration;

  final Curve curve;

  final bool visible;

  final double? opacity;

  final Size? scale;
  final Alignment? scaleAlignment;

  final Size? startSize, endSize;

  final double? angle;

  final void Function()? onEnd;

  /// Default constructor (motionless by default)
  const Entry({
    Key? key,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.ease,
    this.visible = true,
    this.opacity = 1,
    this.scale,
    this.startSize,
    this.endSize,
    this.scaleAlignment = Alignment.center,
    this.angle = 0,
    this.onEnd,
    required this.child,
  }) : super(key: key); // coverage:ignore-line

  @override
  Widget build(BuildContext context) {
    var tween = MovieTween();
    // ..tween("opacity", Tween(begin: opacity, end: 1.0), duration: duration, curve: curve)
    // ..tween("angle", Tween(begin: angle, end: 0.0), duration: duration, curve: curve);
    if (opacity != null) {
      tween = tween..tween("opacity", Tween(begin: opacity, end: 1.0), duration: duration, curve: curve);
    }
    if (angle != null) {
      tween = tween..tween("angle", Tween(begin: angle, end: 0.0), duration: duration, curve: curve);
    }
    if (scale != null) {
      tween = tween
        ..tween("scaleX", Tween(begin: scale!.width, end: 1.0), duration: duration, curve: curve)
        ..tween("scaleY", Tween(begin: scale!.height, end: 1.0), duration: duration, curve: curve);
    }
    // if (size != null) {
    //   tween = tween
    //     ..tween("width", Tween(begin: size!.width, end: 0.0), duration: duration, curve: curve)
    //     ..tween("height", Tween(begin: size!.height, end: 0.0), duration: duration, curve: curve);
    // }
    if (startSize != null && endSize != null) {
      tween = tween
        ..tween("width", Tween(begin: startSize!.width, end: endSize!.width), duration: duration, curve: curve)
        ..tween("height", Tween(begin: startSize!.height, end: endSize!.height), duration: duration, curve: curve);
    }
    return CustomAnimationBuilder<Movie>(
      control: visible ? Control.play : Control.playReverse,
      delay: delay,
      duration: tween.duration,
      tween: tween,
      onCompleted: onEnd,
      builder: (context, value, child) {
        if (opacity != null) {
          child = Opacity(opacity: value.get("opacity"), child: child);
        }
        if (angle != null) {
          child = Transform.rotate(angle: value.get("angle"), child: child);
        }
        if (scale != null) {
          child = Transform.scale(
            scaleX: value.get("scaleX"),
            scaleY: value.get("scaleY"),
            alignment: scaleAlignment,
            child: child,
          );
        }
        if (startSize != null && endSize != null) {
          child = ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: value.get("width"),
              maxHeight: value.get("height"),
            ),
            child: child,
          );
        }
        return child!;
      },
      child: child,
    );
  }
}
