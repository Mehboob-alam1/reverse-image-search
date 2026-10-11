/// Production search stack: Google Lens matches + AI insights (OpenAI mini / Qwen).
class SearchStackConfig {
  SearchStackConfig._();

  static const String lensEngineLabel = 'Google Lens';
  static const String insightsOpenAiLabel = 'GPT-4o mini';
  static const String insightsQwenLabel = 'Qwen-VL';

  static const String metadataLensWebUrl = 'googleLensWebUrl';
  static const String metadataInsightsProvider = 'insightsProvider';
  static const String metadataResultsSummary = 'resultsAiSummary';
}
