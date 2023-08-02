import 'package:flutter/widgets.dart';

abstract class TaskAction<T extends Intent> extends Action<T> {
  @override
  Future<Object?> invoke(T intent);
}

abstract class ContextTaskAction<T extends Intent> extends Action<T> {
  @override
  Future<Object?> invoke(T intent, [BuildContext? context]);
}

abstract class ProgressTaskAction<T extends Intent> extends Action<T> {
  @override
  Stream<ProgressData> invoke(T intent);
}

abstract class ContextProgressTaskAction<T extends Intent> extends Action<T> {
  @override
  Stream<ProgressData> invoke(T intent, [BuildContext? context]);
}

class ProgressData {
  final double progress;
  final String? message;
  final Object? data;
  const ProgressData(this.progress, {this.message}) : data = null;
  const ProgressData.complete({this.message, this.data}) : progress = 1;
}

class TaskManager {}

class ActiveTask {}

class TaskNotification extends Notification {}

class TaskActionDispatcher extends ActionDispatcher {
  final TaskManager taskManager;

  const TaskActionDispatcher(this.taskManager);

  @override
  Object? invokeAction(covariant Action<Intent> action, covariant Intent intent, [BuildContext? context]) {
    Object? result = super.invokeAction(action, intent, context);
    if (action is TaskAction) {
      Future<Object?> resultFuture = result as Future<Object?>;
      Future<Object?> future = Future(() {
        // TODO: submit to task queue
      })
          .then((_) async {
        return await resultFuture;
      }).catchError((err, stackTrace) {
        // TODO: mark task as failed
        return Future.error(err, stackTrace);
      }).then((value) {
        // TODO: mark task as done
        return value;
      });
      result = future;
    } else if (action is ProgressTaskAction) {
      Stream<ProgressData> resultStream = result as Stream<ProgressData>;
      // convert stream to future
      // TODO: submit to task queue
      Future<Object?> future = Future(() async {
        await for (ProgressData data in resultStream) {
          // TODO: update task progress
        }
      });

      result = future;
    }
    return result;
  }
}
