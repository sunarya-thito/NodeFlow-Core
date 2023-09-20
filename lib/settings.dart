import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:nodeflow/components/form/form.dart';
import 'package:nodeflow/i18n.dart';

class Settings extends InheritedWidget {
  final SettingsData data;
  final void Function(SettingsData data) onSettingsChanged;

  const Settings({
    Key? key,
    required this.data,
    required this.onSettingsChanged,
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
    result!.onSettingsChanged(data);
  }

  static void updateValue<T>(BuildContext context, SettingsKey<T> key, T value) {
    final Settings? result = context.dependOnInheritedWidgetOfExactType<Settings>();
    assert(result != null, 'No Settings found in context');
    result!.onSettingsChanged(result.data.copyWith([SettingsValue(key, value)]));
  }

  @override
  bool updateShouldNotify(covariant Settings oldWidget) => data != oldWidget.data || onSettingsChanged != oldWidget.onSettingsChanged;
}

class EntryItem<T> {
  final I18nString name;
  final T value;

  const EntryItem(this.name, this.value);
}

class EntrySettingsKey<T> extends SettingsKey<int> {
  final List<EntryItem<T>> values;

  const EntrySettingsKey(SettingsCategory category, String key, I18nString display, int defaultIndex, this.values)
      : super(category, key, display, defaultIndex);

  @override
  int getFromJson(dynamic json) {
    return json as int;
  }

  @override
  dynamic toJson(int value) {
    return value;
  }

  @override
  Widget build(BuildContext context, SettingsData data, SettingsValue<int> value) {
    return Container();
  }
}

abstract class SettingsKey<T> {
  final SettingsCategory category;
  final String key;
  final I18nString display;
  final T defaultValue;
  final Validator<T>? validator;

  const SettingsKey(this.category, this.key, this.display, this.defaultValue, {this.validator});

  T getFromJson(dynamic json) {
    return json as T;
  }

  dynamic toJson(T value) {
    return value;
  }

  Widget build(BuildContext context, SettingsData data, SettingsValue<T> value);
}

class SettingsCategory {
  final Widget icon;
  final I18nString display;

  const SettingsCategory(this.icon, this.display);
}

class SettingsValue<T> {
  final SettingsKey<T> key;
  final bool _hasValue;
  late T _value;

  SettingsValue.empty(this.key) : _hasValue = false;

  SettingsValue(this.key, T value)
      : _hasValue = true,
        _value = value;

  T get value {
    if (!_hasValue) {
      return key.defaultValue;
    }
    return _value;
  }

  @override
  bool operator ==(Object other) {
    if (other is SettingsValue<T>) {
      return key == other.key && _hasValue == other._hasValue && _value == other._value;
    }
    return false;
  }

  @override
  int get hashCode {
    if (_hasValue) {
      return key.hashCode ^ _value.hashCode;
    }
    return key.hashCode;
  }
}

class InlineSettingsField extends StatelessWidget {
  final SettingsKey settingsKey;
  final Widget child;

  const InlineSettingsField({
    Key? key,
    required this.settingsKey,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(settingsKey.display(context.i18n)),
        ),
        child,
      ],
    );
  }
}

// class EntryFieldValue extends StatelessWidget {
//   final void Function(int value) onChanged;
// }

class SettingsField<T> extends StatelessWidget {
  final SettingsKey<T> settingsKey;
  final Widget child;

  const SettingsField({
    Key? key,
    required this.settingsKey,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(settingsKey.display(context.i18n)),
        child,
      ],
    );
  }
}

class SettingsData {
  final List<SettingsValue> values;

  SettingsData(List<SettingsValue> values) : values = List.unmodifiable(values);

  SettingsData addMissing(SettingsData other) {
    List<SettingsValue> newValues = [];
    for (SettingsValue value in values) {
      int index = other.values.indexWhere((element) => element.key.key == value.key.key);
      if (index != -1) {
        newValues.add(other.values[index]);
      } else {
        newValues.add(value);
      }
    }
    return SettingsData(newValues);
  }

  SettingsData load(Map<String, dynamic> json) {
    List<SettingsValue> newValues = [];
    for (SettingsValue value in values) {
      dynamic jsonValue = json[value.key.key];
      if (jsonValue != null) {
        newValues.add(SettingsValue(value.key, value.key.getFromJson(jsonValue)));
      } else {
        newValues.add(value);
      }
    }
    return SettingsData(newValues);
  }

  SettingsData restoreDefaults() {
    List<SettingsValue> newValues = [];
    for (SettingsValue value in values) {
      newValues.add(SettingsValue.empty(value.key));
    }
    return SettingsData(newValues);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    for (SettingsValue value in values) {
      json[value.key.key] = value.key.toJson(value.value);
    }
    return json;
  }

  SettingsData copyWith(List<SettingsValue> values) {
    List<SettingsValue> newValues = List.from(this.values);
    // overwrite existing values
    for (SettingsValue value in values) {
      int index = newValues.indexWhere((element) => element.key.key == value.key.key);
      if (index != -1) {
        newValues[index] = value;
      } else {
        newValues.add(value);
      }
    }
    return SettingsData(newValues);
  }

  @override
  bool operator ==(Object other) {
    if (other is SettingsData) {
      return const ListEquality().equals(values, other.values);
    }
    return false;
  }

  @override
  int get hashCode {
    return const ListEquality().hash(values);
  }
}
