import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:nodeflow/project/project.dart';

import '../module/file_module.dart';

class ProjectFileMeta {
  final File file;

  ProjectFileMeta(this.file);

  late Map<String, dynamic> _data;

  Future<void> load() async {
    _data = jsonDecode(await file.readAsString());
  }

  Future<void> save() async {
    await file.writeAsString(jsonEncode(_data));
  }

  dynamic get(String key) {
    return _data[key];
  }

  void set(String key, dynamic value) {
    _data[key] = value;
  }
}

const kKeyFileName = 'name';
const kKeyFileModule = 'module';
const kExtMeta = 'nfm';
const kExtFile = 'nff';

abstract class ProjectFile {
  final String id;
  final Project project;
  final File file;

  late ProjectFileMeta meta;
  late ValueNotifier<String> _name;
  late FileModule _module;

  ProjectFile._(this.id, this.project) : file = File('${project.snapshot.directory}/src/$id.$kExtFile');

  Future<void> _load() async {
    meta = ProjectFileMeta(File('${project.snapshot.directory}/src/$id.$kExtMeta'));
    await meta.load();
    _name = ValueNotifier(meta.get(kKeyFileName) ?? 'Untitled');
    _name.addListener(() {
      meta.set(kKeyFileName, _name.value);
    });
    _module = project.snapshot.module.fileModules.firstWhere((element) => element.id == meta.get(kKeyFileModule));
  }

  ValueNotifier<String> get name => _name;
  FileModule get module => _module;
}

class ProjectJsonFile extends ProjectFile {
  ProjectJsonFile._(String id, Project project) : super._(id, project);

  late Map<String, dynamic> _data;
  @override
  Future<void> _load() async {
    await super._load();
    _data = jsonDecode(await file.readAsString());
  }

  Future<void> save(Map<String, dynamic> data) async {
    _data = data;
    await file.writeAsString(jsonEncode(_data));
  }

  Map<String, dynamic> get data => Map.from(_data);
}
