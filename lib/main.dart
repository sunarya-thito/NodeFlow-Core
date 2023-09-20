import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nodeflow/router.dart';

import 'nodeflow.dart';

void main(List<String> args) {
  List<RouterPath> initialPaths = [const KeyPath('dashboard')];
  Set<String> existing = {};
  void Function(FlutterErrorDetails) originalOnError = FlutterError.onError!;
  FlutterError.onError = (FlutterErrorDetails details) {
    var string = details.toString();
    if (existing.contains(string)) return;
    existing.add(string);
    originalOnError(details);
  };
  runApp(Nodeflow(
    modules: const [],
    initialPath: initialPaths,
  ));
  doWhenWindowReady(() {
    const initialSize = Size(800, 600);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = 'Nodeflow';
    appWindow.show();

    if (kDebugMode) {
      Future.delayed(const Duration(seconds: 1), () {
        appWindow.maximize();
        appWindow.restore();
      });
    }
  });
}
