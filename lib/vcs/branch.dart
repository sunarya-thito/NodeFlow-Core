import 'package:flutter/widgets.dart';
import 'package:nodeflow/project.dart';

class Branch extends ChangeNotifier {
  final Project project;
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
