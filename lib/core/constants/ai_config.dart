/// Vision + text models for image insights (About tab, summaries).
class AiConfig {
  AiConfig._();

  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String openAiMiniModel = 'gpt-4o-mini';

  /// DashScope OpenAI-compatible endpoint (Qwen-VL).
  static const String qwenBaseUrl =
      'https://dashscope.aliyuncs.com/compatible-mode/v1';
  static const String qwenVisionModel = 'qwen-vl-plus';

  static const Duration aiTimeout = Duration(seconds: 45);

  /// Locales where Qwen is preferred for vision copy (multilingual quality).
  static const Set<String> qwenPreferredLanguages = {
    'hi',
    'ur',
    'ar',
    'id',
    'tr',
    'zh',
    'fa',
  };

  static bool preferQwenForLocale(String languageCode) {
    return qwenPreferredLanguages.contains(languageCode.split('-').first);
  }
}
