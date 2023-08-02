import 'package:flutter/material.dart';

import 'custom_menu_anchor.dart';

bool _preventContextMenu = true;
void initializeContextMenuService() {
  // prevent context menu from showing up on _ContextMenuState region
  // document.onContextMenu.listen((event) {
  //   if (_preventContextMenu) {
  //     event.preventDefault();
  //   }
  // });
}

class ContextMenu extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;
  final Intent Function() intentBuilder;

  const ContextMenu({Key? key, required this.child, required this.intentBuilder, this.focusNode}) : super(key: key);

  @override
  _ContextMenuState createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  FocusNode focus = FocusNode();
  CustomMenuController _controller = CustomMenuController();
  List<Widget> menuChildren = [];

  @override
  void initState() {
    super.initState();
    focus.addListener(() {
      if (focus.hasFocus) {
        print("context menu focus");
      } else {
        print("context menu unfocus");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == 2) {
          setState(() {
            final intent = widget.intentBuilder();
            // menuChildren = nodeflow.getContext<ActionContext>().buildMenu(
            //       intent,
            //       executorContextMenu,
            //       dividerBuilder: (context) => const Padding(
            //         padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            //         child: DividerHorizontal(),
            //       ),
            //     );
            menuChildren = [];
            _controller.open(position: event.localPosition);
          });
        }
      },
      // onSecondaryTapDown: (details) {
      //   setState(() {
      //     final intent = widget.intentBuilder();
      //     menuChildren = nodeflow.getContext<ActionContext>().buildMenu(
      //           intent,
      //           executorContextMenu,
      //           dividerBuilder: (context) => const Padding(
      //             padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      //             child: DividerHorizontal(),
      //           ),
      //         );
      //     _controller.open(position: details.localPosition);
      //   });
      // },
      child: MenuTheme(
        data: MenuThemeData(
          style: MenuTheme.of(context).style!.copyWith(
                padding: MaterialStatePropertyAll(
                  EdgeInsets.symmetric(vertical: 8),
                ),
              ),
        ),
        child: MenuButtonTheme(
          data: MenuButtonThemeData(
            style: MenuButtonTheme.of(context).style!.copyWith(
                  padding: MaterialStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
          ),
          child: CustomMenuAnchor(
            menuChildren: menuChildren,
            controller: _controller,
            anchorTapClosesMenu: true,
            child: widget.child,
            parentFocusNode: widget.focusNode,
            onClose: () {
              setState(() {
                menuChildren = [];
              });
            },
          ),
        ),
      ),
    );
  }
}
