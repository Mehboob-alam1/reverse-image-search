/// Search API credentials (`--dart-define` or local values for development).
class ApiConfig {
  ApiConfig._();

  /// In-app search trace on Searching + Results screens.
  static const bool showSearchDebugLog = false;

  /// Apify API token — preferred when set (Google Lens actor).
  /// https://console.apify.com/account/integrations
  static const String apifyToken = '';

  /// SerpApi fallback when Apify token is empty.
  /// https://serpapi.com/manage-api-key
  static const String serpApiKey = '';

  /// Bing Visual Search — sends the photo from the phone (no tmpfiles/catbox upload).
  /// Create a Bing Search v7 resource in Azure Portal and paste the key here.
  static const String bingVisualSearchKey = '';

  /// Optional ImgBB hosting. Leave empty if your ImgBB account/API key fails.
  /// Free key: https://api.imgbb.com/
  static const String imgBbApiKey = '';
}
