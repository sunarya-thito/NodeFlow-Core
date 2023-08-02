import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nodeflow/json_file.dart';

class FileStorageContext extends InheritedWidget {
  final FileStorage storage;

  const FileStorageContext({
    Key? key,
    required this.storage,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant FileStorageContext oldWidget) => storage != oldWidget.storage;
}

class FileStorage {
  static FileStorage of(BuildContext context) {
    final FileStorageContext? result = context.dependOnInheritedWidgetOfExactType<FileStorageContext>();
    assert(result != null, 'No FileStorageContext found in context');
    return result!.storage;
  }

  late final JsonFile settingsFile;

  void initialize() async {
    settingsFile = await JsonFile.open(File('settings.json'));
  }
}
