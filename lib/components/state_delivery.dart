import 'package:flutter/widgets.dart';

class StateData<T extends State> extends InheritedWidget {
  final T state;

  const StateData({
    Key? key,
    required this.state,
    required Widget child,
  }) : super(key: key, child: child);

  static T of<T extends State>(BuildContext context) {
    final StateData<T>? result = context.dependOnInheritedWidgetOfExactType<StateData<T>>();
    assert(result != null, 'No StateData found in context');
    return result!.state;
  }

  @override
  bool updateShouldNotify(covariant StateData<T> oldWidget) {
    return state != oldWidget.state;
  }
}
