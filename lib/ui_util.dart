import 'dart:typed_data';

import 'package:flutter/material.dart';

final Uint8List kTransparentImage = Uint8List.fromList(
  <int>[
    0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00, //
    0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x21, 0xf9, 0x04, 0x01, 0x00, //
    0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, //
    0x00, 0x02, 0x01, 0x44, 0x00, 0x3B
  ],
);

const int _iconStart = 0xe000;
const int _iconRange = 0xf4dd;
IconData iconFromHashcode(int hash) {
  int codePoint = _iconStart + (hash % (_iconRange - _iconStart));
  return IconData(codePoint, fontFamily: 'MaterialIcons');
}

extension NotificationExtension on State {
  void fireEvent(Notification notification) {
    context.dispatchNotification(notification);
  }
}

extension StatelessNotificationExtension on StatelessWidget {
  void fireEvent(BuildContext context, Notification notification) {
    context.dispatchNotification(notification);
  }
}

extension StringContainsCheck on String {
  bool containsPartially(String other) {
    // the "other" string split into words
    // and then each word is checked if it is contained in this string
    // in the same order as in the "other" string
    // doesn't matter if there are other words in between
    // this does not check for word boundaries (e.g. "test" is contained in "testing")
    var trim = other.trim();
    if (trim.isEmpty) {
      return true;
    }
    List<String> split = trim.split(' ');
    int lastMatch = 0;
    int count = 0;
    for (int i = 0; i < split.length; i++) {
      String word = split[i];
      if (word.isEmpty) {
        continue;
      }
      int index = indexOf(word, lastMatch);
      if (index == -1) {
        break;
      }
      lastMatch = index + word.length;
      count++;
    }
    return count > 0;
  }
}

List<Widget> joinWidgets(List<Widget> widgets, Widget Function() separatorBuilder) {
  final List<Widget> result = [];
  for (int i = 0; i < widgets.length; i++) {
    if (i > 0) {
      result.add(separatorBuilder());
    }
    result.add(widgets[i]);
  }
  return result;
}

extension GlobalPosition on BuildContext {
  Offset get globalPosition {
    var renderObject = findRenderObject();
    if (renderObject == null) {
      return Offset.zero;
    }
    final RenderBox renderBox = renderObject as RenderBox;
    return renderBox.localToGlobal(Offset.zero);
  }

  Offset localToGlobal(Offset localPosition) {
    var renderObject = findRenderObject();
    if (renderObject == null) {
      return Offset.zero;
    }
    final RenderBox renderBox = renderObject as RenderBox;
    return renderBox.localToGlobal(localPosition);
  }

  Offset globalToLocal(Offset globalPosition) {
    var renderObject = findRenderObject();
    if (renderObject == null) {
      return Offset.zero;
    }
    final RenderBox renderBox = renderObject as RenderBox;
    return renderBox.globalToLocal(globalPosition);
  }

  Size get localSize {
    try {
      var size = this.size;
      if (size != null) {
        return size;
      }
    } catch (ignored) {}
    var renderObject = findRenderObject();
    if (renderObject == null) {
      return Size.zero;
    }
    final RenderBox renderBox = renderObject as RenderBox;
    if (!renderBox.hasSize) {
      return Size.zero;
    }
    return renderBox.size;
  }
}

extension SizeToOffset on Size {
  Offset get offset => Offset(width, height);
  Offset toOffset({double? width, double? height}) => Offset(width ?? this.width, height ?? this.height);
}

extension OffsetToSize on Offset {
  Size get size => Size(dx, dy);
  Size toSize({double? width, double? height}) => Size(width ?? this.dx, height ?? this.dy);
}
