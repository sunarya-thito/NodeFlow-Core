import 'package:nodeflow/module/file_module.dart';
import 'package:nodeflow/module/module.dart';

class SpigotModule extends ProjectModule {
  SpigotModule()
      : super('spigot', [
          SpigotEventModule(),
        ]);
}

class SpigotEventModule extends FileModule {
  SpigotEventModule() : super('spigot_event');
}
