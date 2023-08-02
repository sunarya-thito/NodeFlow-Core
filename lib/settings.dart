import 'package:flutter/material.dart';

class Settings extends InheritedWidget {
  final SettingsData data;
  final SettingsController controller;

  const Settings({
    Key? key,
    required this.data,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  static SettingsData of(BuildContext context) {
    final Settings? result = context.dependOnInheritedWidgetOfExactType<Settings>();
    assert(result != null, 'No Settings found in context');
    return result!.data;
  }

  static void update(BuildContext context, SettingsData data) {
    final Settings? result = context.dependOnInheritedWidgetOfExactType<Settings>();
    assert(result != null, 'No Settings found in context');
    result!.controller.data = data;
  }

  @override
  bool updateShouldNotify(covariant Settings oldWidget) => data != oldWidget.data;
}

class SettingsController extends ChangeNotifier {
  late SettingsData _data;

  SettingsData get data => _data;

  set data(SettingsData value) {
    _data = value;
    notifyListeners();
  }
}

class EnumSettingsKey<T extends Enum> extends SettingsKey<T> {
  final List<T> values;
  EnumSettingsKey(super.key, super.defaultValue, this.values);

  @override
  T getFromJson(dynamic json) {
    return values[json as int];
  }

  @override
  dynamic toJson(T value) {
    return value.index;
  }
}

class SettingsKey<T> {
  final String key;
  final T defaultValue;

  const SettingsKey(this.key, this.defaultValue);

  T getFromJson(dynamic json) {
    return json as T;
  }

  dynamic toJson(T value) {
    return value;
  }
}

class SettingsValue<T> {
  final SettingsKey<T> key;
  final T value;

  const SettingsValue(this.key, this.value);
}

class SettingsData {
  final List<SettingsValue> values;

  const SettingsData(this.values);
}
