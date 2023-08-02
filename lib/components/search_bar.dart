import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/theme/compact_data.dart';

import 'menu/custom_menu_anchor.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({Key? key}) : super(key: key);

  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  TextEditingController controller = TextEditingController();

  int suggestionIndex = 0;
  List<String> suggestions = ["test", "hello", "world", "example"];

  void updateIndexSuggestion() {
    if (suggestions.isEmpty) return;
    var selection = controller.selection;
    if (hasSelection) {
      var currentSuggestion = suggestions[suggestionIndex % suggestions.length];
      controller.text = controller.text.replaceRange(selection.baseOffset, selection.extentOffset, currentSuggestion);
      // set the cursor at original position
      controller.selection = TextSelection(baseOffset: selection.baseOffset, extentOffset: selection.baseOffset + currentSuggestion.length);
    } else if (selection.isCollapsed && selection.baseOffset == controller.text.length) {
      // else if cursor at the end of the text
      var currentSuggestion = suggestions[suggestionIndex % suggestions.length];
      // if not ends with space, then add space first, also move the cursor forward
      controller.text += currentSuggestion;
      controller.selection = TextSelection(baseOffset: selection.baseOffset, extentOffset: selection.baseOffset);
    }
  }

  void updateSuggestion(String query) {
    // insert the suggestion after cursor and highlight it with selection
    // just like the text field in Chrome's URL bar (android)
    // only suggests if the query is ends with a space
    if (suggestions.isEmpty) {
      var selection = controller.selection;
      if (hasSelection) {
        // replace selected with empty
        controller.text = controller.text.replaceRange(selection.baseOffset, selection.extentOffset, '');
      }
      return;
    }

    var cursorPosition = controller.selection.baseOffset;
    var text = controller.text;

    var suggestion = suggestions[suggestionIndex % suggestions.length];

    // if there is a text selected inside TextField, replace them with the suggestion
    // else, also if there is no text after the cursor, insert the suggestion at the end
    // do not insert the suggestion if there is text after the cursor
    if (controller.selection.isValid && controller.selection.isCollapsed) {
      var start = controller.selection.start;
      var end = controller.selection.end;
      var textBefore = text.substring(0, start);
      var textAfter = text.substring(end);
      controller.text = textBefore + suggestion + textAfter;
      controller.selection = TextSelection(baseOffset: start, extentOffset: start + suggestion.length);
    } else if (cursorPosition == text.length && controller.selection.isCollapsed) {
      var textBefore = text.substring(0, cursorPosition);
      controller.text = textBefore + suggestion;
      controller.selection = TextSelection(baseOffset: cursorPosition, extentOffset: cursorPosition + suggestion.length);
    }
  }

  late FocusNode focusNode;

  bool get hasSelection {
    var selection = controller.selection;
    return selection.baseOffset < selection.extentOffset && selection.extentOffset == controller.text.length;
  }

  @override
  void initState() {
    super.initState();
    suggestions.clear();
    // load from asset
    focusNode = FocusNode(
      onKey: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.tab ||
            event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          // stop the propagation of the event
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (hasSelection) {
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Material(
        color: app.searchBarColor,
        borderRadius: BorderRadius.circular(500),
        child: i18n.dashboardSearch.asBuilderWidget((context, i18n) {
          return RawKeyboardListener(
            focusNode: focusNode,
            onKey: (event) {
              if (event is RawKeyUpEvent) return;
              // if pressed backspace, then remove suggestion and remove space at the end
              if (event.logicalKey == LogicalKeyboardKey.backspace) {
                var selection = controller.selection;
                if (hasSelection) {
                  controller.text = controller.text.replaceRange(selection.baseOffset, selection.extentOffset, '');
                  // set selection at the end
                  controller.selection = TextSelection.collapsed(offset: controller.text.length);
                }
              } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                if (hasSelection) {
                  controller.selection = TextSelection.collapsed(offset: controller.text.length);
                }
              } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                if (hasSelection) {
                  // remove suggestion
                  controller.text = controller.text.replaceRange(controller.selection.baseOffset, controller.selection.extentOffset, '');
                  // set selection at the end
                  controller.selection = TextSelection.collapsed(offset: controller.text.length);
                }
              } else if (event.logicalKey == LogicalKeyboardKey.tab || event.logicalKey == LogicalKeyboardKey.arrowUp) {
                // stop the propagation of the event
                suggestionIndex++;
                updateIndexSuggestion();
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                suggestionIndex--;
                if (suggestionIndex < 0) {
                  suggestionIndex = suggestions.length - 1;
                }
                updateIndexSuggestion();
              }
            },
            child: TextField(
              contextMenuBuilder: (context, editableTextState) {
                return AdaptiveTextSelectionToolbar(children: [
                  CustomMenuItemButton(
                    requestFocusOnHover: false,
                    child: Text("Copy"),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: controller.selection.textInside(controller.text)));
                    },
                  ),
                ], anchors: editableTextState.contextMenuAnchors);
                return Container(
                  width: 100,
                  height: 200,
                  color: Colors.red,
                );
              },
              controller: controller,
              onChanged: (query) {
                suggestionIndex = 0;
                updateSuggestion(query);
              },
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(left: 12),
                isDense: true,
                suffixIcon: const Icon(
                  CupertinoIcons.search,
                  size: 16,
                ),
                border: InputBorder.none,
                suffixIconColor: app.secondaryTextColor,
                hintText: i18n,
                hintStyle: TextStyle(
                  color: CompactData.of(context).theme.secondaryTextColor,
                ),
              ),
              style: TextStyle(color: CompactData.of(context).theme.primaryTextColor, fontSize: 12),
              cursorColor: CompactData.of(context).theme.cursorColor,
              cursorWidth: 1.2,
            ),
          );
        }),
      ),
    );
  }
}
