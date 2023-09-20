import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nodeflow/components/click_listener.dart';
import 'package:nodeflow/components/dashboard/pages/change_logs_page.dart';
import 'package:nodeflow/components/dashboard/pages/overview_page.dart';
import 'package:nodeflow/components/dashboard/pages/projects_page.dart';
import 'package:nodeflow/components/dashboard/pages/tutorials_page.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/components/navigation/navigation_button.dart';
import 'package:nodeflow/components/page_holder.dart';
import 'package:nodeflow/components/search_bar.dart';
import 'package:nodeflow/components/state_delivery.dart';
import 'package:nodeflow/router.dart';
import 'package:nodeflow/theme/compact_data.dart';

import '../../search.dart';
import '../../ui_util.dart';
import '../navigation/navigation_category.dart';
import '../navigation/navigation_category_label.dart';
import '../navigation/navigation_label.dart';
import '../navigation/navigation_side_bar.dart';
import '../navigation/navigation_top_bar.dart';
import '../settings.dart';
import 'dashboard_page.dart';

const ValueKey<String> pageOverview = ValueKey('overview');
const ValueKey<String> pageChangeLogs = ValueKey('changelogs');
const ValueKey<String> pageMyProjects = ValueKey('myprojects');
const ValueKey<String> pageTutorials = ValueKey('tutorials');
const ValueKey<String> pagePublicProjects = ValueKey('publicprojects');
const ValueKey<String> pageBilling = ValueKey('billing');
const ValueKey<String> pageSettings = ValueKey('settings');
const ValueKey<String> pageLogout = ValueKey('logout');

const Key dashboardNavigation = Key('dashboardNavigation');

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  final ScrollController _scrollController = ScrollController();
  late List<DashboardCategory> categories = [
    DashboardCategory(
      label: () => i18n.dashboardProject,
      pages: [
        DashboardPage(
          key: pageOverview,
          icon: Icon(CupertinoIcons.house_fill),
          label: () => i18n.dashboardProjectOverview,
          pageBuilder: (context) {
            return OverviewPage();
          },
        ),
        DashboardPage(
          key: pageChangeLogs,
          icon: Icon(Icons.newspaper),
          label: () => i18n.dashboardProjectNews,
          pageBuilder: (context) {
            return ChangeLogsPage();
          },
        ),
        DashboardPage(
          key: pageMyProjects,
          icon: Icon(CupertinoIcons.archivebox_fill),
          label: () => i18n.dashboardProjectProjects,
          pageBuilder: (context) {
            return ProjectsPage();
          },
        ),
      ],
    ),
    DashboardCategory(
      label: () => i18n.dashboardExplore,
      pages: [
        DashboardPage(
          key: pageTutorials,
          icon: Icon(Icons.school),
          label: () => i18n.dashboardExploreTutorials,
          pageBuilder: (context) {
            return TutorialsPage();
          },
        ),
        DashboardPage(
          key: pagePublicProjects,
          icon: Icon(Icons.public),
          label: () => i18n.dashboardExploreProjects,
          pageBuilder: (context) {
            return Container();
          },
        ),
      ],
    ),
    DashboardCategory(
      label: () => i18n.dashboardAccount,
      pages: [
        DashboardPage(
          key: pageSettings,
          icon: const Icon(Icons.settings),
          label: () => i18n.dashboardAccountSettings,
          pageBuilder: (context) {
            return SettingsPage();
          },
        ),
        DashboardPage(
          key: pageLogout,
          icon: const Icon(Icons.logout),
          label: () => i18n.dashboardAccountLogout,
          onTap: () {},
        ),
      ],
    ),
  ];

  DashboardPage getPage(ValueKey<String> key) {
    return categories.expand((element) => element.pages).firstWhere((element) => element.key == key);
  }

  void changePage(ValueKey<String> key) {
    if (!mounted) return;
    setState(() {
      context.replacePaths([KeyPath(key.value)]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Search.generateRandomSearch(RouteBuilder(routes: {
      DefaultPathRequest: (path) => RedirectRouterPage([KeyPath(pageOverview.value)]),
      for (var page in categories.expand((element) => element.pages))
        if (page.onTap == null) KeyPathRequest(page.key.value): (path) => RouterPageBuilder((context) => buildContent(context, page)),
    }));
  }

  Widget buildContent(BuildContext context, DashboardPage selectedPage) {
    WindowButtonColors colors = WindowButtonColors(
      iconMouseDown: app.primaryTextColor,
      mouseOver: app.dividerColor,
      iconMouseOver: app.primaryTextColor,
      mouseDown: app.backgroundColor,
      iconNormal: app.primaryTextColor,
      normal: Colors.transparent,
    );
    WindowButtonColors closeColors = WindowButtonColors(
      mouseOver: Colors.red,
      mouseDown: Colors.red[700]!,
      iconNormal: app.primaryTextColor,
      normal: Colors.transparent,
    );
    var pages = categories.expand((element) => element.pages).toList();
    int index = pages.indexOf(selectedPage);
    return StateData(
      state: this,
      child: WindowBorder(
        color: app.dividerColor,
        child: FocusTraversalGroup(
          child: Container(
            color: app.backgroundColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: app.surfaceColor,
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 60,
                          child: MoveWindow(
                            child: Center(
                              child: 'NODEFLOW'.asTextWidget(
                                style: TextStyle(
                                  color: app.primaryTextColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: FocusTraversalGroup(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: NavigationSideBar(
                                children: joinWidgets(
                                    categories.map((e) {
                                      return NavigationCategory(
                                        label: NavigationCategoryLabel(
                                          label: e.label(),
                                        ),
                                        children: e.pages.map((p) {
                                          return NavigationButton(
                                            icon: p.icon,
                                            label: NavigationLabel(
                                              label: p.label(),
                                            ),
                                            selected: selectedPage == p,
                                            onTap: () {
                                              if (p.onTap != null) {
                                                p.onTap!();
                                              } else {
                                                setState(() {
                                                  context.replacePaths([KeyPath(p.key.value)]);
                                                });
                                              }
                                            },
                                          );
                                        }).toList(),
                                      );
                                    }).toList(),
                                    () => Divider()),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(indent: 60),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FocusTraversalGroup(
                        child: GestureDetector(
                          onPanStart: (e) {
                            appWindow.startDragging();
                          },
                          child: ClickListener(
                            onDoubleClick: () {
                              appWindow.maximizeOrRestore();
                            },
                            child: Material(
                              color: app.surfaceColor,
                              child: NavigationTopBar(
                                children: [
                                  GestureDetector(onPanStart: (e) {}, child: SearchBarWidget()),
                                  Spacer(),
                                  GestureDetector(
                                    // GestureDetector is needed to prevent the MoveWindow widget to capture onPanStart on the child widget
                                    onPanStart: (e) {},
                                    child: IconButton(
                                      icon: Icon(CupertinoIcons.bell_fill),
                                      onPressed: () {},
                                      iconSize: 18,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 24,
                                  ),
                                  VerticalDivider(),
                                  SizedBox(
                                    width: 24,
                                  ),
                                  Center(
                                    child: ClipOval(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: GestureDetector(
                                            onTapDown: (e) {
                                              appWindow.minimize();
                                            },
                                            onPanStart: (e) {
                                              appWindow.minimize();
                                            },
                                            child: MinimizeWindowButton(
                                              colors: colors,
                                            )),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: ClipOval(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: appWindow.isMaximized
                                            ? RestoreWindowButton(
                                                colors: colors,
                                                onPressed: () {
                                                  setState(() {
                                                    appWindow.maximizeOrRestore();
                                                  });
                                                },
                                              )
                                            : MaximizeWindowButton(
                                                colors: colors,
                                                onPressed: () {
                                                  setState(() {
                                                    appWindow.maximizeOrRestore();
                                                  });
                                                },
                                              ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: ClipOval(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: GestureDetector(
                                            onPanStart: (e) {},
                                            child: CloseWindowButton(
                                              colors: closeColors,
                                            )),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Divider(),
                      // replace with IndexedStack to keep the state of the pages
                      Expanded(
                        child: FocusTraversalGroup(
                          child: RelativeDirectionalPageSwitcher(
                            direction: PageTransitionDirection.vertical,
                            index: index,
                            pages: pages.map((e) {
                              return SubNavigator(key: e.navigatorKey, home: e.pageBuilder?.call(context) ?? const SizedBox());
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
