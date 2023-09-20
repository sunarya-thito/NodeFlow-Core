import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../i18n.dart';
import 'compact_theme.dart';

extension CompactDataStatelessAccessor on StatelessWidget {
  CompactTheme app(BuildContext context) {
    return CompactData.of(context).theme;
  }

  AppLocalizations i18n(BuildContext context) {
    return I18n.of(context);
  }
}

extension CompactDataStatefulAccessor on State {
  CompactTheme get app {
    return CompactData.of(context).theme;
  }

  AppLocalizations get i18n {
    return I18n.of(context);
  }
}

class TextBuilder extends StatelessWidget {
  final I18nString text;

  const TextBuilder(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(text(i18n(context)));
  }
}

class CompactData extends InheritedWidget {
  static CompactData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CompactData>()!;
  }

  final CompactTheme theme;

  const CompactData.dark({
    Key? key,
    required Widget child,
    this.theme = const CompactTheme.dark(),
  }) : super(key: key, child: child);

  const CompactData.light({
    Key? key,
    required Widget child,
    this.theme = const CompactTheme.light(),
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant CompactData oldWidget) {
    return oldWidget.theme != theme;
  }

  static Color rgbo(int r, int g, int b, double opacity) {
    return Color.fromARGB((opacity * 255).toInt(), r, g, b);
  }

  static Color orgb(double opacity, int r, int g, int b) {
    return Color.fromARGB((opacity * 255).toInt(), r, g, b);
  }

  static Color rgb(int r, int g, int b) {
    return Color.fromARGB(255, r, g, b);
  }

  static Color argb(int a, int r, int g, int b) {
    return Color.fromARGB(a, r, g, b);
  }

  static Color solid(int color) {
    return Color(0xFF000000 + color);
  }

  static Color alpha(int color, double opacity) {
    return Color(0xFF000000 + color).withOpacity(opacity);
  }
}
