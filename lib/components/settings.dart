import 'package:flutter/material.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/components/menu/custom_menu_anchor.dart';
import 'package:nodeflow/settings.dart';
import 'package:nodeflow/theme/compact_data.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsData? _data;
  final CustomMenuController _menuController = CustomMenuController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data == null) {
      _data = Settings.of(context);
    } else {
      _data!.addMissing(Settings.of(context));
    }
  }

  bool get hasChanges {
    SettingsData parent = Settings.of(context);
    return parent != _data;
  }

  void _restoreDefaults() {
    setState(() {
      _data = _data!.restoreDefaults();
    });
  }

  void _reset() {
    setState(() {
      _data = Settings.of(context);
    });
  }

  void _apply() {
    Settings.update(context, _data!);
  }

  @override
  Widget build(BuildContext context) {
    Map<SettingsCategory, List<SettingsValue>> categories = {};
    for (SettingsValue value in _data!.values) {
      if (!categories.containsKey(value.key.category)) {
        categories[value.key.category] = [];
      }
      categories[value.key.category]!.add(value);
    }
    List<Widget> list = [];
    categories.forEach((key, value) {
      list.add(SettingsCategoryItem(
        category: key,
        items: value,
      ));
    });
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
            itemBuilder: (context, index) {
              if (index == 0) {
                return i18n.windowSettings.asTextWidget(
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                );
              }
              return list[index - 1];
            },
            separatorBuilder: (context, index) {
              return const SizedBox(height: 8);
            },
            itemCount: list.length + 1,
          ),
          if (hasChanges)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Material(
                    color: app.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: app.dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CustomMenuAnchor(
                            controller: _menuController,
                            menuChildren: [
                              CustomMenuItemButton(
                                child: Text('Restore to default'),
                                onPressed: () {
                                  _restoreDefaults();
                                },
                              ),
                            ],
                            child: IconButton(
                              onPressed: () {
                                _menuController.open(context: context);
                              },
                              icon: Icon(Icons.more_vert),
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              constraints: BoxConstraints(),
                            ),
                          ),
                          Spacer(),
                          OutlinedButton(
                            onPressed: () {
                              _reset();
                            },
                            child: Text('Reset'),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _apply();
                            },
                            child: Text('Apply'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}

class SettingsCategoryItem extends StatefulWidget {
  final SettingsCategory category;
  final List<SettingsValue> items;

  const SettingsCategoryItem({
    Key? key,
    required this.category,
    required this.items,
  }) : super(key: key);

  @override
  _SettingsCategoryItemState createState() => _SettingsCategoryItemState();
}

class _SettingsCategoryItemState extends State<SettingsCategoryItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: app.surfaceColor,
        border: Border.all(color: app.dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconTheme(
                    data: IconThemeData(size: 18, color: app.primaryTextColor),
                    child: widget.category.icon,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.category.display(i18n),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
