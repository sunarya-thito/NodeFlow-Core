import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:nodeflow/project.dart';
import 'package:nodeflow/task/task.dart';

class ProjectIntent extends Intent {
  final Project project;

  const ProjectIntent(this.project);
}

class RunProjectIntent extends ProjectIntent {
  const RunProjectIntent(Project project) : super(project);
}

class StopProjectIntent extends ProjectIntent {
  const StopProjectIntent(Project project) : super(project);
}

class BuildProjectIntent extends ProjectIntent {
  const BuildProjectIntent(Project project) : super(project);
}

class CreateProjectIntent extends ProjectIntent {
  const CreateProjectIntent(Project project) : super(project);
}

class OpenProjectIntent extends ProjectIntent {
  const OpenProjectIntent(Project project) : super(project);
}

class CreateFileIntent extends ProjectIntent {
  final Directory? directory;
  const CreateFileIntent(Project project, {this.directory}) : super(project);
}

class OpenFileIntent extends ProjectIntent {
  final File file;
  const OpenFileIntent(Project project, this.file) : super(project);
}

class ImportFileIntent extends ProjectIntent {
  final File file;
  const ImportFileIntent(Project project, this.file) : super(project);
}

class DeleteFileIntent extends ProjectIntent {
  final File file;
  const DeleteFileIntent(Project project, this.file) : super(project);
}

abstract class OpenProjectAction extends TaskAction<OpenProjectIntent> {
  @override
  Future<ProjectController> invoke(OpenProjectIntent intent) async {
    ProjectController project = ProjectController();
    return project;
  }

  Future<void> openProject(ProjectController controller);
}

// rename is handled by the file handler

abstract class AppModule {
  // use it on NodeFlow(appModule: AppModule())
  ProgressTaskAction<RunProjectIntent> get runProjectAction;
  Action<StopProjectIntent> get stopProjectAction;
  Action<BuildProjectIntent> get buildProjectAction;
  Action<CreateProjectIntent> get createProjectAction;

  Map<String, FileModule> get fileModules;
}

abstract class FileModule {
  Action<CreateFileIntent>? get createFileAction; // if null, create file is not supported
  Action<OpenFileIntent> get openFileAction;
  Action<DeleteFileIntent>? get deleteFileAction; // if null, delete file is not supported
  Action<ImportFileIntent>? get importFileAction; // if null, import file is not supported
  FileHandler create(RandomAccessFile file);
  FileHandler open(RandomAccessFile file);
}

abstract class FileHandler {
  Widget build(BuildContext context);
}
