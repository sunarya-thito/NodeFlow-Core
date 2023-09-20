import 'package:flutter/material.dart';
import 'package:nodeflow/components/state_delivery.dart';

typedef RouterBuilder = RouterPage Function(RouterPath path);

abstract class RouterPage {
  const RouterPage();
}

class RouterPageBuilder extends RouterPage {
  final Widget Function(BuildContext context) builder;

  const RouterPageBuilder(this.builder);
}

class RedirectRouterPage extends RouterPage {
  final List<RouterPath> paths;

  const RedirectRouterPage(this.paths);
}

class RouteBuilder extends StatelessWidget {
  final Map<PathRequest, RouterBuilder> routes;

  const RouteBuilder({
    Key? key,
    required this.routes,
  }) : super(key: key);

  RouterBuilder _getByRoutePath(RouterPath path) {
    if (path is EmptyPath) {
      return routes[DefaultPathRequest] ?? (p) => RouterPageBuilder((context) => const SizedBox());
    }
    for (var entry in routes.entries) {
      if (entry.key.matches(path)) {
        return entry.value;
      }
    }
    return routes[NotFoundPathRequest] ?? (p) => RouterPageBuilder((context) => const SizedBox());
  }

  @override
  Widget build(BuildContext context) {
    RouterPathScope scope = RouterPathScope.of(context);
    List<RouterPath> paths = List.of(scope.paths);
    RouterPage page;
    // if (paths.isEmpty) {
    //   page = _getByRoutePath(null)(const EmptyPath());
    // } else {
    //   RouterPath currentPath = paths.first;
    //   paths = paths.sublist(1);
    //   page = _getByRoutePath(currentPath)(currentPath);
    // }
    // while (page is RedirectRouterPage) {
    //   paths = paths + page.paths;
    //   page = _getByRoutePath(paths.first)(paths.first);
    //   paths = paths.sublist(1);
    // }
    while (true) {
      if (paths.isEmpty) {
        paths = [const EmptyPath()];
      }
      page = _getByRoutePath(paths.first)(paths.first);
      paths.removeAt(0);
      if (page is RedirectRouterPage) {
        paths.insertAll(0, page.paths);
      } else {
        break;
      }
    }
    paths = paths.isEmpty ? const [EmptyPath()] : paths.sublist(1);
    return RouterPathScope(
      depth: scope.depth + 1,
      paths: paths,
      child: Builder(builder: (context) {
        return (page as RouterPageBuilder).builder(context);
      }),
    );
  }

  static String toStringPath(List<RouterPath> paths) {
    return paths.map((e) => e.toString()).join('/');
  }
}

class RouterPathScope extends InheritedWidget {
  final int depth;
  final List<RouterPath> paths;

  const RouterPathScope({
    Key? key,
    required this.depth,
    required this.paths,
    required Widget child,
  }) : super(key: key, child: child);

  static RouterPathScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RouterPathScope>()!;
  }

  @override
  bool updateShouldNotify(RouterPathScope oldWidget) {
    return paths != oldWidget.paths || depth != oldWidget.depth;
  }
}

abstract class PathRequest {
  const PathRequest();

  bool matches(RouterPath path);
}

class _404PathRequest extends PathRequest {
  const _404PathRequest();

  @override
  bool matches(RouterPath path) {
    return false;
  }
}

class _DefaultPathRequest extends PathRequest {
  const _DefaultPathRequest();

  @override
  bool matches(RouterPath path) {
    return path is EmptyPath;
  }
}

class _KeyPathRequest extends PathRequest {
  final String pathName;

  const _KeyPathRequest(this.pathName);

  @override
  bool matches(RouterPath path) {
    return path is KeyPath && path.pathName == pathName;
  }
}

const PathRequest DataPathRequest = _DataPathRequest();
const PathRequest DefaultPathRequest = _DefaultPathRequest();
const PathRequest NotFoundPathRequest = _404PathRequest();

PathRequest KeyPathRequest(String pathName) {
  return _KeyPathRequest(pathName);
}

class _DataPathRequest<T> extends PathRequest {
  const _DataPathRequest();

  @override
  bool matches(RouterPath path) {
    return path is DataPath<T>;
  }
}

abstract class RouterPath {
  const RouterPath();

  bool isPath(String pathName) {
    return this is KeyPath && (this as KeyPath).pathName == pathName;
  }
}

class EmptyPath extends RouterPath {
  const EmptyPath();

  @override
  String toString() {
    return '';
  }
}

class KeyPath extends RouterPath {
  final String pathName;

  const KeyPath(this.pathName);

  @override
  String toString() {
    return pathName;
  }
}

class DataPath<T> extends RouterPath {
  final T data;

  const DataPath({
    required this.data,
  });

  @override
  String toString() {
    return ':$data';
  }
}

class RouterNavigator extends StatefulWidget {
  final Widget child;
  final List<RouterPath> initialPaths;

  RouterNavigator({
    Key? key,
    required this.child,
    this.initialPaths = const [EmptyPath()],
  })  : assert(initialPaths.isNotEmpty),
        super(key: key);

  @override
  RouterNavigatorState createState() => RouterNavigatorState();

  static RouterNavigatorState _of(BuildContext context) {
    return StateData.of<RouterNavigatorState>(context);
  }

  static void replace(BuildContext context, List<RouterPath> paths) {
    RouterNavigator._of(context).replace(paths, RouterPathScope.of(context).depth);
  }

  static void push(BuildContext context, RouterPath path) {
    RouterNavigator._of(context).push(path);
  }

  static void pop(BuildContext context) {
    RouterNavigator._of(context).pop();
  }

  static void go(BuildContext context, List<RouterPath> paths) {
    RouterNavigator._of(context).go(paths);
  }
}

extension RouterNavigatorExtension on BuildContext {
  void pushPath(RouterPath path) {
    RouterNavigator.push(this, path);
  }

  void popPath() {
    RouterNavigator.pop(this);
  }

  void goPaths(List<RouterPath> paths) {
    RouterNavigator.go(this, paths);
  }

  void replacePaths(List<RouterPath> paths) {
    RouterNavigator.replace(this, paths);
  }
}

class RouterNavigatorState extends State<RouterNavigator> {
  late List<RouterPath> _paths;

  @override
  void initState() {
    super.initState();
    _paths = List.of(widget.initialPaths);
    if (_paths.isEmpty) {
      _paths = [const EmptyPath()];
    }
  }

  void push(RouterPath path) {
    if (!mounted) return;
    setState(() {
      _paths.add(path);
    });
  }

  void pop() {
    if (!mounted) return;
    setState(() {
      _paths.removeLast();
    });
  }

  void go(List<RouterPath> paths) {
    if (!mounted) return;
    setState(() {
      if (paths.isEmpty) {
        paths = [const EmptyPath()];
      }
      _paths = List.of(paths);
    });
  }

  void replace(List<RouterPath> paths, int depth) {
    if (!mounted) return;
    if (paths.isEmpty) {
      paths = [const EmptyPath()];
    }
    setState(() {
      List<RouterPath> newPaths = [];
      for (int i = 0; i < depth; i++) {
        if (i >= _paths.length) {
          newPaths.add(const EmptyPath());
          continue;
        }
        newPaths.add(_paths[i]);
      }
      _paths = newPaths + paths;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StateData(
      state: this,
      child: RouterPathScope(
        depth: 0,
        paths: _paths,
        child: widget.child,
      ),
    );
  }
}
