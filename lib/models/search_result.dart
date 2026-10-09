class SearchResult {
  const SearchResult({
    required this.id,
    required this.title,
    required this.category,
    this.thumbnail,
    this.imageUrl,
    this.sourceUrl,
    this.sourceDomain,
    this.description,
    this.price,
    this.currency,
  });

  final String id;
  final String title;
  final String category;
  final String? thumbnail;
  final String? imageUrl;
  final String? sourceUrl;
  final String? sourceDomain;
  final String? description;
  final String? price;
  final String? currency;

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      category: json['category']?.toString() ?? 'visual_match',
      thumbnail: json['thumbnail']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      sourceUrl: json['sourceUrl']?.toString(),
      sourceDomain: json['sourceDomain']?.toString(),
      description: json['description']?.toString(),
      price: json['price']?.toString(),
      currency: json['currency']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'thumbnail': thumbnail,
        'imageUrl': imageUrl,
        'sourceUrl': sourceUrl,
        'sourceDomain': sourceDomain,
        'description': description,
        'price': price,
        'currency': currency,
      };

  bool get isProduct => category == 'product';

  static bool _isLoadableImageUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    final u = value.trim();
    return u.startsWith('http://') || u.startsWith('https://');
  }

  /// Thumbnail first (same order as result list), then full image URL.
  List<String> get imageCandidateUrls {
    final seen = <String>{};
    final out = <String>[];
    for (final candidate in [thumbnail, imageUrl]) {
      if (candidate == null) continue;
      final url = candidate.trim();
      if (!_isLoadableImageUrl(url)) continue;
      if (seen.add(url)) out.add(url);
    }
    return out;
  }

  String? get displayImageUrl {
    final urls = imageCandidateUrls;
    return urls.isEmpty ? null : urls.first;
  }

  /// Stable key for local favorites/history when [id] is missing or duplicated.
  String get favoriteId {
    if (id.isNotEmpty) return id;
    return 'h_${Object.hash(title, sourceUrl, imageUrl, thumbnail, category)}';
  }
}
