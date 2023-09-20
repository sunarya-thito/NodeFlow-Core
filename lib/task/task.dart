import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nodeflow/i18n.dart';

class TaskIntent extends Intent {
  final I18nString name;

  const TaskIntent(this.name);
}

abstract class TaskAction<T extends TaskIntent> extends Action<T> {
  Stream<ProgressData> invokeAction(T intent, BuildContext context);

  @override
  Object invoke(T intent, [BuildContext? context]) {
    assert(context != null, 'Context is required for TaskAction');
    return invokeAction(intent, context!);
  }
}

class ProgressData {
  final double progress;
  final I18nString? message;
  final Object? data;
  const ProgressData(this.progress, {this.message}) : data = null;
  const ProgressData.complete({this.message, this.data}) : progress = 1;
  static const ProgressData zero = ProgressData(0);
}

class FunctionTaskAction<T extends TaskIntent> extends TaskAction<T> {
  final Stream<ProgressData> Function(T intent, BuildContext context) function;

  FunctionTaskAction(this.function);

  @override
  Stream<ProgressData> invokeAction(T intent, BuildContext context) {
    return function(intent, context);
  }
}

class TaskManager extends ValueListenable<List<ActiveTask>> with ChangeNotifier {
  final List<ActiveTask> _tasks = [];

  @override
  List<ActiveTask> get value => _tasks;

  void _registerTask(ActiveTask task) {
    _tasks.add(task);
    notifyListeners();
  }

  void _unregisterTask(ActiveTask task) {
    _tasks.remove(task);
    notifyListeners();
  }
}

class ActiveTask extends ValueNotifier<ProgressData> {
  ActiveTask(super.value);
}

abstract class TaskNotification extends Notification {}

class TaskFailedNotification extends TaskNotification {
  final Object? error;
  final StackTrace? stackTrace;

  TaskFailedNotification([this.error, this.stackTrace]);
}

class TaskActionDispatcher extends ActionDispatcher {
  final TaskManager taskManager;

  const TaskActionDispatcher(this.taskManager);

  @override
  Object? invokeAction(covariant Action<Intent> action, covariant Intent intent, [BuildContext? context]) {
    Object? result = super.invokeAction(action, intent, context);
    if (action is TaskAction && context != null && result is Stream<ProgressData>) {
      ActiveTask task = ActiveTask(ProgressData.zero);
      taskManager._registerTask(task);
      var listen = result.listen((event) {
        task.value = event;
      });
      listen.onError((error, stackTrace) {
        taskManager._unregisterTask(task);
        TaskFailedNotification(error, stackTrace).dispatch(context);
        listen.cancel();
      });
      listen.onDone(() {
        taskManager._unregisterTask(task);
        listen.cancel();
      });
    }
    return result;
  }
}
