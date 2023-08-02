import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class ShortcutKey {
  static ShortcutKey fromString(String s) {
    final parts = s.split('+');
    final key = parts.last.toLowerCase(); // this could be A, B, or even F10 (the f10 key)
    final modifiers = parts.sublist(0, parts.length - 1);
    return ShortcutKey(
      LogicalKeyboardKey.knownLogicalKeys.firstWhere((element) => element.keyLabel.toLowerCase() == key),
      modifiers.map((e) => _modifierKeyFromString(e)).toSet(),
    );
  }

  static ModifierKey _modifierKeyFromString(String s) {
    switch (s.toLowerCase()) {
      case 'ctrl':
        return ModifierKey.controlModifier;
      case 'shift':
        return ModifierKey.shiftModifier;
      case 'alt':
        return ModifierKey.altModifier;
      case 'meta':
        return ModifierKey.metaModifier;
      default:
        throw Exception('Invalid modifier key: $s');
    }
  }

  final LogicalKeyboardKey key;
  final Set<ModifierKey> modifiers;

  ShortcutKey(this.key, [this.modifiers = const {}]);

  @override
  bool operator ==(Object other) {
    if (other is ShortcutKey) {
      return other.key == key && const SetEquality().equals(other.modifiers, modifiers);
    }
    return false;
  }

  bool accept(RawKeyEvent event) {
    return event.logicalKey == key &&
        event.isControlPressed == modifiers.contains(ModifierKey.controlModifier) &&
        event.isShiftPressed == modifiers.contains(ModifierKey.shiftModifier) &&
        event.isAltPressed == modifiers.contains(ModifierKey.altModifier) &&
        event.isMetaPressed == modifiers.contains(ModifierKey.metaModifier);
  }

  SingleActivator toSingleActivator() {
    return SingleActivator(
      key,
      alt: modifiers.contains(ModifierKey.altModifier),
      control: modifiers.contains(ModifierKey.controlModifier),
      shift: modifiers.contains(ModifierKey.shiftModifier),
      meta: modifiers.contains(ModifierKey.metaModifier),
    );
  }

  @override
  String toString() {
    String builder = '';
    if (modifiers.contains(ModifierKey.controlModifier)) {
      builder += 'Ctrl+';
    }
    if (modifiers.contains(ModifierKey.shiftModifier)) {
      builder += 'Shift+';
    }
    if (modifiers.contains(ModifierKey.altModifier)) {
      builder += 'Alt+';
    }
    if (modifiers.contains(ModifierKey.metaModifier)) {
      builder += 'Meta+';
    }
    builder += key.keyLabel;
    return builder;
  }

  @override
  int get hashCode => key.hashCode ^ modifiers.hashCode;
}
