import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/components/stream_list_builder.dart';
import 'package:nodeflow/components/widget_size_reporter.dart';
import 'package:nodeflow/search.dart';
import 'package:nodeflow/theme/compact_data.dart';

import 'entry.dart';
import 'menu/custom_menu_anchor.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({Key? key}) : super(key: key);

  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final GlobalKey _anchorKey = GlobalKey();
  late OverlayEntry _overlayEntry;

  TextEditingController controller = TextEditingController();

  int suggestionIndex = 0;
  List<String> suggestions = ["test", "hello", "world", "example"];

  final ValueNotifier<double> _widgetWidth = ValueNotifier(0);
  final ValueNotifier<bool> _visible = ValueNotifier(false);

  final FocusNode focusNode = FocusNode();

  void _show([bool force = false]) {
    if (_visible.value) {
      if (!force) return;
    }
    _visible.value = true;
  }

  void _hide() {
    if (!_visible.value) return;
    Search.interrupt();
    _visible.value = false;
  }

  @override
  void initState() {
    super.initState();
    // load from asset
    focusNode.addListener(() {
      if (focusNode.hasFocus && controller.text.trim().isNotEmpty) {
        _show(true);
      }
    });
    controller.addListener(() {
      if (controller.text.trim().isEmpty) {
        _hide();
      } else {
        _show();
      }
    });
    _visible.addListener(() {
      if (_visible.value && !_overlayEntry.hasOverlay) {
        Overlay.of(context).insert(_overlayEntry);
      }
    });
    GlobalKey circleKey = GlobalKey();
    _overlayEntry = OverlayEntry(
      builder: (context) {
        var renderObject = _anchorKey.currentContext!.findRenderObject() as RenderBox;
        var localToGlobal = renderObject.localToGlobal(Offset(renderObject.paintBounds.left, renderObject.paintBounds.bottom));
        return Positioned.directional(
          textDirection: Directionality.of(outerContext),
          top: localToGlobal.dy + 8,
          start: localToGlobal.dx,
          child: InheritedTheme.captureAll(
            outerContext,
            TapRegion(
              groupId: this,
              onTapOutside: (event) {
                _hide();
              },
              child: ValueListenableBuilder(
                valueListenable: _widgetWidth,
                builder: (context, width, child) {
                  return ValueListenableBuilder(
                    valueListenable: _visible,
                    builder: (context, visible, child) {
                      return Entry(
                        startSize: Size(width, 0),
                        endSize: Size(width, 500),
                        visible: visible,
                        onEnd: () {
                          if (!visible) {
                            _overlayEntry.remove();
                          }
                        },
                        child: child!,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        width: width,
                        decoration: BoxDecoration(
                          color: CompactData.of(context).theme.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CompactData.of(context).theme.dividerColor),
                        ),
                        child: child!,
                      ),
                    ),
                  );
                },
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: controller.text.trim().isEmpty
                      ? Container(
                          height: 0,
                        )
                      : FocusTraversalGroup(
                          child: ValueDelayer(
                            value: controller.text.trim(),
                            delay: const Duration(seconds: 1),
                            builder: (context, value) {
                              print('searching $value');
                              return Searcher(
                                searchContext: Search.of(outerContext),
                                query: value,
                                builder: (context, resultStream) {
                                  return StreamListBuilder(
                                    stream: resultStream,
                                    builder: (context, data, hasMore) {
                                      if (data.isEmpty && !hasMore) {
                                        return SizedBox(
                                          height: 40,
                                          child: Center(
                                            child: 'No results found'.asTextWidget(),
                                          ),
                                        );
                                      }
                                      return ListView.separated(
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          if (index == data.length) {
                                            return Container(
                                              padding: const EdgeInsets.all(12),
                                              child: Center(
                                                child: RepaintBoundary(
                                                  child: CircularProgressIndicator(
                                                    key: circleKey,
                                                    color: CompactData.of(context).theme.secondaryTextColor,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          return SearchResultWidget(
                                            result: data[index],
                                            parentFocusNode: focusNode,
                                          );
                                        },
                                        separatorBuilder: (context, index) {
                                          return const Divider();
                                        },
                                        itemCount: hasMore ? data.length + 1 : data.length,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BuildContext get outerContext => context;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _overlayEntry.markNeedsBuild();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      key: _anchorKey,
      groupId: this,
      child: WidgetSizeReporter(
        onSizeChanged: (size) {
          _widgetWidth.value = size.width;
        },
        child: SizedBox(
          width: 300,
          child: Material(
            color: app.searchBarColor,
            borderRadius: BorderRadius.circular(500),
            child: i18n.dashboardSearch.asBuilderWidget((context, i18n) {
              return TextField(
                focusNode: focusNode,
                contextMenuBuilder: (context, editableTextState) {
                  return AdaptiveTextSelectionToolbar(anchors: editableTextState.contextMenuAnchors, children: [
                    CustomMenuItemButton(
                      requestFocusOnHover: false,
                      child: Text("Copy"),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: controller.selection.textInside(controller.text)));
                      },
                    ),
                  ]);
                  return Container(
                    width: 100,
                    height: 200,
                    color: Colors.red,
                  );
                },
                onChanged: (text) {
                  if (_overlayEntry.hasOverlay) {
                    _overlayEntry.markNeedsBuild();
                  }
                },
                controller: controller,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(left: 12, right: 12),
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
              );
            }),
          ),
        ),
      ),
    );
  }
}

class ValueDelayer<T> extends StatefulWidget {
  final T value;
  final Duration delay;
  final Widget Function(BuildContext context, T value) builder;

  const ValueDelayer({Key? key, required this.value, required this.delay, required this.builder}) : super(key: key);

  @override
  _ValueDelayerState<T> createState() => _ValueDelayerState<T>();
}

class _ValueDelayerState<T> extends State<ValueDelayer<T>> {
  late T _value;
  late T _futureValue;
  Timer? _delayer;
  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant ValueDelayer<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      supplyValue(widget.value);
    }
  }

  void resetDelay() {
    _delayer?.cancel();
    _delayer = Timer(widget.delay, () {
      if (!mounted) return;
      setState(() {
        _value = _futureValue;
        _delayer = null;
      });
    });
  }

  void supplyValue(T value) {
    _futureValue = value;
    resetDelay();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _value);
  }
}

class SearchResultWidget extends StatefulWidget {
  final SearchResult result;
  final FocusNode parentFocusNode;

  const SearchResultWidget({Key? key, required this.result, required this.parentFocusNode}) : super(key: key);

  @override
  _SearchResultWidgetState createState() => _SearchResultWidgetState();
}

class _SearchResultWidgetState extends State<SearchResultWidget> {
  bool _focused = false;
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      parentFocusNode: widget.parentFocusNode,
      onShowFocusHighlight: (value) {
        setState(() {
          _focused = value;
        });
      },
      onShowHoverHighlight: (value) {
        setState(() {
          _hovered = value;
        });
      },
      child: Container(
        color: _focused
            ? app.focusedSurfaceColor
            : _hovered
                ? app.hoveredSurfaceColor
                : null,
        child: widget.result.widget,
      ),
    );
  }
}
