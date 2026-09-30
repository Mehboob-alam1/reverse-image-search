/// SerpApi credentials used when [SERPAPI_KEY] is not passed via `--dart-define`.
class ApiConfig {
  ApiConfig._();

  /// In-app upload/SerpApi trace on Searching + Results screens.
  static const bool showSearchDebugLog = true;

  /// SerpApi key (Google Reverse Image + Google Lens). Replace before production.
  /// https://serpapi.com/manage-api-key
  static const String serpApiKey = '';

  /// Bing Visual Search — sends the photo from the phone (no tmpfiles/catbox upload).
  /// Create a Bing Search v7 resource in Azure Portal and paste the key here.
  static const String bingVisualSearchKey = '';

  /// ImgBB — reliable public URL hosting for SerpApi when Bing key is empty.
  /// Free key: https://api.imgbb.com/
  static const String imgBbApiKey = '';
}
