import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../delta_map.dart';

class FileHistoryData extends InheritedWidget {
  final FileHistory history;

  const FileHistoryData({
    Key? key,
    required this.history,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant FileHistoryData oldWidget) => history != oldWidget.history;

  static FileHistory of(BuildContext context) {
    final FileHistoryData? result = context.dependOnInheritedWidgetOfExactType<FileHistoryData>();
    assert(result != null, 'No FileHistoryData found in context');
    return result!.history;
  }
}

class FileHistoryContext extends StatefulWidget {
  final File file;
  final Widget Function(BuildContext context) builder;
  final int maxHistory;

  const FileHistoryContext({
    Key? key,
    required this.file,
    required this.builder,
    required this.maxHistory,
  }) : super(key: key);

  @override
  State<FileHistoryContext> createState() => _FileHistoryContextState();
}

class _FileHistoryContextState extends State<FileHistoryContext> {
  late Future<FileHistory> _file;

  @override
  void initState() {
    super.initState();
    _file = FileHistory.open(widget.file, widget.maxHistory);
  }

  @override
  void didUpdateWidget(covariant FileHistoryContext oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file != widget.file) {
      _file = FileHistory.open(widget.file, widget.maxHistory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FileHistory>(
      future: _file,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return widget.builder(context);
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          return const Text('Loading...');
        }
      },
    );
  }
}

class FileHistory {
  final File _file;
  late final DeltaMap<String, dynamic> _history;
  final Map<String, dynamic> _json;
  int _historyIndex = 0;

  static Future<FileHistory> open(File file, int maxHistory) async {
    Map<String, dynamic> json = jsonDecode(file.readAsStringSync());
    return FileHistory(file, json, maxHistory);
  }

  FileHistory(this._file, this._json, int maxHistory) {
    _history = DeltaMap(_json['original'], maxHistory, _json['delta'].map((e) => NamedDelta(e['name'], e['delta'])).toList());
    _historyIndex = _json['index'];
  }

  set maxHistory(int value) {
    _history.maxDeltas = value;
  }

  void pushHistory(String displayName, Map<String, dynamic> data) {
    _history.insertData(_historyIndex, displayName, data);
  }

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length;

  Future<Map<String, dynamic>?> undo() async {
    if (_historyIndex > 0) {
      _historyIndex--;
      Map<String, dynamic> data = _history[_historyIndex];
      _json['index'] = _historyIndex;
      _file.writeAsStringSync(jsonEncode(_json));
      return data;
    }
    return null;
  }

  Future<Map<String, dynamic>?> redo() async {
    if (_historyIndex < _history.length) {
      _historyIndex++;
      Map<String, dynamic> data = _history[_historyIndex];
      _json['index'] = _historyIndex;
      _file.writeAsStringSync(jsonEncode(_json));
      return data;
    }
    return null;
  }
}
