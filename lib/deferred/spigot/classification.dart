import 'java.dart';

/// [GetterClassification] is used to classify Java methods as getters.
/// it is used to recommend which methods should be used instead of direct casting.
abstract class GetterClassification {
  bool isGetter(JavaMethod method);
}

class StandardGetterClassification implements GetterClassification {
  @override
  bool isGetter(JavaMethod method) {
    if (method.isConstructor) return false;
    if (method.parameters.isNotEmpty) return false;
    return true;
  }
}
