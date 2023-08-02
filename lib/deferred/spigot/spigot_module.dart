// THIS FILE MUST BE IMPORTED USING DEFERRED IMPORTS!!!

import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/cupertino.dart';

import '../../project.dart';

class SpigotModuleContext extends InheritedWidget {
  final SpigotModule module;

  const SpigotModuleContext({
    Key? key,
    required this.module,
    required Widget child,
  }) : super(key: key, child: child);

  static SpigotModule of(BuildContext context) {
    final SpigotModuleContext? result = context.dependOnInheritedWidgetOfExactType<SpigotModuleContext>();
    assert(result != null, 'No SpigotModuleContext found in context');
    return result!.module;
  }

  @override
  bool updateShouldNotify(covariant SpigotModuleContext oldWidget) => module != oldWidget.module;
}

enum Level {
  info, // [INFO]
  warning, // [WARNING]
  error, // [ERROR]
}

// [Level][time] message
class LogRecord {
  final Level level;
  final String message;
  final DateTime time;

  factory LogRecord.fromLog(String message) {
    message = message.trim();
    Level level;
    if (message.startsWith('[INFO]')) {
      level = Level.info;
      message = message.substring(7);
    } else if (message.startsWith('[WARNING]')) {
      level = Level.warning;
      message = message.substring(10);
    } else if (message.startsWith('[ERROR]')) {
      level = Level.error;
      message = message.substring(8);
    } else {
      level = Level.info;
    }

    message = message.trim();
    String time = DateTime.now().toIso8601String();
    if (message.startsWith('[')) {
      int index = message.indexOf(']');
      if (index != -1) {
        time = message.substring(1, index);
        message = message.substring(index + 1);
      }
    }

    message = message.trim();

    return LogRecord._(level, message, DateTime.parse(time));
  }

  LogRecord._(this.level, this.message, this.time);
}

class SpigotModule {
  String getJavaExecutable() {
    // check for JRE
    // get JRE path using %java% from system environment variables
    Map<String, String> env = Platform.environment;

    String javaExecutable = env['java'] ?? env['nodeflow_java'] ?? 'bundle/jre/bin/java.exe';

    // check if java executable exists
    if (!File(javaExecutable).existsSync()) {
      throw Exception('Java executable not found at $javaExecutable');
    }

    return javaExecutable;
  }

  Stream<LogRecord> convertJdkOrJreToProjectComponent(File output) async* {
    String converterJar = 'libraries/spigot/java-converter.jar';
    String javaExecutable = getJavaExecutable();
    String outputPath = output.path;

    yield LogRecord.fromLog('Converting JRE to project component $outputPath');
    yield LogRecord.fromLog('Using java executable $javaExecutable');
    yield LogRecord.fromLog('Using converter jar $converterJar');

    Process process = await Process.start(
      javaExecutable,
      [
        '-jar',
        'jre-to-npc',
        converterJar,
        outputPath,
      ],
    );

    // listen to stdout and stderr in same time
    await for (String line in _listenConsole(process)) {
      yield LogRecord.fromLog(line);
    }

    yield LogRecord.fromLog('Conversion finished');

    int exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Conversion failed with exit code $exitCode');
    }
  }

  Stream<LogRecord> convertToProjectComponent(File jarFile, File output) async* {
    String converterJar = 'libraries/spigot/java-converter.jar';
    String javaExecutable = getJavaExecutable();
    String jarPath = jarFile.path;
    String outputPath = output.path;

    yield LogRecord.fromLog('Converting jar $jarPath to project component $outputPath');
    yield LogRecord.fromLog('Using java executable $javaExecutable');
    yield LogRecord.fromLog('Using converter jar $converterJar');

    Process process = await Process.start(
      javaExecutable,
      [
        '-jar',
        'jar-to-npc',
        converterJar,
        jarPath,
        outputPath,
      ],
    );

    // listen to stdout and stderr in same time
    await for (String line in _listenConsole(process)) {
      yield LogRecord.fromLog(line);
    }

    yield LogRecord.fromLog('Conversion finished');

    int exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Conversion failed with exit code $exitCode');
    }
  }

  Stream<LogRecord> compile(Project project, File output, [bool includeSource = true]) async* {
    String compilerJar = 'libraries/spigot/spigot-compiler.jar';
    String javaExecutable = getJavaExecutable();
    String projectPath = project.path;

    yield LogRecord.fromLog('Compiling project $projectPath');
    yield LogRecord.fromLog('Using java executable $javaExecutable');
    yield LogRecord.fromLog('Using compiler jar $compilerJar');

    Process process = await Process.start(
      javaExecutable,
      [
        '-jar',
        includeSource.toString(),
        compilerJar,
        projectPath,
        output.path,
      ],
    );

    // listen to stdout and stderr in same time
    await for (String line in _listenConsole(process)) {
      yield LogRecord.fromLog(line);
    }

    yield LogRecord.fromLog('Compilation finished');

    int exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Compilation failed with exit code $exitCode');
    }
  }

  Stream<String> _listenConsole(Process process) {
    Stream<String> stdoutStream = process.stdout.transform(utf8.decoder);
    Stream<String> stderrStream = process.stderr.transform(utf8.decoder);
    return StreamGroup.merge([stdoutStream, stderrStream]);
  }
}

class MavenCachedPackage {}
