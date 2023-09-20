import 'package:flutter/material.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/theme/compact_data.dart';

class SearchContext extends InheritedWidget {
  final SearchContext? _parent;
  final Stream<SearchResult> Function(String query, bool Function() isInterrupted) search;

  const SearchContext({
    Key? key,
    required this.search,
    required Widget child,
    SearchContext? parent,
  })  : _parent = parent,
        super(key: key, child: child);

  @override
  bool updateShouldNotify(SearchContext oldWidget) {
    return search != oldWidget.search || _parent != oldWidget._parent;
  }
}

class Tag {
  final double multiplier;
  final String data;

  const Tag(this.data, this.multiplier);

  @override
  String toString() {
    return 'Tag($data, $multiplier)';
  }
}

class SimpleSearchResult extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? icon;
  final Widget? suffixIcon;

  const SimpleSearchResult({Key? key, required this.title, this.subtitle, this.icon, this.suffixIcon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        iconColor: app(context).primaryTextColor,
        title: title,
        subtitle: subtitle,
        leading: icon,
        trailing: suffixIcon,
        dense: true,
        mouseCursor: SystemMouseCursors.click,
      ),
    );
  }
}

class SearchItem {
  final List<Tag> tags;
  final Widget Function(BuildContext context, String query) builder;

  const SearchItem(this.tags, this.builder);

  double calculateRelevancyScore(String query) {
    return Search.calculateRelevancyScore(tags, query);
  }
}

class Searcher extends StatefulWidget {
  final SearchContext? searchContext;
  final String query;
  final int maxResults;
  final Widget Function(BuildContext context, Stream<SearchResult> resultStream) builder;

  const Searcher({Key? key, required this.query, required this.builder, this.maxResults = 10, required this.searchContext}) : super(key: key);

  @override
  SearcherState createState() => SearcherState();
}

class SearcherState extends State<Searcher> {
  SearchContext? _searchContext;
  late Stream<SearchResult> _resultStream;

  @override
  void initState() {
    super.initState();
    _searchContext = widget.searchContext;
    _resultStream = Search._search(_searchContext, widget.query, widget.maxResults);
  }

  @override
  void didUpdateWidget(covariant Searcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchContext != widget.searchContext || oldWidget.query != widget.query || oldWidget.maxResults != widget.maxResults) {
      _searchContext = widget.searchContext;
      _resultStream = Search._search(_searchContext, widget.query, widget.maxResults);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _resultStream);
  }
}

class Search extends StatelessWidget {
  final Stream<SearchResult> Function(String query, bool Function() isInterrupted) search;
  final Widget child;

  static Search generateRandomSearch(Widget child) {
    List<SearchItem> items = [
      SearchItem(
          [Tag('Lorem Ipsum', 1)],
          (context, query) => SimpleSearchResult(
                title: 'Lorem Ipsum'.asTextSearchableWidget(searchQuery: query.split(r'\s+').toList()),
                icon: Icon(Icons.accessible_forward),
                subtitle: 'Test'.asTextWidget(),
                suffixIcon: Icon(Icons.add),
              )),
      SearchItem([Tag('Dolor Sit Amet', 1)], (context, query) => 'Dolor Sit Amet'.asTextSearchableWidget(searchQuery: query.split(r'\s+').toList())),
      SearchItem([Tag('Consectetur Adipiscing Elit', 1)],
          (context, query) => 'Consectetur Adipiscing Elit'.asTextSearchableWidget(searchQuery: query.split(r'\s+').toList())),
      SearchItem(
          [Tag('Sed Do Eiusmod Tempor Incididunt Ut Labore Et Dolore Magna Aliqua', 1)],
          (context, query) =>
              'Sed Do Eiusmod Tempor Incididunt Ut Labore Et Dolore Magna Aliqua'.asTextSearchableWidget(searchQuery: query.split(r'\s+').toList())),
    ];
    return Search(
        search: (query, isInterrupted) async* {
          for (SearchItem item in items) {
            var calculateRelevancyScore = item.calculateRelevancyScore(query);
            if (calculateRelevancyScore == 0) {
              continue;
            }
            if (isInterrupted()) {
              break;
            }
            await Future.delayed(Duration(milliseconds: 1000));
            yield SearchResult(
                widget: Builder(
                  builder: (context) => item.builder(context, query),
                ),
                relevancyScore: calculateRelevancyScore);
            if (isInterrupted()) {
              break;
            }
          }
        },
        child: child);
  }

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

  static SearchContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SearchContext>();
  }

  static int _searchId = 0;
  static Stream<SearchResult> _search(SearchContext? searchContext, String query, [int maxSearchResult = 10]) async* {
    if (query.isEmpty) {
      return;
    }
    int searchId = ++_searchId;
    int count = 0;
    while (searchContext != null) {
      if (searchId != _searchId) {
        // if the search id has changed, then we should stop searching
        return;
      }
      // yield* searchContext.search(query, () => searchId != _searchId);
      await for (SearchResult result in searchContext.search(query, () => searchId != _searchId)) {
        if (searchId != _searchId) {
          // if the search id has changed, then we should stop searching
          return;
        }
        yield result;
        if (++count >= maxSearchResult) {
          interrupt();
          return;
        }
      }
      if (searchId != _searchId) {
        // if the search id has changed, then we should stop searching
        return;
      }
      searchContext = searchContext._parent;
    }
  }

  static void interrupt() {
    _searchId++;
  }

  @override
  Widget build(BuildContext context) {
    return SearchContext(
      parent: of(context),
      search: search,
      child: child,
    );
  }
}

class SearchResultList extends ValueNotifier<List<SearchResult>> {
  SearchResultList() : super([]);

  void _add(SearchResult result) {
    value.add(result);
    notifyListeners();
  }
}

class SearchResult {
  /// Sorts by relevancy score, from highest score to lowest score
  static int compare(SearchResult a, SearchResult b) {
    return b.relevancyScore.compareTo(a.relevancyScore);
  }

  final Widget widget;
  final double relevancyScore;
  const SearchResult({
    required this.widget,
    required this.relevancyScore,
  });
}
