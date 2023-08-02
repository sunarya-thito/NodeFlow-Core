import 'package:flutter/material.dart';
import 'package:nodeflow/components/menu/custom_menu_anchor.dart';
import 'package:nodeflow/theme/compact_data.dart';

import '../button_icon.dart';
import '../tooltip/tooltip_wrapper.dart';
import '../tree/treeview.dart';

class ProjectFilesPanel extends StatefulWidget {
  final VoidCallback? onCollapse;
  const ProjectFilesPanel({Key? key, this.onCollapse}) : super(key: key);

  @override
  _ProjectFilesPanelState createState() => _ProjectFilesPanelState();
}

class _ProjectFilesPanelState extends State<ProjectFilesPanel> {
  late TreeDataController<String> dataController;
  late CustomMenuController _branchMenuController = CustomMenuController();

  @override
  void initState() {
    super.initState();
    print(_branchMenuController.hashCode);
    dataController = TreeDataController(
      root: TreeData(
        "root",
        children: [
          TreeData(
            "assets",
            children: [
              TreeData("img.png"),
              TreeData("img2.png"),
            ],
          ),
          TreeData(
            "lib",
            children: [
              TreeData("main.dart"),
              TreeData(
                "ui",
                children: [
                  TreeData(
                    "panels",
                    children: [
                      TreeData("project_files_panel.dart"),
                      TreeData(
                          "lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua ut enim ad minim veniam quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur excepteur sint occaecat cupidatat non proident sunt in culpa qui officia deserunt mollit anim id est laborum.dart"),
                    ],
                  ),
                ],
              ),
              TreeData(
                "intents",
                children: [
                  TreeData("intent_tree_view.dart"),
                  for (int i = 0; i < 400; i++) TreeData("intent $i.dart"),
                ],
              ),
              TreeData("application.dart"),
            ],
          ),
          TreeData(
            "test",
          ),
          TreeData(
            "pubspec.yaml",
          ),
        ],
      ),
      childBuilder: (context, data) {
        return SimpleTreeItemLayout(
          child: Text(data.data),
          leading: Icon(Icons.folder_sharp, size: 14),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: app.surfaceColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 32,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: app.dividerColor, width: 1),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: DefaultTextStyle(
                        style: TextStyle(color: app.primaryTextColor, fontSize: 12, overflow: TextOverflow.ellipsis, fontFamily: 'Inter'),
                        child: IconTheme(
                          data: IconThemeData(color: app.primaryTextColor, size: 16),
                          child: ClipRect(
                            child: CustomMenuAnchor(
                              controller: _branchMenuController,
                              menuChildren: [
                                CustomSubmenuButton(
                                  menuChildren: [
                                    CustomMenuItemButton(child: Text("Switch to"), onPressed: () {}),
                                    CustomMenuItemButton(child: Text("Merge into current"), onPressed: () {}),
                                    CustomMenuItemButton(child: Text("Rebase into current"), onPressed: () {}),
                                    CustomMenuItemButton(child: Text("Delete"), onPressed: () {}),
                                  ],
                                  child: Text("master"),
                                ),
                                CustomSubmenuButton(
                                  menuChildren: [
                                    CustomMenuItemButton(child: Text("Switch to"), onPressed: () {}),
                                    CustomMenuItemButton(child: Text("Merge into current"), onPressed: () {}),
                                    CustomMenuItemButton(child: Text("Rebase into current"), onPressed: () {}),
                                    CustomMenuItemButton(child: Text("Delete"), onPressed: () {}),
                                  ],
                                  child: Text("dev"),
                                  onPressed: () {
                                    print("pressed");
                                  },
                                ),
                                const PopupMenuDivider(height: 8),
                                CustomMenuItemButton(child: Text("Clone branch"), onPressed: () {}),
                                const PopupMenuDivider(height: 8),
                                CustomMenuItemButton(child: Text("Branch Network"), onPressed: () {}),
                              ],
                              child: Container(
                                color: app.surfaceColor,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    if (_branchMenuController.isOpen) {
                                      _branchMenuController.close();
                                    } else {
                                      _branchMenuController.open();
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      children: [
                                        // branch icon
                                        Icon(Icons.fork_right),
                                        const SizedBox(width: 4),
                                        // branch name
                                        Expanded(child: Text("master")),
                                        Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          TooltipWrapper(
                            tooltip: TooltipWrapper.defaultTooltip(i18n.tooltipSidebarProjectfilesSettings),
                            child: ButtonIcon(
                              icon: Icon(Icons.settings, size: 12, color: app.primaryTextColor),
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 4),
                          TooltipWrapper(
                            tooltip: TooltipWrapper.defaultTooltip(i18n.tooltipSidebarProjectfilesMinimize),
                            child: ButtonIcon(
                              icon: Icon(Icons.remove, size: 12, color: app.primaryTextColor),
                              onTap: () {
                                widget.onCollapse?.call();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TreeView(
                controller: dataController,
                canMove: (parent, item, targetParent) {
                  return true;
                },
              ),
            )
          ],
        ));
  }
}
