import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'components/blueprint/blueprint.dart';
import 'components/tabview/tab_view_theme.dart';
import 'components/tree/treeview.dart';
import 'theme/compact_data.dart';

class CompactUI extends StatefulWidget {
  final ThemeMode mode;
  final RouterConfig<Object> routerConfig;

  const CompactUI({Key? key, required this.mode, required this.routerConfig}) : super(key: key);

  @override
  CompactUIState createState() => CompactUIState();
}

class CompactUIState extends State<CompactUI> {
  @override
  void initState() {
    super.initState();
  }

  void update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget materialApp = Builder(builder: (context) {
      return BlueprintTheme(
        data: BlueprintThemeData(
          backgroundColor: CompactData.of(context).theme.backgroundColor,
          majorGridSpacing: 100,
          minorGridSpacing: 20,
          majorGridColor: CompactData.of(context).theme.blueprintMajorGridColor,
          minorGridColor: CompactData.of(context).theme.blueprintMinorGridColor,
          executionColor: CompactData.of(context).theme.executionColor,
          nodeBubbleColor: CompactData.of(context).theme.nodeBubbleColor,
          nodeErrorColor: CompactData.of(context).theme.nodeErrorColor,
          nodeWarningColor: CompactData.of(context).theme.nodeWarningColor,
          selectedNodeBorderColor: CompactData.of(context).theme.selectedNodeBorderColor,
          selectionBorderColor: CompactData.of(context).theme.selectionBorderColor,
          selectionColor: CompactData.of(context).theme.selectionColor,
        ),
        child: TreeTheme(
          data: TreeTheme.createDefault(context),
          child: TabViewGroupTheme(
            tabViewGroupStyle: TabViewGroupStyle(
              sectionHighlightColor: MaterialStatePropertyAll(CompactData.of(context).theme.tabViewGroupSectionHighlightColor),
            ),
            child: TabViewTheme(
              tabViewStyle: TabViewStyle(
                headerBackgroundColor: MaterialStatePropertyAll(CompactData.of(context).theme.surfaceColor),
                headerHeight: const MaterialStatePropertyAll(32),
              ),
              child: TabHeaderTheme(
                tabHeaderStyle: TabHeaderStyle(
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return CompactData.of(context).theme.hoveredSurfaceColor;
                    }
                    if (states.contains(MaterialState.hovered)) {
                      return CompactData.of(context).theme.downSurfaceColor;
                    }
                    return null;
                  }),
                  placeholderColor: MaterialStatePropertyAll(CompactData.of(context).theme.hoveredSurfaceColor),
                  outlineColor: MaterialStateProperty.resolveWith(
                    (states) {
                      if (states.contains(MaterialState.focused) && states.contains(MaterialState.selected)) {
                        return CompactData.of(context).theme.focusedSurfaceColor;
                      }
                      if (states.contains(MaterialState.selected)) {
                        return CompactData.of(context).theme.highlightedHoveredSurfaceColor;
                      }
                      return null;
                    },
                  ),
                ),
                child: Container(
                  color: CompactData.of(context).theme.backgroundColor,
                  child: MaterialApp.router(
                    title: 'NodeFlow',
                    debugShowCheckedModeBanner: false,
                    routerConfig: widget.routerConfig,
                    supportedLocales: const [
                      Locale('en', 'US'),
                    ],
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    theme: ThemeData(
                      fontFamily: 'Inter',
                      visualDensity: VisualDensity.compact,
                      textTheme: Theme.of(context).textTheme.apply(
                            fontFamily: 'Inter',
                            bodyColor: CompactData.of(context).theme.primaryTextColor,
                            displayColor: CompactData.of(context).theme.primaryTextColor,
                          ),
                      primaryTextTheme: Theme.of(context).primaryTextTheme.apply(
                            fontFamily: 'Inter',
                            displayColor: CompactData.of(context).theme.primaryTextColor,
                            bodyColor: CompactData.of(context).theme.primaryTextColor,
                          ),
                      iconTheme: IconThemeData(
                        color: CompactData.of(context).theme.secondaryTextColor,
                      ),
                      progressIndicatorTheme: ProgressIndicatorThemeData(
                        linearTrackColor: CompactData.of(context).theme.progressBarTrackColor,
                        color: CompactData.of(context).theme.progressBarValueColor,
                      ),
                      menuBarTheme: const MenuBarThemeData(
                        style: MenuStyle(
                          shape: MaterialStatePropertyAll(
                            RoundedRectangleBorder(),
                          ),
                          backgroundColor: MaterialStatePropertyAll(
                            Colors.transparent,
                          ),
                          shadowColor: MaterialStatePropertyAll(
                            Colors.transparent,
                          ),
                          elevation: MaterialStatePropertyAll(
                            0,
                          ),
                          surfaceTintColor: MaterialStatePropertyAll(
                            Colors.transparent,
                          ),
                          padding: MaterialStatePropertyAll(
                            EdgeInsets.zero,
                          ),
                          minimumSize: MaterialStatePropertyAll(
                            Size(0, 32),
                          ),
                        ),
                      ),
                      scrollbarTheme: ScrollbarThemeData(
                        thumbColor: MaterialStateProperty.all(CompactData.of(context).theme.scrollbarThumbColor),
                        trackColor: MaterialStateProperty.all(Colors.transparent),
                        thumbVisibility: MaterialStateProperty.all(true),
                        radius: Radius.zero,
                        crossAxisMargin: 0,
                        mainAxisMargin: 0,
                        thickness: MaterialStateProperty.all(8),
                      ),
                      menuButtonTheme: MenuButtonThemeData(
                        style: ButtonStyle(
                          splashFactory: NoSplash.splashFactory,
                          overlayColor: MaterialStatePropertyAll(
                            Colors.transparent,
                          ),
                          side: MaterialStatePropertyAll(
                            BorderSide.none,
                          ),
                          textStyle: MaterialStatePropertyAll(
                            TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: CompactData.of(context).theme.primaryTextColor,
                            ),
                          ),
                          backgroundColor: MaterialStateColor.resolveWith((states) {
                            if (states.contains(MaterialState.focused)) {
                              return CompactData.of(context).theme.focusedSurfaceColor;
                            }
                            if (states.contains(MaterialState.hovered)) {
                              return CompactData.of(context).theme.hoveredSurfaceColor;
                            }
                            return Colors.transparent;
                          }),
                          minimumSize: MaterialStatePropertyAll(
                            Size(0, 26),
                          ),
                          iconSize: MaterialStatePropertyAll(
                            14,
                          ),
                          foregroundColor: MaterialStateColor.resolveWith((states) {
                            if (states.contains(MaterialState.disabled)) {
                              return CompactData.of(context).theme.secondaryTextColor;
                            }
                            return CompactData.of(context).theme.primaryTextColor;
                          }),
                          iconColor: MaterialStateColor.resolveWith((states) {
                            if (states.contains(MaterialState.disabled)) {
                              return CompactData.of(context).theme.secondaryTextColor;
                            }
                            return CompactData.of(context).theme.primaryTextColor;
                          }),
                          padding: MaterialStatePropertyAll(
                            EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ),
                      menuTheme: MenuThemeData(
                        style: MenuStyle(
                          backgroundColor: MaterialStatePropertyAll(
                            CompactData.of(context).theme.surfaceColor,
                          ),
                          elevation: MaterialStatePropertyAll(0),
                          shape: MaterialStatePropertyAll(RoundedRectangleBorder()),
                          side: MaterialStatePropertyAll(
                            BorderSide(
                              color: CompactData.of(context).theme.dividerColor,
                              width: 1,
                            ),
                          ),
                          padding: MaterialStatePropertyAll(
                            EdgeInsets.zero,
                          ),
                        ),
                      ),
                      dropdownMenuTheme: DropdownMenuThemeData(
                        textStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                        ),
                        inputDecorationTheme: InputDecorationTheme(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: CompactData.of(context).theme.dividerColor),
                          ),
                        ),
                        menuStyle: MenuStyle(
                          backgroundColor: MaterialStatePropertyAll(
                            CompactData.of(context).theme.surfaceColor,
                          ),
                          elevation: MaterialStatePropertyAll(0),
                          shape: MaterialStatePropertyAll(RoundedRectangleBorder()),
                          side: MaterialStatePropertyAll(
                            BorderSide(
                              color: CompactData.of(context).theme.dividerColor,
                              width: 1,
                            ),
                          ),
                          padding: MaterialStatePropertyAll(
                            EdgeInsets.zero,
                          ),
                        ),
                      ),
                      popupMenuTheme: PopupMenuThemeData(
                        shape: RoundedRectangleBorder(),
                        elevation: 0,
                        textStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: CompactData.of(context).theme.primaryTextColor,
                        ),
                      ),
                      dividerTheme: DividerThemeData(
                        color: CompactData.of(context).theme.dividerColor,
                        space: 0,
                        thickness: 1,
                      ),
                      elevatedButtonTheme: ElevatedButtonThemeData(
                        style: ButtonStyle(
                          textStyle: MaterialStatePropertyAll(
                            TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: CompactData.of(context).theme.primaryTextColor,
                            ),
                          ),
                          foregroundColor: MaterialStatePropertyAll(
                            CompactData.of(context).theme.primaryTextColor,
                          ),
                          backgroundColor: MaterialStateProperty.resolveWith(
                            (states) {
                              if (states.contains(MaterialState.disabled)) {
                                return CompactData.of(context).theme.surfaceColor;
                              }
                              return CompactData.of(context).theme.focusedSurfaceColor;
                            },
                          ),
                          elevation: MaterialStatePropertyAll(
                            0,
                          ),
                          shape: MaterialStatePropertyAll(
                            RoundedRectangleBorder(
                              side: BorderSide(
                                color: CompactData.of(context).theme.focusedSurfaceColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      outlinedButtonTheme: OutlinedButtonThemeData(
                        style: ButtonStyle(
                          textStyle: MaterialStatePropertyAll(
                            TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                            ),
                          ),
                          shadowColor: const MaterialStatePropertyAll(null),
                          side: MaterialStatePropertyAll(
                            BorderSide(
                              color: CompactData.of(context).theme.dividerColor,
                              width: 1,
                            ),
                          ),
                          shape: MaterialStatePropertyAll(
                            RoundedRectangleBorder(
                              side: BorderSide(
                                color: CompactData.of(context).theme.dividerColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          overlayColor: MaterialStatePropertyAll(
                            CompactData.of(context).theme.hoveredSurfaceColor.withOpacity(0.3),
                          ),
                          foregroundColor: MaterialStateProperty.resolveWith((states) {
                            if (states.contains(MaterialState.disabled)) {
                              return CompactData.of(context).theme.dividerColor;
                            }
                            return CompactData.of(context).theme.primaryTextColor;
                          }),
                          // overlayColor: MaterialStatePropertyAll(Colors.transparent),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
    return widget.mode == ThemeMode.dark ? CompactData.dark(child: materialApp) : CompactData.light(child: materialApp);
  }
}
