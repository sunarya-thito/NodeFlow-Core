import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:nodeflow/components/focusable.dart';
import 'package:nodeflow/theme/compact_data.dart';
import 'package:nodeflow/ui_util.dart';

import '../../blueprint_util.dart';
import 'blueprint.dart';

class NodeProviderCategory {
  final String name;
  final String description;
  final NodeProviderCategory? parent;

  NodeProviderCategory(this.name, this.description, [this.parent]);
}

abstract class NodeProvider {
  final String id;
  final String name;
  final String description;
  final NodeProviderCategory category;

  NodeProvider(this.id, this.name, this.description, this.category);

  Node createNode(IdStorage storage, {String? name, Offset? position}) {
    return Node(
        storage.requestId(),
        this,
        parameters
            .map(
              (e) => NodeParameterGroup(e, [
                NodeParameter(e, storage.requestId(), e.defaultConstantValue),
              ]),
            )
            .toList(),
        name: name,
        position: position);
  }

  Node parseNode(Map<String, dynamic> json) {
    return Node.fromJson(this, json);
  }

  List<NodeParameterProvider> get parameters;
}

class SimpleNodeTitleProvider extends NodeTitleProvider {
  SimpleNodeTitleProvider({Widget? icon, required Widget title, Widget? subTitle}) : super(icon: icon, title: title, subTitle: subTitle);

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
  bool get growable => false;

  @override
  PortBounds get inputBounds => PortBounds.none;

  @override
  bool isAssignableTo(NodeParameter to) {
    return false;
  }

  @override
  PortBounds get outputBounds => PortBounds.none;
}

abstract class NodeTitleProvider extends NodeParameterProvider {
  final Widget? icon;
  final Widget title;
  final Widget? subTitle;

  NodeTitleProvider({this.icon, required this.title, this.subTitle});

  @override
  Widget createWidget(NodeParameter parameter) {
    return NodeTitleWidget(
      title: title,
      subTitle: subTitle,
      icon: icon,
    );
  }
}

class NodeTitleWidget extends StatelessWidget {
  final NodeParameter parameter;
  final Widget? icon;
  final Widget title;
  final Widget? subTitle;

  const NodeTitleWidget({Key? key, required this.parameter, required this.title, this.subTitle, this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final generateColor = ColorStorage.generateColor(parameter.node.provider.id.hashCode, app(context).brightness);
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1,
          focalRadius: 1,
          focal: Alignment.bottomRight,
          colors: [
            generateColor.calculateDarkerColor(0.5),
            generateColor,
            generateColor.calculateBrighterColor(0.1),
          ],
          stops: const [0, 0.6, 1],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: icon == null && subTitle == null ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
          mainAxisAlignment: icon == null && subTitle == null ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (icon != null) IconTheme(data: IconThemeData(color: app(context).primaryTextColor), child: icon!),
            if (icon != null) const SizedBox(width: 6),
            Column(
              crossAxisAlignment: icon == null && subTitle == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                title,
                if (subTitle != null) DefaultTextStyle(style: TextStyle(fontSize: 12, color: app(context).secondaryTextColor), child: subTitle!),
              ],
            ),
            if (icon != null || subTitle != null) const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

// enum for how much amount of inputs/outputs a parameter can have
enum PortBounds {
  // only one input/output
  single,
  // multiple inputs/outputs
  multiple,
  // no inputs/outputs
  none,
}

abstract class NodeParameterProvider {
  bool get growable;
  bool get hasInput => inputBounds != PortBounds.none;
  bool get hasOutput => outputBounds != PortBounds.none;
  PortBounds get inputBounds;
  PortBounds get outputBounds;
  Color? getInputColor([Brightness brightness = Brightness.light]);
  Color? getOutputColor([Brightness brightness = Brightness.light]);
  Optional get defaultConstantValue;
  Widget createWidget(NodeParameter parameter);
  bool isAssignableTo(NodeParameter to);
  NodeParameter parseJson(Map<String, dynamic> json) {
    return NodeParameter.fromJson(this, json);
  }
}

class ExecutionNodeParameterProvider extends NodeParameterProvider {
  @override
  Widget createWidget(NodeParameter parameter) {
    throw UnimplementedError('ExecutionNodeParameterProvider does not have a widget');
  }

  @override
  bool get growable => false;

  @override
  bool isAssignableTo(NodeParameter to) {
    return to.provider is ExecutionNodeParameterProvider;
  }

  @override
  Optional get defaultConstantValue => Optional.empty();

  @override
  Color? getInputColor([Brightness brightness = Brightness.light]) {
    return null;
  }

  @override
  Color? getOutputColor([Brightness brightness = Brightness.light]) {
    return null;
  }

  @override
  PortBounds get inputBounds => PortBounds.multiple;

  @override
  PortBounds get outputBounds => PortBounds.single;
}

class Node extends ChangeNotifier implements Selectable, Focusable {
  final NodeProvider provider;
  final List<NodeParameterGroup> parameters;

  final String id;
  String? _name; // custom name for the node, if null, use the node provider name
  Offset _position;
  bool _selected = false;

  Size? size;

  Node(this.id, this.provider, this.parameters, {String? name, Offset? position, bool selected = false})
      : _position = position ?? Offset.zero,
        _name = name,
        _selected = selected {
    for (var element in parameters) {
      element._node = this;
      for (var parameter in element.parameters) {
        parameter._node = this;
      }
    }
  }

  Offset get position => _position;
  String get name => _name ?? provider.name;
  @override
  bool get selected => _selected;

  set name(String? value) {
    _name = value;
    notifyListeners();
  }

  set position(Offset value) {
    _position = value;
    notifyListeners();
  }

  @override
  set selected(bool value) {
    if (value == _selected) return;
    _selected = value;
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider.id,
      'parameters': parameters.map((e) => e.toJson()).toList(),
      'selected': selected,
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
    };
  }

  factory Node.fromJson(NodeProvider provider, Map<String, dynamic> json) {
    List<NodeParameterProvider> parameters = provider.parameters;
    return Node(
      json['id'],
      provider,
      json['parameters'].mapIndexed((index, e) => NodeParameterGroup.fromJson(parameters[index], e)).toList(),
      name: json['name'],
      position: Offset(json['position']['x'], json['position']['y']),
      selected: json['selected'],
    );
  }

  @override
  void move(Offset delta) {
    position += delta;
  }

  @override
  Rect get boundingBox => _position & (size ?? Size.zero);
}

enum PortType {
  input,
  output;
}

enum PortShape {
  circle,
  triangle,
  diamond,
  rhombus;
}

class NodeParameterGroup extends ChangeNotifier {
  final NodeParameterProvider provider;
  final List<NodeParameter> _parameters;

  late Node _node;

  NodeParameterGroup(this.provider, this._parameters);

  Node get node => _node;

  List<NodeParameter> get parameters => List.unmodifiable(_parameters);

  void moveParameter(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) {
      return;
    }
    _parameters.insert(newIndex, _parameters.removeAt(oldIndex));
    notifyListeners();
  }

  void swapParameters(int index1, int index2) {
    if (index1 == index2) {
      return;
    }
    NodeParameter temp = _parameters[index1];
    _parameters[index1] = _parameters[index2];
    _parameters[index2] = temp;
    notifyListeners();
  }

  void insertParameter(int index, IdStorage storage) {
    _parameters.insert(index, NodeParameter(provider, storage.requestId(), provider.defaultConstantValue));
    notifyListeners();
  }

  void addParameter(IdStorage storage) {
    _parameters.add(NodeParameter(provider, storage.requestId(), provider.defaultConstantValue));
    notifyListeners();
  }

  void removeParameter(NodeParameter parameter) {
    if (_parameters.remove(parameter)) {
      notifyListeners();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'parameters': parameters.map((e) => e.toJson()).toList(),
    };
  }

  factory NodeParameterGroup.fromJson(NodeParameterProvider provider, Map<String, dynamic> json) {
    return NodeParameterGroup(
      provider,
      json['parameters'].map((e) => provider.parseJson(e)).toList(),
    );
  }
}

class ConstantValue extends ChangeNotifier {
  List<dynamic> _valueHolder = [];

  ConstantValue? _boundTo;

  void bind(ConstantValue other) {
    if (_boundTo != null) {
      _boundTo!.unbind(this);
    }
    _boundTo = other;
    _valueHolder = other._valueHolder;
    other.addListener(notifyListeners);
  }

  void unbind(ConstantValue other) {
    if (_boundTo == other) {
      _boundTo = null;
      _valueHolder = _valueHolder.toList(); // unbind, but keep the value
      other.removeListener(notifyListeners);
    }
  }

  void clear() {
    _valueHolder.clear();
    notifyListeners();
  }

  bool get hasValue => _valueHolder.isNotEmpty;

  dynamic get value {
    assert(_valueHolder.isNotEmpty);
    return _valueHolder[0];
  }

  set value(dynamic value) {
    if (_valueHolder.isEmpty) {
      _valueHolder.add(value);
    } else {
      if (_valueHolder[0] == value) {
        return;
      }
      _valueHolder[0] = value;
    }
    notifyListeners();
  }
}

class NodeParameter {
  final String id;
  final NodeParameterProvider provider;
  final ConstantValue constantValue = ConstantValue();
  late Node _node;

  NodeParameter(this.provider, this.id, Optional constantValue) {
    if (constantValue.hasValue) {
      this.constantValue.value = constantValue.value;
    }
  }

  Offset? outputPosition;
  Offset? inputPosition;

  Color? getInputColor([Brightness brightness = Brightness.light]) {
    return provider.getInputColor(brightness);
  }

  Color? getOutputColor([Brightness brightness = Brightness.light]) {
    return provider.getOutputColor(brightness);
  }

  String get inputId => '$id#input';
  String get outputId => '$id#output';

  Node get node => _node;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (constantValue.hasValue) 'constantValue': constantValue.value,
    };
  }

  bool isAssignableTo(NodeParameter other) {
    return provider.isAssignableTo(other);
  }

  factory NodeParameter.fromJson(NodeParameterProvider provider, Map<String, dynamic> json) {
    return NodeParameter(
        provider, json['id'], json.containsKey('constantValue') ? Optional.of(json['constantValue']) : const Optional.empty()); // TODO constant value
  }
}

class Bendpoint extends ChangeNotifier implements Selectable, Focusable {
  bool _selected;
  double _dx;
  double _dy;
  Bendpoint(this._dx, this._dy, [this._selected = false]);
  Bendpoint.fromOffset(Offset offset, [this._selected = false])
      : _dx = offset.dx,
        _dy = offset.dy;

  double get dx => _dx;
  double get dy => _dy;
  @override
  bool get selected => _selected;

  @override
  set selected(bool selected) {
    _selected = selected;
    notifyListeners();
  }

  Offset get offset => Offset(_dx, _dy);

  set offset(Offset offset) {
    _dx = offset.dx;
    _dy = offset.dy;
    notifyListeners();
  }

  set dx(double dx) {
    _dx = dx;
    notifyListeners();
  }

  set dy(double dy) {
    _dy = dy;
    notifyListeners();
  }

  @override
  void move(Offset delta) {
    _dx += delta.dx;
    _dy += delta.dy;
    notifyListeners();
  }

  @override
  Rect get boundingBox => Rect.fromCenter(center: offset, width: 10, height: 10);
}

class NodeLink extends ChangeNotifier implements Focusable {
  final NodeParameter from;
  final NodeParameter to;
  final NodeLinkState state = NodeLinkState();

  List<Bendpoint> _bendPoints; // bend points are relative to the from and to ports

  NodeLink(this.from, this.to, [List<Bendpoint>? bendPoints]) : _bendPoints = bendPoints ?? [];

  List<Bendpoint> get bendPoints => List.unmodifiable(_bendPoints);

  @override
  bool operator ==(Object other) {
    if (other is NodeLink) {
      return other.from == from && other.to == to;
    }
    return false;
  }

  set bendPoints(List<Bendpoint> bendPoints) {
    _bendPoints = bendPoints;
    notifyListeners();
  }

  void addBendPoint(Bendpoint point) {
    _bendPoints.add(point);
    point.addListener(notifyListeners);
    notifyListeners();
  }

  void insertBendPoint(int index, Bendpoint point) {
    _bendPoints.insert(index, point);
    point.addListener(notifyListeners);
    notifyListeners();
  }

  Bendpoint removeBendPointAt(int index) {
    Bendpoint bendPoint = _bendPoints.removeAt(index);
    bendPoint.removeListener(notifyListeners);
    notifyListeners();
    return bendPoint;
  }

  void removeBendPoint(Bendpoint point) {
    if (_bendPoints.remove(point)) {
      point.removeListener(notifyListeners);
      notifyListeners();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from.outputId,
      'to': to.inputId,
      'bendPoints': bendPoints.map((e) => {'x': e.dx, 'y': e.dy}).toList(),
    };
  }

  static NodeLink fromJson(BlueprintNodeController controller, Map<String, dynamic> json) {
    return NodeLink(
      controller.findParameterOutput(json['from']),
      controller.findParameterInput(json['to']),
      json['bendPoints'].map((e) => Bendpoint(e['x'], e['y'])).toList(),
    );
  }

  @override
  int get hashCode => from.hashCode ^ to.hashCode;

  @override
  Rect get boundingBox {
    Offset outputPosition = from.outputPosition ?? Offset.zero;
    Offset inputPosition = to.inputPosition ?? Offset.zero;
    const Size size = Size(10, 10);
    Rect rect = Rect.fromPoints(outputPosition, inputPosition);
    rect = rect.inflate(size.width / 2);
    return rect;
  }
}

class NodeLinkState {
  double arrowSize = 0;
  int midpointIndex = 0;
  bool isHovering = false;
  Offset? cursorOffset;
}

class Optional<T> {
  final List<T> _valueHolder;

  const Optional() : _valueHolder = const [];

  Optional.of(T value) : _valueHolder = [value];

  const Optional.empty() : _valueHolder = const [];

  bool get hasValue => _valueHolder.isNotEmpty;

  T get value {
    assert(_valueHolder.isNotEmpty);
    return _valueHolder[0];
  }

  set value(T value) {
    if (_valueHolder.isEmpty) {
      _valueHolder.add(value);
    } else {
      if (_valueHolder[0] == value) {
        return;
      }
      _valueHolder[0] = value;
    }
  }
}

typedef ConstantValueSerializer = Map<String, dynamic>? Function(dynamic value);
typedef ConstantValueDeserializer = Optional Function(Map<String, dynamic> json);

class ConstantValueParser {
  final ConstantValueSerializer serializer;
  final ConstantValueDeserializer deserializer;

  const ConstantValueParser(this.serializer, this.deserializer);
}

class BlueprintRegistry {
  final List<NodeProvider> _providers = [];
  final List<ConstantValueParser> _constantValueParsers = [
    ConstantValueParser(
      (value) => value is String ? {'stringValue': value} : null,
      (json) => json.containsKey('stringValue') ? Optional.of(json['stringValue']) : const Optional(),
    ),
    ConstantValueParser(
      (value) => value is int ? {'intValue': value} : null,
      (json) => json.containsKey('intValue') ? Optional.of(json['intValue']) : const Optional(),
    ),
    ConstantValueParser(
      (value) => value is double ? {'doubleValue': value} : null,
      (json) => json.containsKey('doubleValue') ? Optional.of(json['doubleValue']) : const Optional(),
    ),
    ConstantValueParser(
      (value) => value is bool ? {'boolValue': value} : null,
      (json) => json.containsKey('boolValue') ? Optional.of(json['boolValue']) : const Optional(),
    ),
  ];

  dynamic deserializeConstantValue(Map<String, dynamic> json) {
    for (var parser in _constantValueParsers) {
      var result = parser.deserializer(json);
      if (result.hasValue) {
        return result.value;
      }
    }
    throw Exception('No deserializer found for $json');
  }

  Map<String, dynamic> serializeConstantValue(dynamic value) {
    for (var parser in _constantValueParsers) {
      var result = parser.serializer(value);
      if (result != null) {
        return result;
      }
    }
    throw Exception('No serializer found for $value');
  }

  void registerConstantValueParser(ConstantValueParser parser) {
    _constantValueParsers.add(parser);
  }

  void removeConstantValueParser(ConstantValueParser parser) {
    _constantValueParsers.remove(parser);
  }

  NodeProvider? findProvider(String id) {
    return _providers.firstWhereOrNull((element) => element.id == id);
  }

  void registerProvider(NodeProvider provider) {
    if (_providers.any((element) => element.id == provider.id)) {
      throw Exception('Provider with id ${provider.id} already registered');
    }
    _providers.add(provider);
  }
}

abstract class Selectable extends Focusable {
  bool selected = false;
  void move(Offset delta);
}

class NodeGroup extends ChangeNotifier implements Selectable {
  String _id;
  String _name;
  Rect _rect;
  bool _selected = false;
  final BlueprintController controller;

  String get id => _id;
  String get name => _name;

  NodeGroup({
    required String id,
    required String name,
    required Rect rect,
    required this.controller,
  })  : _id = id,
        _rect = rect,
        _name = name;

  NodeGroup.fromJson(
    this.controller,
    Map<String, dynamic> json,
  )   : _rect = Rect.fromLTWH(
          json['x'],
          json['y'],
          json['width'],
          json['height'],
        ),
        _id = json['id'],
        _name = json['name'];

  Map<String, dynamic> toJson() {
    return {
      'x': _rect.left,
      'y': _rect.top,
      'width': _rect.width,
      'height': _rect.height,
      'id': _id,
      'name': _name,
    };
  }

  @override
  bool get selected => _selected;

  Rect get rect => _rect;

  set rect(Rect value) {
    _rect = value;
    notifyListeners();
  }

  @override
  set selected(bool value) {
    _selected = value;
    notifyListeners();
  }

  @override
  void move(Offset delta) {
    _rect = _rect.shift(delta);
    Set<Selectable> selectables = controller.findSelectables(_rect, SelectionRule.grabWhole);
    for (var selectable in selectables) {
      selectable.move(delta);
    }
    notifyListeners();
  }

  @override
  Rect get boundingBox => _rect;
}

class BlueprintController extends ChangeNotifier {
  late final BlueprintNodeController nodeController;
  final BlueprintLinkController linkController = BlueprintLinkController();
  late final BlueprintGroupController groupController;
  final IdStorage _idStorage = IdStorage();

  bool multiSelect = false; // does not need to notify listeners because it does not affect the UI
  double _zoom = kDefaultZoom;
  Offset _offset = kDefaultOffset;
  double? _snapToGrid = 20;

  BlueprintController() {
    nodeController = BlueprintNodeController(_idStorage);
    groupController = BlueprintGroupController(this);
  }

  double get zoom => _zoom;
  Offset get offset => _offset;
  double? get snapToGrid => _snapToGrid;

  Map<String, dynamic> toJson() {
    return {
      'nodes': nodeController.toJson(),
      'links': linkController.toJson(),
      'groups': groupController.toJson(),
      'zoom': _zoom,
      'offset': {
        'x': _offset.dx,
        'y': _offset.dy,
      },
      'snapToGrid': _snapToGrid,
      'idStorage': _idStorage.getNextId(),
    };
  }

  void loadFromJson(BlueprintRegistry registry, Map<String, dynamic> json) {
    nodeController.loadFromJson(registry, json['nodes']);
    linkController.loadFromJson(nodeController, json['links']);
    groupController.loadFromJson(this, json['groups']);
    _zoom = json['zoom'];
    _offset = Offset(json['offset']['x'], json['offset']['y']);
    _snapToGrid = json['snapToGrid'];
    _idStorage.setNextId(json['idStorage']);
    notifyListeners();
  }

  Set<Selectable> findSelectables(Rect rect, SelectionRule rule) {
    Set<Selectable> result = {};
    result.addAll(nodeController.findSelectables(rect, rule));
    result.addAll(linkController.findSelectables(rect, rule));
    result.addAll(groupController.findSelectables(rect, rule));
    return result;
  }

  List<Selectable> get selectables {
    List<Selectable> result = [];
    result.addAll(nodeController._nodes);
    result.addAll(linkController._links.map((e) => e.bendPoints).expand((element) => element));
    result.addAll(groupController._groups);
    return result;
  }

  void clearSelection() {
    for (var selectable in selectables) {
      selectable.selected = false;
    }
    notifyListeners();
  }

  /// Used to move the selection by a given delta
  void shiftSelection(Selectable? primarySelection, Offset delta) {
    if (primarySelection != null && !primarySelection.selected) {
      return;
    }

    for (var selectable in selectables) {
      if (selectable.selected) {
        selectable.move(delta);
      }
    }
  }

  void zoomTowardsCenter(Offset centerLocation, double delta) {
    var newZoom = _zoom * delta;
    var newOffset = _offset + (centerLocation - _offset) * (1 - delta);
    zoom = newZoom;
    offset = newOffset;
  }

  void select(Selectable selectable) {
    if (multiSelect) {
      selectable.selected = !selectable.selected;
    } else {
      for (var element in selectables) {
        if (element == selectable) {
          continue;
        }
        element.selected = false;
      }
      selectable.selected = true;
    }
    notifyListeners();
  }

  void selectAll(Iterable<Selectable> selectables) {
    if (multiSelect) {
      for (var selectable in selectables) {
        selectable.selected = true;
      }
    } else {
      for (var element in this.selectables) {
        if (selectables.contains(element)) {
          continue;
        }
        element.selected = false;
      }
      for (var selectable in selectables) {
        selectable.selected = true;
      }
    }
    notifyListeners();
  }

  set zoom(double value) {
    if (_zoom == value) {
      return;
    }
    _zoom = value;
    notifyListeners();
  }

  set offset(Offset value) {
    if (_offset == value) {
      return;
    }
    _offset = value;
    notifyListeners();
  }

  set snapToGrid(double? value) {
    if (_snapToGrid == value) {
      return;
    }
    _snapToGrid = value;
    // if (value != null) {
    //   for (var node in _nodes) {
    //     node._position = node._position.translate(
    //       (node._position.dx / value).round() * value - node._position.dx,
    //       (node._position.dy / value).round() * value - node._position.dy,
    //     );
    //   }
    // }
    notifyListeners();
  }
}

class BlueprintNodeController extends ChangeNotifier {
  final IdStorage _idStorage;
  final List<Node> _nodes = [];

  BlueprintNodeController(this._idStorage);

  List<Node> get nodes => List.unmodifiable(_nodes);

  Set<Selectable> findSelectables(Rect area, SelectionRule rule) {
    Set<Selectable> result = {};
    // find selectable in nodes
    for (var node in _nodes) {
      if (node.size == null) {
        continue;
      }
      if (rule == SelectionRule.grabPart) {
        if ((node._position & node.size!).overlaps(area)) {
          result.add(node);
        }
      } else if (rule == SelectionRule.grabWhole) {
        if (area.contains(node._position) && area.contains(node._position + node.size!.offset)) {
          result.add(node);
        }
      }
    }
    return result;
  }

  void loadFromJson(BlueprintRegistry registry, Map<String, dynamic> json) {
    _nodes.clear();
    for (Map<String, dynamic> nodeJson in json['nodes']) {
      _nodes.add(registry._providers.firstWhere((element) => element.id == nodeJson['provider']).parseNode(nodeJson));
    }
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'nodes': nodes.map((e) => e.toJson()).toList(),
    };
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  NodeParameter findParameter(String id) {
    for (var node in _nodes) {
      for (var parameterGroup in node.parameters) {
        for (var parameter in parameterGroup.parameters) {
          if (parameter.id == id) {
            return parameter;
          }
        }
      }
    }
    throw Exception('Parameter with id $id not found');
  }

  NodeParameter findParameterOutput(String id) {
    return findParameter('$id#output');
  }

  NodeParameter findParameterInput(String id) {
    return findParameter('$id#input');
  }

  Node addNode(NodeProvider provider, {String? name, Offset? position}) {
    var node = provider.createNode(_idStorage, name: name, position: position);
    _nodes.add(node);
    notifyListeners();
    return node;
  }

  void removeNode(Node node) {
    if (_nodes.remove(node)) {
      notifyListeners();
    }
  }
}

class BlueprintGroupController extends ChangeNotifier {
  final BlueprintController controller;
  final List<NodeGroup> _groups = [];

  BlueprintGroupController(this.controller);

  NodeGroup addGroup(String name, Rect rect) {
    NodeGroup group = NodeGroup(id: controller._idStorage.requestId(), name: name, rect: rect, controller: controller);
    _groups.add(group);
    notifyListeners();
    return group;
  }

  void removeGroup(NodeGroup group) {
    if (_groups.remove(group)) {
      notifyListeners();
    }
  }

  void clear() {
    _groups.clear();
    notifyListeners();
  }

  Set<Selectable> findSelectables(Rect area, SelectionRule rule) {
    var result = <Selectable>{};
    for (var group in _groups) {
      if (rule == SelectionRule.grabPart) {
        if (group.rect.overlaps(area)) {
          result.add(group);
        }
      } else if (rule == SelectionRule.grabWhole) {
        if (area.contains(group.rect.topLeft) && area.contains(group.rect.bottomRight)) {
          result.add(group);
        }
      }
    }
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'groups': _groups.map((e) => e.toJson()).toList(),
    };
  }

  void loadFromJson(BlueprintController controller, Map<String, dynamic> json) {
    _groups.clear();
    for (Map<String, dynamic> groupJson in json['groups']) {
      var group = NodeGroup.fromJson(controller, groupJson);
      _groups.add(group);
    }
    notifyListeners();
  }
}

class BlueprintLinkController extends ChangeNotifier {
  final List<NodeLink> _links = [];

  List<NodeLink> get links => List.unmodifiable(_links);

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'links': links.map((e) => e.toJson()).toList(),
    };
  }

  void loadFromJson(BlueprintNodeController blueprint, Map<String, dynamic> json) {
    _links.clear();
    for (Map<String, dynamic> linkJson in json['links']) {
      var from = blueprint.findParameterOutput(linkJson['from']);
      var to = blueprint.findParameterInput(linkJson['to']);
      var nodeLink = NodeLink(from, to);
      _links.add(nodeLink);
      nodeLink.addListener(notifyListeners);
    }
    notifyListeners();
  }

  Set<Selectable> findSelectables(Rect area, SelectionRule rule) {
    Set<Selectable> result = {};
    // find selectable in link bendpoints
    for (var link in _links) {
      for (var bendPoint in link.bendPoints) {
        if (area.contains(bendPoint.offset)) {
          result.add(bendPoint);
        }
      }
    }
    return result;
  }

  NodeLink? addLink(NodeParameter from, NodeParameter to) {
    // TODO check for multi linking
    // reset existing link for "to" parameter since it can only have one link
    if (to.provider.inputBounds == PortBounds.none || from.provider.outputBounds == PortBounds.none) {
      return null;
    }

    if (!from.isAssignableTo(to) || !to.isAssignableTo(from)) {
      return null;
    }

    if (from == to) {
      return null;
    }

    if (from.node == to.node) {
      return null;
    }

    if (to.provider.inputBounds == PortBounds.single) {
      _removeLinkWhere((link) => link.to == to);
    }

    if (from.provider.outputBounds == PortBounds.single) {
      _removeLinkWhere((link) => link.from == from);
    }

    var nodeLink = NodeLink(from, to);
    if (_links.contains(nodeLink)) {
      return null;
    }
    _links.add(nodeLink);
    nodeLink.addListener(notifyListeners);

    // bind constant value from -> to
    var fromConstantValue = from.constantValue;
    var toConstantValue = to.constantValue;

    toConstantValue.bind(fromConstantValue);

    notifyListeners();
    return nodeLink;
  }

  void removeLinks(List<NodeLink> links) {
    bool changed = false;
    for (var link in links) {
      if (_links.remove(link)) {
        link.removeListener(notifyListeners);

        // unbind
        var fromConstantValue = link.from.constantValue;
        var toConstantValue = link.to.constantValue;

        toConstantValue.unbind(fromConstantValue);

        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void removeLink(NodeLink link) {
    if (_links.remove(link)) {
      link.removeListener(notifyListeners);

      // unbind
      var fromConstantValue = link.from.constantValue;
      var toConstantValue = link.to.constantValue;

      toConstantValue.unbind(fromConstantValue);

      notifyListeners();
    }
  }

  void _removeLinkWhere(bool Function(NodeLink link) test) {
    _links.removeWhere((element) {
      if (test(element)) {
        element.removeListener(notifyListeners);

        // unbind
        var fromConstantValue = element.from.constantValue;
        var toConstantValue = element.to.constantValue;

        toConstantValue.unbind(fromConstantValue);

        return true;
      }
      return false;
    });
  }

  void removeLinkWhere(bool Function(NodeLink link) test) {
    _removeLinkWhere(test);
    notifyListeners();
  }
}
