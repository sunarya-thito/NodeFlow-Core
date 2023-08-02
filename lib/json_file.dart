import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

class JsonFile extends ChangeNotifier {
  static Future<JsonFile> open(File file) async {
    JsonFile jsonFile = JsonFile._(file);
    await jsonFile.reload();
    return jsonFile;
  }

  final File file;

  JsonFile._(this.file);

  late Map<String, dynamic> _data;

  Future<void> reload() async {
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('{}');
    }
    _data = jsonDecode(await file.readAsString());
  }

  Future<void> write() async {
    await file.writeAsString(jsonEncode(_data));
  }

  T? get<T>(String key) {
    return _data[key] as T?;
  }

  operator [](String key) {
    return get(key);
  }

  operator []=(String key, dynamic value) {
    set(key, value);
  }

  Future<void> set<T>(String key, T value) {
    _data[key] = value;
    notifyListeners();
    return write();
  }

  JsonFileBatchSetter batch() {
    return JsonFileBatchSetter._(this);
  }

  void _updateListeners() {
    notifyListeners();
  }
}

class JsonFileBatchSetter {
  final JsonFile _file;

  JsonFileBatchSetter._(this._file);

  JsonFileBatchSetter set<T>(String key, T value) {
    _file._data[key] = value;
    return this;
  }

  operator [](String key) {
    return _file._data[key];
  }

  operator []=(String key, dynamic value) {
    _file._data[key] = value;
  }

  Future<void> commit() {
    _file._updateListeners();
    return _file.write();
  }
}
