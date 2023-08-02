import 'package:flutter/material.dart';
import 'package:undo/undo.dart';

class UndoableActionContext extends StatefulWidget {
  final Widget child;

  const UndoableActionContext({Key? key, required this.child}) : super(key: key);

  @override
  _UndoableActionContextState createState() => _UndoableActionContextState();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class UndoAction extends Action<UndoIntent> {
  final ChangeStack _changeStack;

  UndoAction(this._changeStack);

  @override
  Object? invoke(UndoIntent intent) {
    _changeStack.undo();
    return null;
  }
}

class RedoAction extends Action<RedoIntent> {
  final ChangeStack _changeStack;

  RedoAction(this._changeStack);

  @override
  Object? invoke(RedoIntent intent) {
    _changeStack.redo();
    return null;
  }
}

class _UndoableActionContextState extends State<UndoableActionContext> {
  final ChangeStack _changeStack = ChangeStack();
  late final Map<Type, Action> _actions;

  @override
  void initState() {
    super.initState();
    _actions = {
      UndoIntent: UndoAction(_changeStack),
      RedoIntent: RedoAction(_changeStack),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: _actions,
      child: NotificationListener<Notification>(
        onNotification: (notification) {
          return false;
        },
        child: widget.child,
      ),
    );
  }
}
