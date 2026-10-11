import 'search_result.dart';
import 'search_type.dart';

class AboutImageInfo {
  const AboutImageInfo({
    this.summary,
    this.possibleSource,
    this.relatedWebsites = const [],
    this.relatedSearches = const [],
    this.metadata = const {},
  });

  final String? summary;
  final String? possibleSource;
  final List<String> relatedWebsites;
  final List<String> relatedSearches;
  final Map<String, String> metadata;

  bool get hasContent =>
      (summary != null && summary!.isNotEmpty) ||
      (possibleSource != null && possibleSource!.isNotEmpty) ||
      relatedWebsites.isNotEmpty ||
      relatedSearches.isNotEmpty ||
      metadata.isNotEmpty;

  AboutImageInfo copyWith({
    String? summary,
    String? possibleSource,
    List<String>? relatedWebsites,
    List<String>? relatedSearches,
    Map<String, String>? metadata,
  }) {
    return AboutImageInfo(
      summary: summary ?? this.summary,
      possibleSource: possibleSource ?? this.possibleSource,
      relatedWebsites: relatedWebsites ?? this.relatedWebsites,
      relatedSearches: relatedSearches ?? this.relatedSearches,
      metadata: metadata ?? this.metadata,
    );
  }

  AboutImageInfo merge(AboutImageInfo other) {
    return AboutImageInfo(
      summary: (summary != null && summary!.isNotEmpty) ? summary : other.summary,
      possibleSource: (possibleSource != null && possibleSource!.isNotEmpty)
          ? possibleSource
          : other.possibleSource,
      relatedWebsites: relatedWebsites.isNotEmpty ? relatedWebsites : other.relatedWebsites,
      relatedSearches: relatedSearches.isNotEmpty ? relatedSearches : other.relatedSearches,
      metadata: {...other.metadata, ...metadata},
    );
  }

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'possibleSource': possibleSource,
        'relatedWebsites': relatedWebsites,
        'relatedSearches': relatedSearches,
        'metadata': metadata,
      };

  factory AboutImageInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AboutImageInfo();
    return AboutImageInfo(
      summary: json['summary']?.toString() ?? json['description']?.toString(),
      possibleSource: json['possibleSource']?.toString(),
      relatedWebsites: _stringList(json['relatedWebsites']),
      relatedSearches: _stringList(json['relatedSearches']),
      metadata: {
        for (final entry in (json['metadata'] as Map? ?? {}).entries)
          entry.key.toString(): entry.value.toString(),
      },
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}

class SearchResultsBundle {
  const SearchResultsBundle({
    this.visualMatches = const [],
    this.exactMatches = const [],
    this.products = const [],
    this.aboutImage,
  });

  final List<SearchResult> visualMatches;
  final List<SearchResult> exactMatches;
  final List<SearchResult> products;
  final AboutImageInfo? aboutImage;

  List<SearchResult> get all => [
        ...visualMatches,
        ...exactMatches,
        ...products,
      ];

  bool get isEmpty => all.isEmpty && !(aboutImage?.hasContent ?? false);

  Map<String, dynamic> toJson() => {
        'visualMatches': visualMatches.map((e) => e.toJson()).toList(),
        'exactMatches': exactMatches.map((e) => e.toJson()).toList(),
        'products': products.map((e) => e.toJson()).toList(),
        'aboutImage': aboutImage?.toJson(),
      };

  factory SearchResultsBundle.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SearchResultsBundle();
    return SearchResultsBundle(
      visualMatches: _results(json['visualMatches']),
      exactMatches: _results(json['exactMatches']),
      products: _results(json['products']),
      aboutImage: json['aboutImage'] is Map<String, dynamic>
          ? AboutImageInfo.fromJson(json['aboutImage'] as Map<String, dynamic>)
          : AboutImageInfo.fromJson(
              json['aboutImage'] is Map
                  ? Map<String, dynamic>.from(json['aboutImage'] as Map)
                  : null,
            ),
    );
  }

  static List<SearchResult> _results(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => SearchResult.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class SearchResponse {
  const SearchResponse({
    required this.searchId,
    required this.queryImage,
    required this.searchType,
    required this.results,
    this.success = true,
  });

  final String searchId;
  final String queryImage;
  final SearchType searchType;
  final SearchResultsBundle results;
  final bool success;

  SearchResponse copyWith({
    String? searchId,
    String? queryImage,
    SearchType? searchType,
    SearchResultsBundle? results,
    bool? success,
  }) {
    return SearchResponse(
      searchId: searchId ?? this.searchId,
      queryImage: queryImage ?? this.queryImage,
      searchType: searchType ?? this.searchType,
      results: results ?? this.results,
      success: success ?? this.success,
    );
  }

  SearchResponse forSites(List<String> domains) {
    if (domains.isEmpty) return this;
    bool matches(SearchResult item) {
      final hay = '${item.sourceUrl} ${item.sourceDomain} ${item.title} ${item.description}'
          .toLowerCase();
      return domains.any((domain) => hay.contains(domain.toLowerCase()));
    }

    final filtered = SearchResultsBundle(
      visualMatches: results.visualMatches.where(matches).toList(),
      exactMatches: results.exactMatches.where(matches).toList(),
      products: results.products.where(matches).toList(),
      aboutImage: results.aboutImage,
    );
    return filtered.isEmpty
        ? this
        : SearchResponse(
            searchId: searchId,
            queryImage: queryImage,
            searchType: searchType,
            results: filtered,
            success: success,
          );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'searchId': searchId,
        'queryImage': queryImage,
        'searchType': searchType.apiValue,
        'results': results.toJson(),
      };

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      success: json['success'] != false,
      searchId: json['searchId']?.toString() ?? '',
      queryImage: json['queryImage']?.toString() ?? '',
      searchType: SearchType.fromValue(json['searchType']?.toString()),
      results: SearchResultsBundle.fromJson(
        json['results'] is Map
            ? Map<String, dynamic>.from(json['results'] as Map)
            : null,
      ),
    );
  }
}
