import 'package:flutter/material.dart';

class TabViewStyle {
  final MaterialStateProperty<double> headerHeight;
  final MaterialStateProperty<Color?>? headerBackgroundColor;

  const TabViewStyle({
    this.headerBackgroundColor,
    required this.headerHeight,
  });

  TabViewStyle copyWith({
    MaterialStateProperty<Color?>? backgroundColor,
    MaterialStateProperty<double>? headerHeight,
  }) {
    return TabViewStyle(
      headerBackgroundColor: backgroundColor ?? headerBackgroundColor,
      headerHeight: headerHeight ?? this.headerHeight,
    );
  }

  TabViewStyle merge(TabViewStyle? other) {
    if (other == null) {
      return this;
    }
    return copyWith(
      backgroundColor: other.headerBackgroundColor,
      headerHeight: other.headerHeight,
    );
  }
}

class TabViewGroupStyle {
  final MaterialStateProperty<Color?>? sectionHighlightColor;

  const TabViewGroupStyle({
    this.sectionHighlightColor,
  });

  TabViewGroupStyle copyWith({
    MaterialStateProperty<Color?>? sectionHighlightColor,
  }) {
    return TabViewGroupStyle(
      sectionHighlightColor: sectionHighlightColor ?? this.sectionHighlightColor,
    );
  }

  TabViewGroupStyle merge(TabViewGroupStyle? other) {
    if (other == null) {
      return this;
    }
    return copyWith(
      sectionHighlightColor: other.sectionHighlightColor,
    );
  }
}

class TabHeaderStyle {
  final MaterialStateProperty<Color?>? backgroundColor;
  final MaterialStateProperty<Color?>? outlineColor;
  final MaterialStateProperty<Color?>? placeholderColor;

  const TabHeaderStyle({
    this.backgroundColor,
    this.outlineColor,
    this.placeholderColor,
  });

  TabHeaderStyle copyWith({
    MaterialStateProperty<Color?>? backgroundColor,
    MaterialStateProperty<Color?>? outlineColor,
    MaterialStateProperty<Color?>? placeholderColor,
  }) {
    return TabHeaderStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      outlineColor: outlineColor ?? this.outlineColor,
      placeholderColor: placeholderColor ?? this.placeholderColor,
    );
  }

  TabHeaderStyle merge(TabHeaderStyle? other) {
    if (other == null) {
      return this;
    }
    return copyWith(
      backgroundColor: other.backgroundColor,
      outlineColor: other.outlineColor,
      placeholderColor: other.placeholderColor,
    );
  }
}

class TabViewTheme extends InheritedWidget {
  final TabViewStyle tabViewStyle;

  const TabViewTheme({
    Key? key,
    required this.tabViewStyle,
    required Widget child,
  }) : super(key: key, child: child);

  static TabViewTheme of(BuildContext context) {
    final TabViewTheme? result = context.dependOnInheritedWidgetOfExactType<TabViewTheme>();
    assert(result != null, 'No TabViewTheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(TabViewTheme oldWidget) => tabViewStyle != oldWidget.tabViewStyle;
}

class TabViewGroupTheme extends InheritedWidget {
  final TabViewGroupStyle tabViewGroupStyle;

  const TabViewGroupTheme({
    Key? key,
    required this.tabViewGroupStyle,
    required Widget child,
  }) : super(key: key, child: child);

  static TabViewGroupTheme of(BuildContext context) {
    final TabViewGroupTheme? result = context.dependOnInheritedWidgetOfExactType<TabViewGroupTheme>();
    assert(result != null, 'No TabViewGroupTheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(TabViewGroupTheme oldWidget) => tabViewGroupStyle != oldWidget.tabViewGroupStyle;
}

class TabHeaderTheme extends InheritedWidget {
  final TabHeaderStyle tabHeaderStyle;

  const TabHeaderTheme({
    Key? key,
    required this.tabHeaderStyle,
    required Widget child,
  }) : super(key: key, child: child);

  static TabHeaderTheme of(BuildContext context) {
    final TabHeaderTheme? result = context.dependOnInheritedWidgetOfExactType<TabHeaderTheme>();
    assert(result != null, 'No TabHeaderTheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(TabHeaderTheme oldWidget) => tabHeaderStyle != oldWidget.tabHeaderStyle;
}
