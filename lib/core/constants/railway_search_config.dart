/// Production reverse-image API (Railway).
class RailwaySearchConfig {
  RailwaySearchConfig._();

  static const String baseUrl =
      'https://reverse-image-search-api-production-7116.up.railway.app';

  static const String searchPath = '/api/search';
  static const String healthPath = '/health';

  /// Docs recommend ~15–60s; allow headroom.
  static const Duration searchTimeout = Duration(seconds: 90);

  static const int defaultK = 24;
  static const bool defaultWeb = true;
  static const double defaultMinScore = 0.5;
}
