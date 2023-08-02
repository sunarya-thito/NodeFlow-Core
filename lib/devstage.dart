import 'package:flutter/material.dart';
import 'package:nodeflow/components/blueprint/parameter/label_parameter.dart';
import 'package:nodeflow/components/locale_widget.dart';

import 'components/blueprint/controller.dart';

class TestProvider extends NodeProvider {
  TestProvider(super.id, super.name, super.description, super.category);

  @override
  List<NodeParameterProvider> get parameters => [
        SimpleNodeTitleProvider(title: 'Title Example'.asTextWidget(), subTitle: 'This is subtitle'.asTextWidget(), icon: Icon(Icons.accessibility_sharp)),
        TestParameterProvider(),
        SimpleNodeTitleProvider(
          title: 'Title Example'.asTextWidget(),
        ),
      ];
}

class TestParameterProvider extends NodeParameterProvider {
  @override
  Widget createWidget(NodeParameter parameter) {
    return LabelParameter(label: Text("This is a test"));
  }

  @override
  Optional get defaultConstantValue => const Optional.empty();

  @override
  Color? getInputColor([Brightness brightness = Brightness.light]) {
    return null;
  }

  @override
  Color? getOutputColor([Brightness brightness = Brightness.light]) {
    return null;
  }

  @override
  bool get growable => true;

  @override
  PortBounds get inputBounds => PortBounds.multiple;

  @override
  bool isAssignableTo(NodeParameter to) {
    return true;
  }

  @override
  PortBounds get outputBounds => PortBounds.multiple;
}
