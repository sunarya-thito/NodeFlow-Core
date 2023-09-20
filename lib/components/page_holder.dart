import 'package:flutter/widgets.dart';

class SubNavigator extends StatefulWidget {
  final Widget home;

  const SubNavigator({Key? key, required this.home}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SubNavigatorState();
  }

  static SubNavigatorState of(BuildContext context, [Key? key]) {
    var state = context.dependOnInheritedWidgetOfExactType<_SubNavigatorData>()!.state;
    if (key != null) {
      while (state.widget.key != key) {
        state = state.context.dependOnInheritedWidgetOfExactType<_SubNavigatorData>()!.state;
      }
    }
    return state;
  }
}

abstract class PageTransition {
  final Duration duration;
  const PageTransition({required this.duration});
  Widget buildTransitionPageIn(BuildContext context, Widget child, Animation<double> animation);
  Widget buildTransitionPageOut(BuildContext context, Widget child, Animation<double> animation);
}

abstract class SubNavigatorState extends State<SubNavigator> {
  void go(Widget page, [PageTransition transition = const SlidePageTransition()]);
  void goBack();
  void goHome();
  bool get canGoBack;
}

class _RouteHistory {
  final _SubNavigatorState state;
  final Widget page;
  final PageTransition transition;
  final AnimationController controller;
  bool beingPopped = false;

  _RouteHistory(this.state, this.page, this.transition, this.controller) {
    controller.addListener(() {
      if (controller.value <= 0 && beingPopped) {
        state.removeHistory(this);
        controller.dispose();
      }
    });
  }
}

class _SubNavigatorData extends InheritedWidget {
  final SubNavigatorState state;

  const _SubNavigatorData({Key? key, required this.state, required Widget child}) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant _SubNavigatorData oldWidget) {
    return oldWidget.state != state;
  }
}

class _SubNavigatorState extends State<SubNavigator> with TickerProviderStateMixin implements SubNavigatorState {
  final List<_RouteHistory> history = [];

  @override
  void didUpdateWidget(covariant SubNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!Widget.canUpdate(oldWidget.home, widget.home)) {
      history.clear();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SubNavigatorData(
      state: this,
      child: ClipRect(
        child: _buildContent(),
      ),
    );
  }

  void removeHistory(_RouteHistory routeHistory) {
    history.remove(routeHistory);
    if (mounted) setState(() {});
  }

  Widget _buildContent() {
    if (history.isEmpty) return widget.home;
    return buildStack(history.length - 1);
  }

  Widget buildStack(int index) {
    return _SubNavigatorStack(home: widget.home, history: history, routeHistory: history[index], previousHistory: index > 0 ? history[index - 1] : null);
  }

  @override
  bool get canGoBack => history.isNotEmpty;

  @override
  void go(Widget page, [PageTransition transition = const SlidePageTransition()]) {
    if (!mounted) return;
    var routeHistory = _RouteHistory(this, page, transition, AnimationController(vsync: this, duration: transition.duration));
    history.add(routeHistory);
    routeHistory.controller.forward();
    setState(() {});
  }

  _RouteHistory? _findLastNotPopped() {
    for (var i = history.length - 1; i >= 0; i--) {
      if (!history[i].beingPopped) return history[i];
    }
    return null;
  }

  @override
  void goBack() {
    var routeHistory = _findLastNotPopped();
    if (routeHistory == null) return;
    routeHistory.beingPopped = true;
    routeHistory.controller.reverse();
    if (mounted) setState(() {});
  }

  @override
  void goHome() {
    // remove all routes except the last one (without animation), and then remove the last one with animation
    history.removeRange(0, history.length - 1);
    var routeHistory = history.removeLast();
    routeHistory.controller.reverse();
    if (mounted) setState(() {});
  }
}

class _SubNavigatorStack extends StatefulWidget {
  final Widget home;
  final List<_RouteHistory> history;
  final _RouteHistory routeHistory;
  final _RouteHistory? previousHistory;

  const _SubNavigatorStack({Key? key, required this.routeHistory, required this.home, required this.history, required this.previousHistory}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SubNavigatorStackState();
  }
}

class _SubNavigatorStackState extends State<_SubNavigatorStack> {
  @override
  void initState() {
    super.initState();
    widget.routeHistory.controller.addListener(_update);
  }

  @override
  void didUpdateWidget(covariant _SubNavigatorStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeHistory != widget.routeHistory) {
      oldWidget.routeHistory.controller.removeListener(_update);
      widget.routeHistory.controller.addListener(_update);
    }
  }

  @override
  void dispose() {
    widget.routeHistory.controller.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _RouteHistory routeHistory = widget.routeHistory;
    Widget previous = widget.previousHistory?.page ?? widget.home;
    if (routeHistory.controller.value >= 1) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FocusTraversalGroup(child: routeHistory.page),
          FocusTraversalGroup(
            child: ExcludeFocus(
              child: Offstage(
                child: previous,
              ),
            ),
          ),
        ],
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        FocusTraversalGroup(child: routeHistory.transition.buildTransitionPageIn(context, routeHistory.page, routeHistory.controller)),
        FocusTraversalGroup(child: routeHistory.transition.buildTransitionPageOut(context, previous, routeHistory.controller)),
      ],
    );
  }
}

class PageSwitcher extends StatefulWidget {
  final int index;
  final List<Widget> pages;
  final PageTransition transition;

  const PageSwitcher({Key? key, required this.index, required this.pages, this.transition = const SlidePageTransition()}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PageSwitcherState();
  }
}

enum TransitionDirection {
  toDown,
  toUp,
  toLeft,
  toRight,
}

TransitionDirection _reverseDirection(TransitionDirection dir) {
  switch (dir) {
    case TransitionDirection.toDown:
      return TransitionDirection.toUp;
    case TransitionDirection.toUp:
      return TransitionDirection.toDown;
    case TransitionDirection.toLeft:
      return TransitionDirection.toRight;
    case TransitionDirection.toRight:
      return TransitionDirection.toLeft;
  }
}

enum PageTransitionDirection {
  horizontal,
  vertical,
  horizontalReverse,
  verticalReverse,
}

class RelativeDirectionalPageSwitcher extends StatefulWidget {
  final PageTransitionDirection direction;
  final int index;
  final List<Widget> pages;

  const RelativeDirectionalPageSwitcher({Key? key, required this.direction, required this.index, required this.pages}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RelativeDirectionalPageSwitcherState();
  }
}

class _RelativeDirectionalPageSwitcherState extends State<RelativeDirectionalPageSwitcher> {
  late int _index;
  late TransitionDirection _transitionDirection;
  @override
  void initState() {
    super.initState();
    _index = widget.index;
    switch (widget.direction) {
      case PageTransitionDirection.horizontal:
        _transitionDirection = TransitionDirection.toLeft;
        break;
      case PageTransitionDirection.horizontalReverse:
        _transitionDirection = TransitionDirection.toRight;
        break;
      case PageTransitionDirection.vertical:
        _transitionDirection = TransitionDirection.toUp;
        break;
      case PageTransitionDirection.verticalReverse:
        _transitionDirection = TransitionDirection.toDown;
        break;
    }
  }

  @override
  void didUpdateWidget(covariant RelativeDirectionalPageSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      if (_index < widget.index) {
        switch (widget.direction) {
          case PageTransitionDirection.horizontal:
            _transitionDirection = TransitionDirection.toLeft;
            break;
          case PageTransitionDirection.horizontalReverse:
            _transitionDirection = TransitionDirection.toRight;
            break;
          case PageTransitionDirection.vertical:
            _transitionDirection = TransitionDirection.toUp;
            break;
          case PageTransitionDirection.verticalReverse:
            _transitionDirection = TransitionDirection.toDown;
            break;
        }
      } else {
        switch (widget.direction) {
          case PageTransitionDirection.horizontal:
            _transitionDirection = TransitionDirection.toRight;
            break;
          case PageTransitionDirection.horizontalReverse:
            _transitionDirection = TransitionDirection.toLeft;
            break;
          case PageTransitionDirection.vertical:
            _transitionDirection = TransitionDirection.toDown;
            break;
          case PageTransitionDirection.verticalReverse:
            _transitionDirection = TransitionDirection.toUp;
            break;
        }
      }
      _index = widget.index;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageSwitcher(
      index: _index,
      pages: widget.pages,
      transition: SlidePageTransition(direction: _transitionDirection),
    );
  }
}

// slide with fade transition
class SlidePageTransition extends PageTransition {
  final TransitionDirection direction;

  const SlidePageTransition({this.direction = TransitionDirection.toLeft, Duration duration = const Duration(milliseconds: 300)}) : super(duration: duration);

  @override
  Widget buildTransitionPageIn(BuildContext context, Widget child, Animation<double> animation) {
    var curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    Offset begin;
    switch (direction) {
      case TransitionDirection.toDown:
        begin = const Offset(0, -1);
        break;
      case TransitionDirection.toUp:
        begin = const Offset(0, 1);
        break;
      case TransitionDirection.toLeft:
        begin = const Offset(1, 0);
        break;
      case TransitionDirection.toRight:
        begin = const Offset(-1, 0);
        break;
    }
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }

  @override
  Widget buildTransitionPageOut(BuildContext context, Widget child, Animation<double> animation) {
    var curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    Offset end;
    switch (direction) {
      case TransitionDirection.toDown:
        end = const Offset(0, 1);
        break;
      case TransitionDirection.toUp:
        end = const Offset(0, -1);
        break;
      case TransitionDirection.toLeft:
        end = const Offset(-1, 0);
        break;
      case TransitionDirection.toRight:
        end = const Offset(1, 0);
        break;
    }
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(animation),
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset.zero, end: end).animate(curved),
        child: child,
      ),
    );
  }
}

class _PageSwitcherState extends State<PageSwitcher> {
  @override
  Widget build(BuildContext context) {
    return widget.pages.isEmpty
        ? Container()
        : ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (int i = 0; i < widget.pages.length; i++)
                  _PageStateHolder(
                    transition: widget.transition,
                    visible: i == widget.index,
                    child: widget.pages[i],
                  ),
              ],
            ),
          );
  }
}

class _PageStateHolder extends StatefulWidget {
  final PageTransition transition;
  final bool visible;
  final Widget child;

  const _PageStateHolder({Key? key, required this.transition, required this.visible, required this.child}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PageStateHolderState();
  }
}

class _PageStateHolderState extends State<_PageStateHolder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.transition.duration, value: widget.visible ? 1 : 0);
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _PageStateHolder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transition != widget.transition) {
      _controller.duration = widget.transition.duration;
    }
    if (oldWidget.visible != widget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      excluding: _controller.value <= 0,
      child: FocusTraversalGroup(
        child: Visibility(
          visible: _controller.value > 0,
          maintainState: true,
          child: widget.visible
              ? widget.transition.buildTransitionPageIn(context, widget.child, _controller)
              : widget.transition.buildTransitionPageOut(context, widget.child, Tween<double>(begin: 1, end: 0).animate(_controller)),
        ),
      ),
    );
  }
}
