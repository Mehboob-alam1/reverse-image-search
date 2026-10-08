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

  /// Stable key for local favorites/history when [id] is missing or duplicated.
  String get favoriteId {
    if (id.isNotEmpty) return id;
    return 'h_${Object.hash(title, sourceUrl, imageUrl, thumbnail, category)}';
  }
}
