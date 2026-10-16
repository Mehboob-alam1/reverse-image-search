/// Search API credentials (`--dart-define` or local values for development).
class ApiConfig {
  ApiConfig._();

  /// In-app search trace on Searching + Results screens.
  static const bool showSearchDebugLog = false;

  /// **Apify** Google Lens actor — fills Visual / Exact / Products lists.
  /// Prefer gitignored `dart_defines.dev.json` or `--dart-define=APIFY_TOKEN=...`.
  /// https://console.apify.com/account/integrations
  static const String apifyToken = '';

  /// **ChatGPT mini** — About tab + summaries (`gpt-4o-mini`).
  /// Prefer gitignored `dart_defines.dev.json` or `--dart-define=OPENAI_API_KEY=...`.
  static const String openAiApiKey = '';

  /// **Qwen-VL** on DashScope — multilingual insights fallback.
  /// https://dashscope.aliyun.com/
  static const String qwenApiKey = '';

  /// Bing Visual Search — sends the photo from the phone (no tmpfiles/catbox upload).
  /// Create a Bing Search v7 resource in Azure Portal and paste the key here.
  static const String bingVisualSearchKey = '';

  /// Optional ImgBB hosting. Leave empty if your ImgBB account/API key fails.
  /// Free key: https://api.imgbb.com/
  static const String imgBbApiKey = '';
}
