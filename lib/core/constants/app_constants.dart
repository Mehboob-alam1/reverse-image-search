import 'api_config.dart';
import 'subscription_config.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Deep Image Search';
  static const String packageName = 'com.reverseimagesearch.app';

  static const Duration splashDuration = Duration(milliseconds: 1600);
  static const Duration apiTimeout = Duration(seconds: 45);
  static const Duration connectTimeout = Duration(seconds: 20);

  static const int maxImageBytes = 25 * 1024 * 1024;
  /// Free searches per install — see [SubscriptionConfig.freeLifetimeSearches].
  static const int freeSearchCredits = SubscriptionConfig.freeLifetimeSearches;

  /// Legacy display cap; subscribers use period allowances in [SubscriptionConfig].
  static const int proSearchLimit = SubscriptionConfig.weeklySearchAllowance;
  static const int recentSearchLimit = 20;

  static const List<String> supportedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  static const List<String> supportedMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];

  static const String weeklyProductId = SubscriptionConfig.weeklyProductId;
  static const String monthlyProductId = SubscriptionConfig.monthlyProductId;
  static const String yearlyProductId = SubscriptionConfig.yearlyProductId;

  static const String supportEmail = 'support@reverseimagesearch.app';
  static const String privacyUrl = 'https://reverseimagesearch.app/privacy';
  static const String termsUrl = 'https://reverseimagesearch.app/terms';
}

class AppEnv {
  AppEnv._();

  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'development',
  );

  static const String _apifyTokenFromDefine =
      String.fromEnvironment('APIFY_TOKEN');
  static const String _serpApiKeyFromDefine = String.fromEnvironment('SERPAPI_KEY');

  static String get apifyToken =>
      _apifyTokenFromDefine.isNotEmpty ? _apifyTokenFromDefine : ApiConfig.apifyToken;

  /// Non-empty `--dart-define=SERPAPI_KEY=...` wins; otherwise [ApiConfig.serpApiKey].
  static String get serpApiKey =>
      _serpApiKeyFromDefine.isNotEmpty ? _serpApiKeyFromDefine : ApiConfig.serpApiKey;

  static bool get useApifySearch => apifyToken.isNotEmpty;

  static bool get isProduction => flavor == 'production';
  static bool get isDevelopment => flavor == 'development';
  static bool get verboseLogging => !isProduction;
}
