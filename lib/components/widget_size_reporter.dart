import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class WidgetSizeReporter extends SingleChildRenderObjectWidget {
  final void Function(Size size) onSizeChanged;

  const WidgetSizeReporter({
    Key? key,
    required this.onSizeChanged,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderWidgetSizeReporter(
      onSizeChanged: onSizeChanged,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as RenderWidgetSizeReporter).onSizeChanged = onSizeChanged;
  }
}

class RenderWidgetSizeReporter extends RenderProxyBox {
  late void Function(Size size) onSizeChanged;

  RenderWidgetSizeReporter({
    required this.onSizeChanged,
    RenderBox? child,
  }) : super(child);

  @override
  set size(Size value) {
    if (hasSize && size == value) {
      return;
    }
    super.size = value;
    onSizeChanged(size);
  }
}
