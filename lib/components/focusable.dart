import 'package:flutter/widgets.dart';

abstract class Focusable {
  Rect get boundingBox;
}

void makeSureVisible(BuildContext context, List<Focusable> focusable, {bool zoom = false}) {
  if (focusable.isEmpty) {
    return;
  }
  FocusableViewport? viewport = FocusableViewport.maybeOf(context);
  if (viewport == null) {
    return;
  }
  Rect combined = focusable.first.boundingBox;
  for (var i = 1; i < focusable.length; i++) {
    combined = combined.expandToInclude(focusable[i].boundingBox);
  }
  viewport.makeSureVisible(combined, zoom);
}

class FocusableViewport extends InheritedWidget {
  final void Function(Rect rect, bool zoom) makeSureVisible;

  const FocusableViewport({
    Key? key,
    required this.makeSureVisible,
    required Widget child,
  }) : super(key: key, child: child);

  static FocusableViewport? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FocusableViewport>();
  }

  static FocusableViewport of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FocusableViewport>()!;
  }

  @override
  bool updateShouldNotify(covariant FocusableViewport oldWidget) {
    return makeSureVisible != oldWidget.makeSureVisible;
  }
}
