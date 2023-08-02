import 'package:flutter/material.dart';

class Project {
  final String path;

  const Project(this.path);
}

class ProjectController {}

class ProjectContext extends InheritedWidget {
  final ProjectController project;

  const ProjectContext({
    Key? key,
    required this.project,
    required Widget child,
  }) : super(key: key, child: child);

  static ProjectController of(BuildContext context) {
    final ProjectContext? result = context.dependOnInheritedWidgetOfExactType<ProjectContext>();
    assert(result != null, 'No ProjectContext found in context');
    return result!.project;
  }

  @override
  bool updateShouldNotify(covariant ProjectContext oldWidget) => project != oldWidget.project;
}
