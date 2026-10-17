/// Android AdMob + remote toggles. Replace test IDs before release.
/// Remote JSON keys: see [AdsRemoteConfigKeys].
class AdConfig {
  AdConfig._();

  /// Master switch in code (remote `ads_enabled` must also be true).
  static const bool enableAdsOnAndroid = true;

  /// HTTPS JSON for ad toggles and unit IDs (Firebase Hosting, GitHub raw, etc.).
  /// Leave empty to use bundled defaults only.
  static const String remoteConfigUrl = '';

  /// Google sample app ID (replace with your AdMob app ID).
  static const String androidAdMobAppId =
      'ca-app-pub-3940256099942544~3347511713';

  static const String androidNativeUnitId =
      'ca-app-pub-3940256099942544/2247696110';

  static const String androidInterstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String androidAppOpenUnitId =
      'ca-app-pub-3940256099942544/9257395921';

  /// Collapsible banner test unit (regular banner test ID will not expand).
  /// Production: use your own banner unit + request extras `collapsible: bottom`.
  static const String androidBannerUnitId =
      'ca-app-pub-3940256099942544/2014213617';

  static const String androidRewardedUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static const Duration remoteConfigCacheTtl = Duration(hours: 6);
  static const Duration splashMinDuration = Duration(milliseconds: 2800);
  static const Duration adLoadTimeout = Duration(seconds: 12);
  static const int defaultInterstitialIntervalSeconds = 90;

  /// Insert a native ad after every N results in the results list.
  static const int resultsNativeAdEvery = 4;
}

class AdsRemoteConfigKeys {
  AdsRemoteConfigKeys._();

  static const adsEnabled = 'ads_enabled';
  static const nativeEnabled = 'native_bottom_enabled';
  static const interstitialEnabled = 'interstitial_enabled';
  static const appOpenEnabled = 'app_open_enabled';
  static const bannerEnabled = 'banner_enabled';
  static const rewardedEnabled = 'rewarded_enabled';
  static const interstitialIntervalSec = 'interstitial_interval_seconds';
  static const splashMinMs = 'splash_min_ms';
  static const nativeUnitId = 'android_native_unit_id';
  static const interstitialUnitId = 'android_interstitial_unit_id';
  static const appOpenUnitId = 'android_app_open_unit_id';
  static const bannerUnitId = 'android_banner_unit_id';
  static const rewardedUnitId = 'android_rewarded_unit_id';
}
