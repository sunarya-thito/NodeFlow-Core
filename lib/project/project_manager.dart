import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nodeflow/project/project.dart';
import 'package:nodeflow/router.dart';

import '../module/module.dart';
import '../objects.dart';

class ProjectManager extends InheritedWidget {
  final Directory directory;
  final List<ProjectModule> modules;

  const ProjectManager({
    Key? key,
    required Widget child,
    required this.directory,
    required this.modules,
  }) : super(key: key, child: child);

  static ProjectManager of(BuildContext context) {
    final ProjectManager? result = context.dependOnInheritedWidgetOfExactType<ProjectManager>();
    assert(result != null, 'No ProjectManager found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant ProjectManager oldWidget) {
    return directory != oldWidget.directory || modules != oldWidget.modules;
  }

  static void openProject(BuildContext context, Project project) async {
    context.goPaths([const KeyPath('project'), DataPath(data: project)]);
  }

  Future<ProjectSnapshot> createProject(ProjectDescription description, ProjectModule module) async {
    Directory dir = Directory('${directory.path}/${description.name}');
    if (await dir.exists()) {
      throw Exception('Project already exists');
    }
    await dir.create();
    File file = File('${dir.path}/project.nfp');
    await file.writeAsString(jsonEncode({
      'name': description.name,
      'description': description.description,
      'module': module.id,
    }));

    ProjectSnapshot snapshot = ProjectSnapshot._(dir);
    snapshot._module = module;
    snapshot._description = description;
    return snapshot;
  }

  Future<List<ProjectSnapshot>> loadProjectSnapshots() async {
    List<ProjectSnapshot> projects = [];
    if (!await directory.exists()) {
      return projects;
    }
    List<FileSystemEntity> entities = await directory.list().toList();
    for (FileSystemEntity entity in entities) {
      if (entity is Directory) {
        try {
          projects.add(await ProjectSnapshot.load(entity, this));
        } catch (e) {
          print(e);
        }
      }
    }
    return projects;
  }
}

class ProjectSnapshot extends ChangeNotifier {
  final Directory directory;
  late ProjectDescription _description;
  late ProjectModule _module;
  ProjectSnapshot._(this.directory);

  static Future<ProjectSnapshot> load(Directory dir, ProjectManager manager) async {
    ProjectSnapshot project = ProjectSnapshot._(dir);
    await project._load(manager);
    return project;
  }

  ProjectModule get module => _module;
  ProjectDescription get description => _description;

  Future<void> _load(ProjectManager manager) async {
    File file = File('${directory.path}/project.nfp');
    if (!await file.exists()) {
      throw Exception('Project description file not found');
    }
    Map<String, dynamic> data = jsonDecode(await file.readAsString());
    _description = ProjectDescription(
      name: Objects.nonNull(data['name'], 'Project name not found'),
      description: data['description'],
    );
    _module = manager.modules.firstWhere((element) => element.id == data['module']);
  }

  Future<void> setProjectDescription(ProjectDescription description) async {
    _description = description;
    await _updateDescription(description);
  }

  Future<void> _updateDescription(ProjectDescription description) async {
    File file = File('${directory.path}/project.nfp');
    await file.writeAsString(jsonEncode({
      'name': description.name,
      'description': description.description,
    }));
    notifyListeners();
  }
}

class ProjectDescription {
  final String name;
  final String? description;

  const ProjectDescription({
    required this.name,
    this.description,
  });

  ProjectDescription copyWith({
    String? name,
    String? description,
  }) {
    return ProjectDescription(
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}
