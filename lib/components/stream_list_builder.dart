import 'dart:async';

import 'package:flutter/widgets.dart';

class StreamListBuilder<T> extends StatefulWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, List<T> collected, bool hasMore) builder;

  const StreamListBuilder({
    Key? key,
    required this.stream,
    required this.builder,
  }) : super(key: key);

  @override
  _StreamListBuilderState<T> createState() => _StreamListBuilderState<T>();
}

class _StreamListBuilderState<T> extends State<StreamListBuilder<T>> {
  final List<T> _collected = [];
  bool _hasMore = true;
  late StreamSubscription<T> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.stream.listen((T data) {
      setState(() {
        _collected.add(data);
      });
    }, onDone: () {
      setState(() {
        _hasMore = false;
      });
    });
  }

  @override
  void didUpdateWidget(covariant StreamListBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _subscription.cancel();
      _collected.clear();
      _subscription = widget.stream.listen((T data) {
        setState(() {
          _collected.add(data);
        });
      }, onDone: () {
        setState(() {
          _hasMore = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _collected, _hasMore);
  }
}
