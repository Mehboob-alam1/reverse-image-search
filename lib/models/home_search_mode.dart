import 'search_type.dart';

/// Dashboard tile the user picked on [HomeScreen] (and related entry points).
enum HomeSearchMode {
  face,
  social,
  object,
  web,
  duplicate,
  similar,
  general;

  /// SerpApi Google Lens returns the fullest payload with [SearchType.all].
  /// Modes only change UI tab focus and optional domain filters.
  SearchType get searchType => SearchType.all;

  /// Prefer matches on these domains when filtering (falls back to full results if empty).
  List<String> get siteFilter {
    switch (this) {
      case HomeSearchMode.face:
        return const [
          'linkedin.com',
          'facebook.com',
          'instagram.com',
          'twitter.com',
          'x.com',
          'tiktok.com',
          'pinterest.com',
          'imdb.com',
        ];
      case HomeSearchMode.web:
        return const [];
      default:
        return const [];
    }
  }

  /// Default tab on [ResultsScreen]: 0 All, 1 Visual, 2 Exact, 3 Products, 4 About.
  int get resultsTabIndex {
    switch (this) {
      case HomeSearchMode.face:
        return 1;
      case HomeSearchMode.object:
        return 4;
      case HomeSearchMode.web:
        return 0;
      case HomeSearchMode.duplicate:
        return 2;
      case HomeSearchMode.similar:
        return 1;
      case HomeSearchMode.social:
        return 0;
      case HomeSearchMode.general:
        return 0;
    }
  }
}
