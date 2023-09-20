import 'package:flutter/widgets.dart';

import '../project/project_manager.dart';

class Branch extends ChangeNotifier {
  final ProjectSnapshot project;
  final String id;
  String _name;

  Branch(this.project, this.id, this._name);

  String get name => _name;

  set name(String value) {
    _name = value;
    notifyListeners();
  }

  static Branch of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BranchContext>()!.branch;
  }
}

class BranchContext extends InheritedWidget {
  final Branch branch;

  const BranchContext({Key? key, required this.branch, required Widget child}) : super(key: key, child: child);

  static BranchContext of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BranchContext>()!;
  }

  @override
  bool updateShouldNotify(covariant BranchContext oldWidget) {
    return branch != oldWidget.branch;
  }
}
