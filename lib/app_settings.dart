import 'package:flutter/material.dart';
import 'package:nodeflow/settings.dart';

class AppSettings extends StatefulWidget {
  final Map<String, dynamic> file;
  final Widget child;

  const AppSettings({
    Key? key,
    required this.file,
    required this.child,
  }) : super(key: key);

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

final SettingsCategory kSettingsCategoryAppearance = SettingsCategory(const Icon(Icons.remove_red_eye), (i18n) => i18n.settingsAppearance);

final EntrySettingsKey<ThemeMode> kSettingsThemeMode = EntrySettingsKey<ThemeMode>(
  kSettingsCategoryAppearance,
  'theme_mode',
  (i18n) => i18n.settingsAppearanceTheme,
  0,
  [
    EntryItem((i18n) => i18n.menubarViewThemeDark, ThemeMode.dark),
    EntryItem((i18n) => i18n.menubarViewThemeLight, ThemeMode.light),
  ],
);

class _AppSettingsState extends State<AppSettings> {
  late SettingsData _data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // use this instead of initState() to fetch external settings (e.g. from a project module)
    _data = SettingsData([
      SettingsValue.empty(kSettingsThemeMode),
    ]);
    _data.load(widget.file);
  }

  @override
  Widget build(BuildContext context) {
    return Settings(
      data: _data,
      onSettingsChanged: (data) {
        setState(() {
          _data = data;
        });
      },
      child: widget.child,
    );
  }
}
