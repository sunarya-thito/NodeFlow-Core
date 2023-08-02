import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:nodeflow/components/blueprint/parameter/label_parameter.dart';
import 'package:nodeflow/objects.dart';

import '../../blueprint_util.dart';
import '../../components/blueprint/controller.dart';

class Modifier {
  // spec: https://docs.oracle.com/javase/8/docs/api/constant-values.html#java.lang.reflect.Modifier.ABSTRACT
  static const int modifierNone = 0;
  static const int modifierAbstract = 1024;
  static const int modifierFinal = 16;
  static const int modifierInterface = 512;
  static const int modifierNative = 256;
  static const int modifierPrivate = 2;
  static const int modifierProtected = 4;
  static const int modifierPublic = 1;
  static const int modifierStatic = 8;
  static const int modifierStrict = 2048;
  static const int modifierSynchronized = 32;
  static const int modifierTransient = 128;
  static const int modifierVolatile = 64;

  static bool isModifier(int modifiers, int modifier) {
    return (modifiers & modifier) == modifier;
  }
}

class JavaLoader {
  final Directory _packageDirectory;

  const JavaLoader(this._packageDirectory);

  JavaClassLoader load(JavaClassLoader? parent, String id) {
    JavaClassLoader? existing = _load(parent, id, {});
    if (existing != null) {
      return existing;
    }
    throw Exception('Failed to load class loader for $id');
  }

  JavaClassLoader? _load(JavaClassLoader? parent, String id, Set<JavaClassLoader> loaded) {
    JavaClassLoader? existing = loaded.firstWhereOrNull((element) => element.id == id);
    if (existing != null) {
      return existing;
    }
    File file = File('${_packageDirectory.path}/$id.npc');
    if (!file.existsSync()) {
      return null;
    }
    Map<String, dynamic> json = jsonDecode(file.readAsStringSync());
    JavaClassLoader loader = JavaClassLoader._(id);
    List<String> dependencies = List<String>.from(json['dependencies']);
    for (String dependency in dependencies) {
      var classLoader = _load(parent, dependency, loaded); // the classloader parent uses "parent", do not use "loader"!
      if (classLoader == null) {
        throw Exception('Failed to load dependency $dependency');
      }
      loader._dependencies.add(classLoader);
    }
    loader._fromJson(parent, id, json);
    loaded.add(loader);
    return loader;
  }
}

class JREClassLoader extends JavaClassLoader {
  final List<JavaType> _predefinedTypes = [];

  JREClassLoader(String id) : super._(id) {
    _addPrimitiveType(const PrimitiveDescriptor('B'), const ClassDescriptor('java/lang/Byte'));
    _addPrimitiveType(const PrimitiveDescriptor('C'), const ClassDescriptor('java/lang/Character'));
    _addPrimitiveType(const PrimitiveDescriptor('D'), const ClassDescriptor('java/lang/Double'));
    _addPrimitiveType(const PrimitiveDescriptor('F'), const ClassDescriptor('java/lang/Float'));
    _addPrimitiveType(const PrimitiveDescriptor('I'), const ClassDescriptor('java/lang/Integer'));
    _addPrimitiveType(const PrimitiveDescriptor('J'), const ClassDescriptor('java/lang/Long'));
    _addPrimitiveType(const PrimitiveDescriptor('S'), const ClassDescriptor('java/lang/Short'));
    _addPrimitiveType(const PrimitiveDescriptor('Z'), const ClassDescriptor('java/lang/Boolean'));
    _addPrimitiveType(const PrimitiveDescriptor('V'), const ClassDescriptor('java/lang/Void'));
  }

  void _addPrimitiveType(PrimitiveDescriptor primitiveDescriptor, ClassDescriptor boxerDescriptor) {
    JavaBoxerClass boxerClass = JavaBoxerClass._();
    boxerClass._descriptor = boxerDescriptor;
    PrimitiveType primitiveType = PrimitiveType(this, primitiveDescriptor, boxerClass);
    boxerClass._primitiveType = primitiveType;
    _predefinedTypes.add(primitiveType);
  }

  @override
  JavaType? findByClassDescriptor(Descriptor descriptor) {
    return _predefinedTypes.firstWhereOrNull((element) => element.descriptor == descriptor) ?? super.findByClassDescriptor(descriptor);
  }
}

class JavaClassLoader {
  final String id; // maven/groupId/artifactId/version (version must be an .npc file)
  // for local jars, use the path to the nodeflow project component (.npc) path
  late JavaClassLoader? _parent;
  final List<JavaClass> _types = [];
  late int _javaVersion;
  late List<JavaClassLoader> _dependencies;

  JavaClassLoader._(this.id);

  JavaClassLoader? get parent => _parent;
  List<JavaClass> get types => List.unmodifiable(_types);
  int get javaVersion => _javaVersion;
  List<JavaClassLoader> get dependencies => List.unmodifiable(_dependencies);

  void _fromJson(JavaClassLoader? parent, String id, Map<String, dynamic> json) {
    _parent = parent;
    _javaVersion = json['javaVersion'];

    Map<String, dynamic> typeMap = json['types'];
    typeMap.forEach((key, value) {
      // key is qualified name (e.g. java/lang/Object)
      JavaClass type = JavaClass._();
      type._classLoader = this;
      type._descriptor = ClassDescriptor(key);
      _types.add(type);
    });

    for (var value in _types) {
      Map<String, dynamic> typeData = typeMap[value.descriptor];
      // load dependencies
      value._superType = Objects.nonNull(findByClassDescriptor(typeData['superType']), 'superType');
      value._interfaces = typeData['interfaces'].map((e) => Objects.nonNull(findByClassDescriptor(e), 'interface')).toList();
      // load members
      List<JavaMember> members = [];
      List<Map<String, dynamic>> fieldData = typeData['fields'];
      List<Map<String, dynamic>> methodData = typeData['methods'];
      for (var element in fieldData) {
        JavaField field = JavaField(element['name'], Objects.nonNull(findByClassDescriptor(element['type']), 'type'), element['modifiers']);
        field._declaringClass = value;
        members.add(field);
      }
      for (var element in methodData) {
        JavaMethod method = JavaMethod(
            element['name'],
            Objects.nonNull(findByClassDescriptor(element['returnType']), 'returnType'),
            element['parameters'].map((e) => JavaParameter(e['name'], Objects.nonNull(findByClassDescriptor(e), 'type'))).toList(),
            element['modifiers'],
            element['exceptions'].map((e) => Objects.nonNull(findByClassDescriptor(e), 'exception')).toList(),
            element['typeVariables'].map((e) {
              return Objects.nonNull(findByClassDescriptor(Descriptor.fromString(e)), 'bound');
            }).toList());
        method._declaringClass = value;
        members.add(method);
      }
      value._members = members;
    }
  }

  JavaType? findByClassDescriptor(Descriptor descriptor) {
    if (descriptor is WildcardDescriptor) {
      return WildcardType(this, descriptor.upperBound != null ? [Objects.nonNull(findByClassDescriptor(descriptor.upperBound!), 'upperBound')] : [],
          descriptor.lowerBound != null ? [Objects.nonNull(findByClassDescriptor(descriptor.lowerBound!), 'lowerBound')] : []);
    }
    if (descriptor is ArrayDescriptor) {
      return ArrayJavaType(this, Objects.nonNull(findByClassDescriptor(descriptor.componentType), 'elementType'));
    }
    if (descriptor is ClassDescriptor) {
      // find in types
      for (var element in _types) {
        if (element.descriptor == descriptor) return element;
      }
      // find in dependencies
      for (var element in _dependencies) {
        JavaType? type = element.findByClassDescriptor(descriptor);
        if (type != null) return type;
      }
    }
    // find in parent
    return _parent?.findByClassDescriptor(descriptor);
  }
}

abstract class Descriptor {
  String get descriptor;

  const Descriptor();

  @override
  bool operator ==(Object other) {
    return other is Descriptor && other.descriptor == descriptor;
  }

  @override
  int get hashCode => descriptor.hashCode;

  static Descriptor fromString(String descriptor) {
    if (descriptor.startsWith('[')) {
      return ArrayDescriptor(Descriptor.fromString(descriptor.substring(1)));
    } else if (descriptor.startsWith('L')) {
      return ClassDescriptor(descriptor.substring(1, descriptor.length - 1));
    } else if (descriptor.startsWith('T')) {
      return TypeVariableDescriptor(descriptor.substring(1, descriptor.length - 1));
    } else if (descriptor.startsWith('<')) {
      int index = descriptor.indexOf('>');
      if (index != -1) {
        Descriptor rawType = Descriptor.fromString(descriptor.substring(1, index));
        List<Descriptor> typeArguments = [];
        int start = index + 1;
        int depth = 0;
        for (int i = start; i < descriptor.length; i++) {
          String char = descriptor[i];
          if (char == '<') {
            depth++;
          } else if (char == '>') {
            depth--;
          } else if (char == ';' && depth == 0) {
            typeArguments.add(Descriptor.fromString(descriptor.substring(start, i)));
            start = i + 1;
          }
        }
        return ParameterizedTypeDescriptor(rawType, typeArguments);
      }
    } else if (descriptor.startsWith('(')) {
      int index = descriptor.indexOf(')');
      if (index != -1) {
        Descriptor returnType = Descriptor.fromString(descriptor.substring(index + 1));
        List<Descriptor> parameterTypes = [];
        int start = 1;
        int depth = 0;
        for (int i = start; i < descriptor.length; i++) {
          String char = descriptor[i];
          if (char == '<') {
            depth++;
          } else if (char == '>') {
            depth--;
          } else if (char == ';' && depth == 0) {
            parameterTypes.add(Descriptor.fromString(descriptor.substring(start, i)));
            start = i + 1;
          }
        }
        return MethodDescriptor(parameterTypes, returnType);
      }
    } else if (descriptor.startsWith('T')) {
      return TypeVariableDescriptor(descriptor.substring(1, descriptor.length - 1));
    } else if (descriptor == 'B') {
      return const PrimitiveDescriptor('B');
    } else if (descriptor == 'C') {
      return const PrimitiveDescriptor('C');
    } else if (descriptor == 'D') {
      return const PrimitiveDescriptor('D');
    } else if (descriptor == 'F') {
      return const PrimitiveDescriptor('F');
    } else if (descriptor == 'I') {
      return const PrimitiveDescriptor('I');
    } else if (descriptor == 'J') {
      return const PrimitiveDescriptor('J');
    } else if (descriptor == 'S') {
      return const PrimitiveDescriptor('S');
    } else if (descriptor == 'Z') {
      return const PrimitiveDescriptor('Z');
    } else if (descriptor == 'V') {
      return const PrimitiveDescriptor('V');
    }
    throw ArgumentError('Invalid descriptor: $descriptor');
  }
}

class TypeVariableDescriptor extends Descriptor {
  final String name;
  const TypeVariableDescriptor(this.name);
  @override
  String get descriptor => 'T$name;';
}

class ClassDescriptor extends Descriptor {
  final String qualifiedName;

  const ClassDescriptor(this.qualifiedName);

  @override
  String get descriptor => 'L$qualifiedName;';
}

class ArrayDescriptor extends Descriptor {
  final Descriptor componentType;

  const ArrayDescriptor(this.componentType);

  @override
  String get descriptor => '[${componentType.descriptor}';
}

class GenericArrayDescriptor extends Descriptor {
  final Descriptor componentType;

  const GenericArrayDescriptor(this.componentType);

  @override
  String get descriptor => '[${componentType.descriptor}';
}

class MethodDescriptor extends Descriptor {
  final List<Descriptor> parameterTypes;
  final Descriptor returnType;

  const MethodDescriptor(this.parameterTypes, this.returnType);

  @override
  String get descriptor {
    StringBuffer buffer = StringBuffer();
    buffer.write('(');
    for (Descriptor parameterType in parameterTypes) {
      buffer.write(parameterType.descriptor);
    }
    buffer.write(')');
    buffer.write(returnType.descriptor);
    return buffer.toString();
  }
}

class PrimitiveDescriptor extends Descriptor {
  @override
  final String descriptor;

  const PrimitiveDescriptor(this.descriptor);
}

class ParameterizedTypeDescriptor extends Descriptor {
  final Descriptor rawType;
  final List<Descriptor> typeArguments;

  const ParameterizedTypeDescriptor(this.rawType, this.typeArguments);

  @override
  String get descriptor {
    StringBuffer buffer = StringBuffer();
    buffer.write(rawType.descriptor);
    buffer.write('<');
    for (Descriptor typeArgument in typeArguments) {
      buffer.write(typeArgument.descriptor);
    }
    buffer.write('>');
    return buffer.toString();
  }
}

class WildcardDescriptor extends Descriptor {
  final Descriptor? upperBound;
  final Descriptor? lowerBound;

  const WildcardDescriptor(this.upperBound, this.lowerBound);

  @override
  String get descriptor {
    StringBuffer buffer = StringBuffer();
    buffer.write('*');
    if (upperBound != null) {
      buffer.write('+');
      buffer.write(upperBound!.descriptor);
    } else if (lowerBound != null) {
      buffer.write('-');
      buffer.write(lowerBound!.descriptor);
    }
    return buffer.toString();
  }
}

class Annotation {
  final JavaClass type;
  final Map<String, AnnotationValue> values;

  Annotation(this.type, this.values);
}

abstract class AnnotationValue {}

class StringAnnotationValue extends AnnotationValue {
  final String value;

  StringAnnotationValue(this.value);
}

class ClassAnnotationValue extends AnnotationValue {
  final JavaClass value;

  ClassAnnotationValue(this.value);
}

class EnumAnnotationValue extends AnnotationValue {
  final JavaEnum value;

  EnumAnnotationValue(this.value);
}

class ArrayAnnotationValue extends AnnotationValue {
  final List<AnnotationValue> values;

  ArrayAnnotationValue(this.values);
}

class JavaEnum {
  final JavaClass type;
  final String name;

  JavaEnum(this.type, this.name);
}

abstract class JavaType {
  // JavaType instances only exist once per classloader, so when a JavaType with the same identity but different classloader is compared, it will return false

  const JavaType();

  JavaClassLoader get classLoader;

  Descriptor get descriptor;

  String get typeName;

  String get simpleName;

  bool isAssignableFrom(JavaType type);

  Map<JavaClass, Annotation> get annotations;
}

void _addMethods(List<JavaMethod> methods, JavaClass type) {
  for (var element in type.methods) {
    if (!_canAccess(type, element)) {
      continue;
    }
    if (!_methodExists(methods, element.name, element.parameters.map((e) => e.type).toList())) {
      methods.add(element);
    }
  }
}

void _addFields(List<JavaField> fields, JavaClass type) {
  for (var element in type.fields) {
    if (!_canAccess(type, element)) {
      continue;
    }
    if (!_fieldExists(fields, element.name)) {
      fields.add(element);
    }
  }
}

bool _canAccess(JavaClass accessor, JavaMember member) {
  if (Modifier.isModifier(member.modifiers, Modifier.modifierPublic)) {
    return true;
  }
  var declaringClass = member.declaringClass;
  if (declaringClass == null) {
    return false;
  }
  if (accessor == declaringClass) {
    return true;
  }
  if (Modifier.isModifier(member.modifiers, Modifier.modifierPrivate)) {
    return accessor == declaringClass;
  }
  if (Modifier.isModifier(member.modifiers, Modifier.modifierProtected)) {
    return accessor.isAssignableFrom(declaringClass) || declaringClass.isAssignableFrom(accessor) || declaringClass.packageName == accessor.packageName;
  }
  return declaringClass.packageName == accessor.packageName; // package-private
}

bool _fieldExists(List<JavaField> fields, String name) {
  for (var element in fields) {
    if (element.name == name) {
      return true;
    }
  }
  return false;
}

bool _methodExists(List<JavaMethod> methods, String name, List<JavaType> parameters) {
  for (var element in methods) {
    if (element.name == name) {
      List<JavaType> existingParameters = element.parameters.map((e) => e.type).toList();
      if (existingParameters.length != parameters.length) {
        continue;
      }
      bool match = true;
      for (int i = 0; i < existingParameters.length; i++) {
        if (existingParameters[i] != parameters[i]) {
          match = false;
          break;
        }
      }
      if (match) {
        return true;
      }
    }
  }
  return false;
}

class JavaClass extends JavaType with JavaMember, GenericDeclaration {
  static const ClassDescriptor objectDescriptor = ClassDescriptor('java.lang.Object');
  static JavaClass findRealIdentity(JavaType type) {
    if (type is JavaClass) {
      return type;
    }
    if (type is ParameterizedType) {}
    if (type is TypeVariable) {}
    if (type is WildcardType) {}
    if (type is GenericArrayType) {}
    throw ArgumentError('invalid type: $type');
  }

  late List<TypeVariable> _typeParameters;
  @override
  List<TypeVariable> get typeParameters => List.unmodifiable(_typeParameters);

  late JavaClassLoader _classLoader;
  @override
  JavaClassLoader get classLoader => _classLoader;

  late int _modifiers;
  @override
  int get modifiers => _modifiers;

  late ClassDescriptor _descriptor;
  @override
  ClassDescriptor get descriptor => _descriptor;

  late JavaType? _superType;
  JavaType? get superType => _superType;

  late List<JavaType> _interfaces;
  List<JavaType> get interfaces => List.unmodifiable(_interfaces);

  late Map<JavaClass, Annotation> _annotations;
  @override
  Map<JavaClass, Annotation> get annotations => Map.unmodifiable(_annotations);

  late List<JavaMember> _members;
  Iterable<JavaMember> get members => List.unmodifiable(_members);

  Iterable<JavaMethod> get constructors => members.whereType<JavaMethod>().where((element) => element.isConstructor);
  Iterable<JavaMethod> get methods => members.whereType<JavaMethod>().whereNot((element) => element.isConstructor);
  Iterable<JavaField> get fields => members.whereType<JavaField>();

  JavaType get nonNullSuperType {
    return superType ?? Objects.nonNull(classLoader.findByClassDescriptor(objectDescriptor), 'java.lang.Object');
  }

  Iterable<JavaMethod> getMethods(JavaType accessor) {
    // all public methods including from super types and interfaces, must not duplicate
    List<JavaMethod> methods = [];
    _addMethods(methods, this);
    for (var element in interfaces) {
      _addMethods(methods, findRealIdentity(element));
    }
    _addMethods(methods, findRealIdentity(nonNullSuperType));
    return methods;
  }

  Iterable<JavaField> getFields(JavaType accessor) {
    // all public fields including from super types and interfaces, must not duplicate
    List<JavaField> fields = [];
    _addFields(fields, this);
    for (var element in interfaces) {
      _addFields(fields, findRealIdentity(element));
    }
    _addFields(fields, findRealIdentity(nonNullSuperType));
    return fields;
  }

  Iterable<JavaMethod> getConstructors(JavaClass accessor) {
    // all public constructors NOT including from super types and interfaces, must not duplicate
    return constructors.where((element) => _canAccess(accessor, element));
  }

  JavaClass._();

  @override
  bool isAssignableFrom(JavaType type) {
    if (type is JavaClass) {
      return _isAssignableFrom(type);
    }
    return false;
  }

  bool _isAssignableFrom(JavaClass type) {
    if (this == type) {
      return true;
    }
    if (type.superType != null && isAssignableFrom(type.nonNullSuperType)) {
      return true;
    }
    for (var element in type.interfaces) {
      if (isAssignableFrom(element)) {
        return true;
      }
    }
    return false;
  }

  @override
  String toString() {
    return descriptor.descriptor;
  }

  @override
  bool operator ==(Object other) => other is JavaClass && descriptor == other.descriptor;

  @override
  int get hashCode => descriptor.hashCode;

  @override
  String get typeName {
    String qualifiedName = descriptor.qualifiedName; // e.g. "java/lang/String"
    return qualifiedName.replaceAll('/', '.'); // e.g. "java.lang.String"
  }

  String? get packageName {
    String name = typeName;
    int index = name.lastIndexOf('.');
    if (index != -1) {
      return name.substring(0, index);
    }
    return null;
  }

  @override
  String get simpleName {
    // separate package name and simple name (also for inner classes)
    String name = typeName;
    int index = name.lastIndexOf('.');
    if (index != -1) {
      name = name.substring(index + 1);
    }
    index = name.lastIndexOf('\$');
    if (index != -1) {
      name = name.substring(index + 1);
    }
    return name;
  }

  @override
  String get name => typeName;

  JavaClass _clone() {
    JavaClass clone = JavaClass._();
    clone._classLoader = _classLoader;
    clone._modifiers = _modifiers;
    clone._declaringClass = _declaringClass;
    clone._descriptor = _descriptor;
    clone._superType = _superType;
    clone._interfaces = _interfaces;
    clone._annotations = _annotations;
    clone._members = _members;
    return clone;
  }

  @override
  JavaClass declareIn(Map<TypeVariable, JavaType> typeArguments) {
    JavaClass clone = _clone();
    JavaType? superType = clone.superType;
    if (superType is ParameterizedType) {
      clone._superType = ParameterizedType(
          superType.classLoader,
          superType.actualTypeArguments.map((e) {
            if (e is TypeVariable) {
              return typeArguments[e] ?? e;
            }
            return e;
          }).toList(),
          superType.rawType,
          superType.ownerType);
    }
    for (var i = 0; i < clone._interfaces.length; i++) {
      JavaType interface = clone._interfaces[i];
      if (interface is ParameterizedType) {
        clone._interfaces[i] = ParameterizedType(
            interface.classLoader,
            interface.actualTypeArguments.map((e) {
              if (e is TypeVariable) {
                return typeArguments[e] ?? e;
              }
              return e;
            }).toList(),
            interface.rawType,
            interface.ownerType);
      }
    }
    for (var i = 0; i < clone._members.length; i++) {
      JavaMember member = clone._members[i];
      clone._members[i] = member.declareIn(typeArguments);
      member._declaringClass = clone;
    }
    return clone;
  }
}

class JavaBoxerClass extends JavaClass {
  late final JavaType _primitiveType;

  JavaBoxerClass._() : super._();

  @override
  bool _isAssignableFrom(JavaClass type) {
    if (type == _primitiveType) {
      return true;
    }
    return super._isAssignableFrom(type);
  }
}

class ArrayJavaType extends JavaType {
  // Array#length is not a field, but rather a language feature that implemented differently
  // than other fields. Therefore, we need to handle it manually in the compiler.
  @override
  final JavaClassLoader classLoader;
  final JavaType elementType;

  ArrayJavaType(this.classLoader, this.elementType);

  @override
  Descriptor get descriptor => ArrayDescriptor(elementType.descriptor);

  @override
  String get typeName => '${elementType.typeName}[]';

  @override
  String get simpleName => '${elementType.simpleName}[]';

  @override
  bool isAssignableFrom(JavaType type) {
    if (type is ArrayJavaType) {
      return elementType.isAssignableFrom(type.elementType);
    }
    return false;
  }

  @override
  final Map<JavaClass, Annotation> annotations = const {}; // automatically extends Object
}

class PrimitiveType extends JavaType {
  static final Map<String, Set<String>> _primitiveTransformMapping = {
    // in the compiler, this is handled by the boxing methods
    // byte
    'B': {'I', 'J', 'F', 'D'},
    // char
    'C': {'I', 'J', 'F', 'D'},
    // double
    'D': {'D'},
    // float
    'F': {'F', 'D'},
    // int
    'I': {'I', 'J', 'F', 'D'},
    // long
    'J': {'J', 'F', 'D'},
    // short
    'S': {'I', 'J', 'F', 'D'},
    // boolean
    'Z': {'Z'},
  };
  static final Map<String, String> _primitiveDescriptorMap = {
    'V': 'void',
    'Z': 'boolean',
    'B': 'byte',
    'C': 'char',
    'S': 'short',
    'I': 'int',
    'J': 'long',
    'F': 'float',
    'D': 'double'
  };
  @override
  final JavaClassLoader classLoader;

  @override
  final PrimitiveDescriptor descriptor;

  final JavaBoxerClass boxerClass;

  PrimitiveType(this.classLoader, this.descriptor, this.boxerClass);

  @override
  bool isAssignableFrom(JavaType type) {
    if (type is PrimitiveType) {
      if (this == type) {
        return true;
      }
      Set<String>? transformMapping = _primitiveTransformMapping[descriptor];
      if (transformMapping != null) {
        return transformMapping.contains(type.descriptor.descriptor);
      }
      return false;
    }
    if (type is JavaBoxerClass) {
      return isAssignableFrom(type._primitiveType);
    }
    return false;
  }

  @override
  String get typeName => _primitiveDescriptorMap[descriptor]!;

  @override
  String get simpleName => typeName;

  @override
  final Map<JavaClass, Annotation> annotations = const {};
}

class TypeVariable extends JavaType {
  final List<JavaType> bounds;
  final GenericDeclaration genericDeclaration;
  final String name;

  @override
  final JavaClassLoader classLoader;
  @override
  final Map<JavaClass, Annotation> annotations;

  TypeVariable(this.classLoader, this.bounds, this.genericDeclaration, this.name, this.annotations);

  @override
  TypeVariableDescriptor get descriptor => TypeVariableDescriptor(name);

  @override
  bool isAssignableFrom(JavaType type) {
    throw ArgumentError('Type variables cannot be used in isAssignableFrom, if this is a GenericDeclaration, use declareIn first');
  }

  @override
  String get typeName => name;

  @override
  String get simpleName => name;

  TypeVariable declareIn(Map<TypeVariable, JavaType> map) {
    List<JavaType> newBounds = bounds.map((e) {
      if (e is TypeVariable) {
        return map[e] ?? e;
      }
      return e;
    }).toList();
    return TypeVariable(classLoader, newBounds, genericDeclaration, name, annotations);
  }
}

class ParameterizedType extends JavaType {
  final List<JavaType> actualTypeArguments;
  final JavaType rawType;
  final JavaType? ownerType;

  @override
  final JavaClassLoader classLoader;

  ParameterizedType(this.classLoader, this.actualTypeArguments, this.rawType, this.ownerType);

  @override
  ParameterizedTypeDescriptor get descriptor => ParameterizedTypeDescriptor(rawType.descriptor, actualTypeArguments.map((e) => e.descriptor).toList());

  @override
  bool isAssignableFrom(JavaType type) {
    if (type is ParameterizedType) {
      if (rawType.isAssignableFrom(type.rawType)) {
        if (actualTypeArguments.length == type.actualTypeArguments.length) {
          for (int i = 0; i < actualTypeArguments.length; i++) {
            if (!actualTypeArguments[i].isAssignableFrom(type.actualTypeArguments[i])) {
              return false;
            }
          }
          return true;
        }
      }
    }
    return false;
  }

  @override
  String get typeName => '${rawType.typeName}<${actualTypeArguments.map((e) => e.typeName).join(', ')}>';

  @override
  String get simpleName => rawType.simpleName;

  @override
  Map<JavaClass, Annotation> get annotations => rawType.annotations;
}

class GenericArrayType extends JavaType {
  final JavaType genericComponentType;

  @override
  Map<JavaClass, Annotation> annotations = const {};

  @override
  final JavaClassLoader classLoader;

  GenericArrayType(this.classLoader, this.genericComponentType);

  @override
  GenericArrayDescriptor get descriptor => GenericArrayDescriptor(genericComponentType.descriptor);

  @override
  bool isAssignableFrom(JavaType type) {
    if (type is GenericArrayType) {
      return genericComponentType.isAssignableFrom(type.genericComponentType);
    }
    return false;
  }

  @override
  String get simpleName => '${genericComponentType.simpleName}[]';

  @override
  String get typeName => '${genericComponentType.typeName}[]';
}

class WildcardType extends JavaType {
  final List<JavaType> upperBounds;
  final List<JavaType> lowerBounds;

  @override
  final Map<JavaClass, Annotation> annotations = const {};

  @override
  final JavaClassLoader classLoader;

  WildcardType(this.classLoader, this.upperBounds, this.lowerBounds);

  @override
  Descriptor get descriptor =>
      WildcardDescriptor(upperBounds.isEmpty ? null : upperBounds[0].descriptor, lowerBounds.isEmpty ? null : lowerBounds[0].descriptor);

  @override
  bool isAssignableFrom(JavaType type) {
    if (type is WildcardType) {
      if (upperBounds.length == type.upperBounds.length && lowerBounds.length == type.lowerBounds.length) {
        for (int i = 0; i < upperBounds.length; i++) {
          if (!upperBounds[i].isAssignableFrom(type.upperBounds[i])) {
            return false;
          }
        }
        for (int i = 0; i < lowerBounds.length; i++) {
          if (!lowerBounds[i].isAssignableFrom(type.lowerBounds[i])) {
            return false;
          }
        }
        return true;
      }
    }
    return false;
  }

  @override
  String get simpleName {
    StringBuffer builder = StringBuffer();
    List<JavaType> bounds = lowerBounds;
    if (lowerBounds.isNotEmpty) {
      builder.write("? super ");
    } else {
      if (upperBounds.isNotEmpty && upperBounds[0].descriptor != JavaClass.objectDescriptor) {
        builder.write("? extends ");
        bounds = upperBounds;
      } else {
        return "?";
      }
    }

    bool first = true;
    for (JavaType bound in bounds) {
      if (!first) {
        builder.write(" & ");
      }
      first = false;
      builder.write(bound.simpleName);
    }
    return builder.toString();
  }

  @override
  String get typeName {
    StringBuffer builder = StringBuffer();
    List<JavaType> bounds = lowerBounds;
    if (lowerBounds.isNotEmpty) {
      builder.write("? super ");
    } else {
      if (upperBounds.isNotEmpty && upperBounds[0].descriptor != JavaClass.objectDescriptor) {
        builder.write("? extends ");
        bounds = upperBounds;
      } else {
        return "?";
      }
    }

    bool first = true;
    for (JavaType bound in bounds) {
      if (!first) {
        builder.write(" & ");
      }
      first = false;
      builder.write(bound.typeName);
    }
    return builder.toString();
  }
}

mixin GenericDeclaration {
  Iterable<TypeVariable> get typeParameters;
}

mixin JavaMember {
  int get modifiers;
  String get name;
  late JavaClass _declaringClass;
  JavaClass? get declaringClass => _declaringClass;

  JavaMember declareIn(Map<TypeVariable, JavaType> typeArguments);
}

class JavaParameter {
  final String name;
  final JavaType type;

  const JavaParameter(this.name, this.type);

  JavaParameter.fromJson(JavaClassLoader loader, Map<String, dynamic> json)
      : this(json['name'], Objects.nonNull(loader.findByClassDescriptor(json['type']), 'type'));
}

class JavaMethod with JavaMember, GenericDeclaration {
  @override
  final String name;
  final JavaType returnType;
  final List<JavaParameter> parameters;
  @override
  final int modifiers;
  final List<JavaType> exceptions;
  @override
  final List<TypeVariable> typeParameters;

  JavaMethod(this.name, this.returnType, this.parameters, this.modifiers, this.exceptions, this.typeParameters);

  bool get isConstructor => name == '<init>';

  @override
  JavaMember declareIn(Map<TypeVariable, JavaType> typeArguments) {
    JavaType returnType = this.returnType is TypeVariable ? typeArguments[this.returnType] ?? this.returnType : this.returnType;
    List<JavaParameter> parameters =
        this.parameters.map((e) => JavaParameter(e.name, e.type is TypeVariable ? typeArguments[e.type] ?? e.type : e.type)).toList();
    List<JavaType> exceptions = this.exceptions.map((e) => e is TypeVariable ? typeArguments[e] ?? e : e).toList();
    List<TypeVariable> typeParameters = this.typeParameters.map((e) => e.declareIn(typeArguments)).toList();
    var javaMethod = JavaMethod(name, returnType, parameters, modifiers, exceptions, typeParameters);
    javaMethod._declaringClass = _declaringClass;
    return javaMethod;
  }
}

class JavaField with JavaMember {
  @override
  final String name;
  final JavaType type;
  @override
  final int modifiers;

  JavaField(this.name, this.type, this.modifiers);

  @override
  JavaMember declareIn(Map<TypeVariable, JavaType> typeArguments) {
    JavaType type = this.type is TypeVariable ? typeArguments[this.type] ?? this.type : this.type;
    var javaField = JavaField(name, type, modifiers);
    javaField._declaringClass = _declaringClass;
    return javaField;
  }
}

String nodePortId(String className, String parameterName, PortType type) {
  return '$className.$parameterName#${type.name}';
}

class JavaParameterNodeParameterProvider extends NodeParameterProvider {
  final JavaParameter parameter;
  @override
  final bool hasInput, hasOutput;
  @override
  final Optional defaultConstantValue;

  JavaParameterNodeParameterProvider(this.parameter, this.hasInput, this.hasOutput, {this.defaultConstantValue = const Optional.empty()});

  @override
  Widget createWidget(NodeParameter parameter) {
    return LabelParameter(label: Text((parameter.provider as JavaParameterNodeParameterProvider).parameter.name));
  }

  @override
  bool get growable => parameter.type is ArrayJavaType;

  @override
  bool isAssignable(NodeParameter from, NodeParameter to) {
    NodeParameterProvider fromProvider = from.provider;
    NodeParameterProvider toProvider = to.provider;
    if (fromProvider is JavaParameterNodeParameterProvider && toProvider is JavaParameterNodeParameterProvider) {
      return fromProvider.parameter.type.isAssignableFrom(toProvider.parameter.type);
    }
    return false;
  }

  @override
  Color? getInputColor([Brightness brightness = Brightness.light]) {
    return ColorStorage.generateColor(parameter.type.descriptor.hashCode, brightness);
  }

  @override
  Color? getOutputColor([Brightness brightness = Brightness.light]) {
    return ColorStorage.generateColor(parameter.type.descriptor.hashCode, brightness);
  }

  @override
  PortBounds get inputBounds => hasInput ? PortBounds.single : PortBounds.none;

  @override
  PortBounds get outputBounds => hasOutput ? PortBounds.multiple : PortBounds.none;
}

class MethodInvocationNodeProvider extends NodeProvider {
  MethodInvocationNodeProvider(super.id, super.name, super.description, super.category);

  @override
  List<NodeParameterProvider> get parameters => throw UnimplementedError();
}

class FieldAccessNodeProvider extends NodeProvider {
  final JavaField field;
  @override
  final List<NodeParameterProvider> parameters = [];

  FieldAccessNodeProvider(this.field, super.id, super.name, super.description, super.category) {
    parameters.add(JavaParameterNodeParameterProvider(JavaParameter('this', field.type), true, true));
    parameters.add(JavaParameterNodeParameterProvider(JavaParameter('that', field.type), true, true));
    parameters.add(JavaParameterNodeParameterProvider(JavaParameter('thus', field.type), true, true));
  }
}
