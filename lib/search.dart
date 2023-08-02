import 'package:flutter/widgets.dart';

class _SearchContext extends InheritedWidget {
  final _SearchContext? _parent;
  final Iterable<SearchResult> Function(String query) search;

  const _SearchContext({
    Key? key,
    required this.search,
    required Widget child,
    _SearchContext? parent,
  })  : _parent = parent,
        super(key: key, child: child);

  @override
  bool updateShouldNotify(_SearchContext oldWidget) {
    return search != oldWidget.search || _parent != oldWidget._parent;
  }
}

class Tag {
  final double multiplier;
  final String data;

  const Tag(this.data, this.multiplier);
}

class Search extends StatelessWidget {
  final Iterable<SearchResult> Function(String query) search;
  final Widget child;

  static double calculateRelevancyScore(Iterable<Tag> tags, String query) {
    // split by whitespace with no empty strings
    List<String> queryWords = query.toLowerCase().split(r'\s+').toList();
    double accumulation = 0;

    for (Tag tag in tags) {
      String data = tag.data.toLowerCase();
      double score = 0;
      int index = 0;
      for (String queryWord in queryWords) {
        int matchIndex = data.indexOf(queryWord, index);
        if (matchIndex == -1) {
          break;
        }
        score += tag.multiplier;
        index = matchIndex + queryWord.length;
      }
      accumulation += score / query.length;
    }

    return accumulation;
  }

  const Search({
    Key? key,
    required this.search,
    required this.child,
  }) : super(key: key);

  static _SearchContext? _of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_SearchContext>();
  }

  static Iterable<SearchResult> of(BuildContext context, String query) sync* {
    _SearchContext? searchContext = context.dependOnInheritedWidgetOfExactType<_SearchContext>();
    while (searchContext != null) {
      yield* searchContext.search(query);
      searchContext = searchContext._parent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SearchContext(
      parent: _of(context),
      search: search,
      child: child,
    );
  }
}

class SearchResult {
  final VoidCallback open;
  final Widget Function(String query) builder;
  final double relevancyScore;

  const SearchResult({
    required this.open,
    required this.builder,
    required this.relevancyScore,
  });
}
