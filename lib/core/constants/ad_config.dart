/// Android AdMob + remote toggles. iOS never shows ads.
/// Hostable JSON: [assets/ads/ads_remote_config.json] — see [AdsRemoteConfigKeys].
class AdConfig {
  AdConfig._();

  /// Local kill-switch. Remote `ads_enabled` must also be true (Android only).
  static const bool enableAdsOnAndroid = true;

  /// HTTPS JSON for ad toggles + Android unit IDs.
  /// Override: `--dart-define=ADS_REMOTE_CONFIG_URL=https://.../ads_remote_config.json`
  static const String remoteConfigUrl = String.fromEnvironment(
    'ADS_REMOTE_CONFIG_URL',
    defaultValue: '',
  );

  static const String androidAdMobAppId =
      'ca-app-pub-3940256099942544~3347511713';

  static const String androidNativeUnitId =
      'ca-app-pub-3940256099942544/2247696110';

  static const String androidInterstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String androidAppOpenUnitId =
      'ca-app-pub-3940256099942544/9257395921';

  static const String androidBannerUnitId =
      'ca-app-pub-3940256099942544/2014213617';

  static const String androidRewardedUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static const Duration remoteConfigCacheTtl = Duration(hours: 6);
  static const Duration splashMinDuration = Duration(milliseconds: 2800);
  static const Duration adLoadTimeout = Duration(seconds: 12);

  /// Fallback when remote omits strategy keys.
  static const int defaultInterstitialIntervalSeconds = 75;
  static const int defaultFullscreenMinGapSeconds = 40;
  static const int defaultInterstitialLoadWaitMs = 2500;
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

  /// Show interstitial when a search finishes successfully.
  static const interstitialAfterSearch = 'interstitial_after_search';

  /// Min seconds between two interstitial impressions (Firebase-style key).
  static const interstitialCooldownSec = 'interstitial_cooldown_sec';

  /// Legacy alias for [interstitialCooldownSec].
  static const interstitialIntervalSec = 'interstitial_interval_seconds';

  /// Min seconds between any fullscreen ads (app-open / interstitial / rewarded).
  static const fullscreenMinGapSec = 'fullscreen_min_gap_seconds';

  /// How long to wait for a preloaded interstitial before giving up.
  static const interstitialLoadWaitMs = 'interstitial_load_wait_ms';

  /// Insert an in-feed native every N result cards (0 = off).
  static const nativeEveryN = 'native_every_n_results';

  static const splashMinMs = 'splash_min_ms';

  /// Railway (or other) reverse-image API root URL. Empty = app default.
  static const apiBaseUrl = 'api_base_url';

  /// Short unit-ID keys (Firebase Remote Config style).
  static const banner = 'banner';
  static const interstitial = 'interstitial';
  static const rewarded = 'rewarded';
  static const appOpen = 'app_open';
  static const native = 'native';

  /// Legacy aliases (still accepted).
  static const nativeUnitId = 'android_native_unit_id';
  static const interstitialUnitId = 'android_interstitial_unit_id';
  static const appOpenUnitId = 'android_app_open_unit_id';
  static const bannerUnitId = 'android_banner_unit_id';
  static const rewardedUnitId = 'android_rewarded_unit_id';
}
