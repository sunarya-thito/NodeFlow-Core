import 'package:flutter/material.dart';
import 'package:nodeflow/components/bottom_bar_button.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/components/outlined.dart';
import 'package:nodeflow/components/search_bar.dart';
import 'package:nodeflow/components/split_pane.dart';
import 'package:nodeflow/theme/compact_data.dart';

import '../components/blueprint/blueprint.dart';
import '../components/breadcrumbs.dart';
import '../components/menu/custom_menu_anchor.dart';
import '../components/panels/collapsed_project_files_panel.dart';
import '../components/panels/project_files_panel.dart';
import '../components/tabview/tab_header.dart';
import '../components/tabview/tab_view.dart';
import '../components/toolbar/toolbar_viewport.dart';
import '../components/tooltip/tooltip_wrapper.dart';

class Editor extends StatefulWidget {
  const Editor({Key? key}) : super(key: key);

  @override
  _EditorState createState() => _EditorState();
}

const double kBottomBarHeight = 24;

class EditorController extends ChangeNotifier {
  double? _bottomBarHeight;
  double? _sidebarWidth = 200;

  final SplitPaneController _horizontalController = SplitPaneController(
    orientation: SplitPaneOrientation.horizontal,
    position: 200,
  );
  final SplitPaneController _verticalController = SplitPaneController(
    orientation: SplitPaneOrientation.vertical,
    position: 0,
    reverse: true,
    // resizable: false,
  );

  double get bottomBarHeight => _bottomBarHeight ?? 0;
  double get sidebarWidth => _sidebarWidth ?? 0;
  bool get isSidebarCollapsed => _sidebarWidth == null;
  bool get isBottomBarCollapsed => _bottomBarHeight == null;

  set bottomBarHeight(double? value) {
    if (_bottomBarHeight != value) {
      _bottomBarHeight = value;
      _verticalController.resizable = value != null;
      if (value != null) {
        _verticalController.position = value;
      } else {
        _verticalController.position = 0;
      }
      notifyListeners();
    }
  }

  set sidebarWidth(double? value) {
    if (_sidebarWidth != value) {
      _sidebarWidth = value;
      _horizontalController.resizable = value != null;
      if (value != null) {
        _horizontalController.position = value;
      } else {
        _horizontalController.position = 0;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
  }
}

const String taskManagerButtonGroup = 'taskManagerButtonGroup';
const String notificationButtonGroup = 'notificationButtonGroup';

class _EditorState extends State<Editor> {
  late EditorController _controller = EditorController();

  void update() {
    setState(() {});
  }

  int focusedTab = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: app.surfaceColor,
          height: 24,
          child: Row(
            children: [
              CustomMenuBar(
                children: [
                  CustomSubmenuButton(
                    menuChildren: [],
                    child: i18n.menubarFile.asMenuAcceleratorLabelWidget(),
                  ),
                  CustomSubmenuButton(
                    menuChildren: [],
                    child: i18n.menubarEdit.asMenuAcceleratorLabelWidget(),
                  ),
                  CustomSubmenuButton(
                    menuChildren: [],
                    child: i18n.menubarView.asMenuAcceleratorLabelWidget(),
                  ),
                  CustomSubmenuButton(
                    menuChildren: [],
                    child: i18n.menubarTools.asMenuAcceleratorLabelWidget(),
                  ),
                  CustomSubmenuButton(
                    menuChildren: [],
                    child: i18n.menubarHelp.asMenuAcceleratorLabelWidget(),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: CompactData.of(context).theme.secondaryTextColor,
                      fontSize: 12,
                    ),
                    child: i18n.helloWorld.asTextWidget(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Container(
          height: ToolbarState.toolbarHeight,
          color: CompactData.of(context).theme.surfaceColor,
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 5), // 5 because of the bottom border causing a 1px offset
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Breadcrumbs(children: [
                  Text('Hello'),
                  Text('World'),
                  Text('This'),
                  Text('Is'),
                  Text('A'),
                  Text('Breadcrumb'),
                ]),
              ),
              Toolbar(toolbars: []),
              const SizedBox(width: 8),
              TooltipWrapper(
                tooltip: TooltipWrapper.descriptiveTooltip(i18n.quickaccessSearch, i18n.tooltipQuickaccessSearch),
                child: const SearchBarWidget(),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: SplitPane(
            backgroundColor: app.dividerColor,
            controller: _controller._verticalController,
            second: _controller.isBottomBarCollapsed
                ? null
                : SplitPaneItem(
                    minSize: _controller.isBottomBarCollapsed ? 0 : 50,
                    child: Outlined(
                      child: Container(
                        color: Colors.red,
                      ),
                    ),
                  ),
            first: SplitPaneItem(
              minSize: 200,
              child: Outlined(
                child: SplitPane(
                  backgroundColor: app.dividerColor,
                  controller: _controller._horizontalController,
                  first: SplitPaneItem(
                    minSize: _controller.isSidebarCollapsed ? 24 : 100,
                    child: Outlined(child: _controller.isSidebarCollapsed ? CollapsedProjectFilesPanel() : ProjectFilesPanel()),
                  ),
                  second: SplitPaneItem(
                    minSize: 100,
                    child: Outlined(
                      child: TabView(tabs: [
                        for (int i = 0; i < 12; i++)
                          TabEntry(
                            label: 'T$i',
                            tabHeader: TabHeader(
                              label: Text('T$i'),
                              closeable: true,
                            ),
                            tabContentBuilder: (context) {
                              return Blueprint();
                            },
                          ),
                      ], focusedTabIndex: 0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Divider(),
        Container(
          color: app.surfaceColor,
          height: kBottomBarHeight,
          padding: const EdgeInsets.only(left: 24 + 1, right: 12), // + 1 to align with the toolbar
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [], // TODO: bottom bar tabs
                ),
              ),
              TapRegion(
                groupId: taskManagerButtonGroup,
                child: BottomBarButton(isOpened: true),
              ),
              TapRegion(
                groupId: taskManagerButtonGroup,
                child: BottomBarButton(isOpened: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
