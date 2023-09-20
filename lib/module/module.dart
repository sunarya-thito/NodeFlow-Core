import 'package:nodeflow/module/file_module.dart';

class ProjectModule {
  final String id;
  final List<FileModule> fileModules;

  ProjectModule(this.id, this.fileModules);
}
