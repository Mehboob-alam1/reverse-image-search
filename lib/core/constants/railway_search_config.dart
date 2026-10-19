/// Production reverse-image API (Railway).
/// [baseUrl] can be overridden at runtime from remote config (`api_base_url`).
class RailwaySearchConfig {
  RailwaySearchConfig._();

  static const String defaultBaseUrl =
      'https://reverse-image-search-api-production-7116.up.railway.app';

  static String _remoteBaseUrl = '';

  /// Active API root (no trailing slash). Remote config wins when non-empty.
  static String get baseUrl {
    final remote = _remoteBaseUrl.trim();
    if (remote.isNotEmpty) return _stripTrailingSlash(remote);
    return defaultBaseUrl;
  }

  /// Apply HTTPS API root from remote config. Empty / invalid → keep default.
  static void applyRemoteBaseUrl(String? url) {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) {
      _remoteBaseUrl = '';
      return;
    }
    final normalized = _stripTrailingSlash(raw);
    if (!normalized.startsWith('https://') && !normalized.startsWith('http://')) {
      return;
    }
    _remoteBaseUrl = normalized;
  }

  static String _stripTrailingSlash(String url) {
    if (url.length > 1 && url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  static const String searchPath = '/api/search';
  static const String healthPath = '/health';

  /// Docs recommend ~15–60s; allow headroom.
  static const Duration searchTimeout = Duration(seconds: 90);

  static const int defaultK = 24;
  static const bool defaultWeb = true;
  static const double defaultMinScore = 0.5;
}
