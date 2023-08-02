import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Helper class to access the [AppLocalizations] instance.
class I18n {
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations.of(context)!;
  }

  /// Prevents instantiation and extension.
  const I18n._();
}
