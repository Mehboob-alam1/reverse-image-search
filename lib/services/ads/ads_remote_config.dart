import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/ad_config.dart';
import '../../core/constants/railway_search_config.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/storage/local_storage.dart';

class AdsRemoteSettings {
  const AdsRemoteSettings({
    required this.adsEnabled,
    required this.nativeBottomEnabled,
    required this.interstitialEnabled,
    required this.appOpenEnabled,
    required this.bannerEnabled,
    required this.rewardedEnabled,
    required this.interstitialAfterSearch,
    required this.interstitialIntervalSeconds,
    required this.fullscreenMinGapSeconds,
    required this.interstitialLoadWaitMs,
    required this.nativeEveryNResults,
    required this.splashMinMs,
    required this.apiBaseUrl,
    required this.nativeUnitId,
    required this.interstitialUnitId,
    required this.appOpenUnitId,
    required this.bannerUnitId,
    required this.rewardedUnitId,
  });

  /// Ads are Android-only; API URL applies on all platforms.
  factory AdsRemoteSettings.defaults() {
    final android = !kIsWeb && Platform.isAndroid;
    return AdsRemoteSettings(
      adsEnabled: android && AdConfig.enableAdsOnAndroid,
      nativeBottomEnabled: android,
      interstitialEnabled: android,
      appOpenEnabled: android,
      bannerEnabled: android,
      rewardedEnabled: android,
      interstitialAfterSearch: android,
      interstitialIntervalSeconds: AdConfig.defaultInterstitialIntervalSeconds,
      fullscreenMinGapSeconds: AdConfig.defaultFullscreenMinGapSeconds,
      interstitialLoadWaitMs: AdConfig.defaultInterstitialLoadWaitMs,
      nativeEveryNResults: AdConfig.resultsNativeAdEvery,
      splashMinMs: AdConfig.splashMinDuration.inMilliseconds,
      apiBaseUrl: RailwaySearchConfig.defaultBaseUrl,
      nativeUnitId: AdConfig.androidNativeUnitId,
      interstitialUnitId: AdConfig.androidInterstitialUnitId,
      appOpenUnitId: AdConfig.androidAppOpenUnitId,
      bannerUnitId: AdConfig.androidBannerUnitId,
      rewardedUnitId: AdConfig.androidRewardedUnitId,
    );
  }

  factory AdsRemoteSettings.fromMap(Map<String, dynamic> map) {
    final defaults = AdsRemoteSettings.defaults();
    final android = !kIsWeb && Platform.isAndroid;

    String unit(List<String> keys, String fallback) {
      for (final key in keys) {
        final v = map[key]?.toString().trim() ?? '';
        if (v.isNotEmpty) return v;
      }
      return fallback;
    }

    Object? first(List<String> keys) {
      for (final key in keys) {
        if (map.containsKey(key) && map[key] != null) return map[key];
      }
      return null;
    }

    final apiBaseUrl = unit(
      [AdsRemoteConfigKeys.apiBaseUrl],
      defaults.apiBaseUrl,
    );

    if (!android) {
      return AdsRemoteSettings(
        adsEnabled: false,
        nativeBottomEnabled: false,
        interstitialEnabled: false,
        appOpenEnabled: false,
        bannerEnabled: false,
        rewardedEnabled: false,
        interstitialAfterSearch: false,
        interstitialIntervalSeconds: defaults.interstitialIntervalSeconds,
        fullscreenMinGapSeconds: defaults.fullscreenMinGapSeconds,
        interstitialLoadWaitMs: defaults.interstitialLoadWaitMs,
        nativeEveryNResults: defaults.nativeEveryNResults,
        splashMinMs: _int(map[AdsRemoteConfigKeys.splashMinMs], defaults.splashMinMs)
            .clamp(1500, 8000),
        apiBaseUrl: apiBaseUrl,
        nativeUnitId: defaults.nativeUnitId,
        interstitialUnitId: defaults.interstitialUnitId,
        appOpenUnitId: defaults.appOpenUnitId,
        bannerUnitId: defaults.bannerUnitId,
        rewardedUnitId: defaults.rewardedUnitId,
      );
    }

    return AdsRemoteSettings(
      adsEnabled: _bool(map[AdsRemoteConfigKeys.adsEnabled], defaults.adsEnabled) &&
          AdConfig.enableAdsOnAndroid,
      nativeBottomEnabled:
          _bool(map[AdsRemoteConfigKeys.nativeEnabled], defaults.nativeBottomEnabled),
      interstitialEnabled: _bool(
        map[AdsRemoteConfigKeys.interstitialEnabled],
        defaults.interstitialEnabled,
      ),
      appOpenEnabled:
          _bool(map[AdsRemoteConfigKeys.appOpenEnabled], defaults.appOpenEnabled),
      bannerEnabled:
          _bool(map[AdsRemoteConfigKeys.bannerEnabled], defaults.bannerEnabled),
      rewardedEnabled:
          _bool(map[AdsRemoteConfigKeys.rewardedEnabled], defaults.rewardedEnabled),
      interstitialAfterSearch: _bool(
        map[AdsRemoteConfigKeys.interstitialAfterSearch],
        defaults.interstitialAfterSearch,
      ),
      interstitialIntervalSeconds: _int(
        first([
          AdsRemoteConfigKeys.interstitialCooldownSec,
          AdsRemoteConfigKeys.interstitialIntervalSec,
        ]),
        defaults.interstitialIntervalSeconds,
      ).clamp(15, 600),
      fullscreenMinGapSeconds: _int(
        map[AdsRemoteConfigKeys.fullscreenMinGapSec],
        defaults.fullscreenMinGapSeconds,
      ).clamp(15, 300),
      interstitialLoadWaitMs: _int(
        map[AdsRemoteConfigKeys.interstitialLoadWaitMs],
        defaults.interstitialLoadWaitMs,
      ).clamp(500, 8000),
      nativeEveryNResults: _int(
        map[AdsRemoteConfigKeys.nativeEveryN],
        defaults.nativeEveryNResults,
      ).clamp(0, 20),
      splashMinMs: _int(map[AdsRemoteConfigKeys.splashMinMs], defaults.splashMinMs)
          .clamp(1500, 8000),
      apiBaseUrl: apiBaseUrl,
      nativeUnitId: unit(
        [AdsRemoteConfigKeys.native, AdsRemoteConfigKeys.nativeUnitId],
        defaults.nativeUnitId,
      ),
      interstitialUnitId: unit(
        [AdsRemoteConfigKeys.interstitial, AdsRemoteConfigKeys.interstitialUnitId],
        defaults.interstitialUnitId,
      ),
      appOpenUnitId: unit(
        [AdsRemoteConfigKeys.appOpen, AdsRemoteConfigKeys.appOpenUnitId],
        defaults.appOpenUnitId,
      ),
      bannerUnitId: unit(
        [AdsRemoteConfigKeys.banner, AdsRemoteConfigKeys.bannerUnitId],
        defaults.bannerUnitId,
      ),
      rewardedUnitId: unit(
        [AdsRemoteConfigKeys.rewarded, AdsRemoteConfigKeys.rewardedUnitId],
        defaults.rewardedUnitId,
      ),
    );
  }

  final bool adsEnabled;
  final bool nativeBottomEnabled;
  final bool interstitialEnabled;
  final bool appOpenEnabled;
  final bool bannerEnabled;
  final bool rewardedEnabled;
  final bool interstitialAfterSearch;
  final int interstitialIntervalSeconds;
  final int fullscreenMinGapSeconds;
  final int interstitialLoadWaitMs;
  final int nativeEveryNResults;
  final int splashMinMs;
  final String apiBaseUrl;
  final String nativeUnitId;
  final String interstitialUnitId;
  final String appOpenUnitId;
  final String bannerUnitId;
  final String rewardedUnitId;

  static bool _bool(Object? value, bool fallback) {
    if (value == null) return fallback;
    if (value is bool) return value;
    final s = value.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return fallback;
  }

  static int _int(Object? value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}

final adsRemoteSettingsProvider = FutureProvider<AdsRemoteSettings>((ref) async {
  final storage = ref.read(localStorageProvider);
  return AdsRemoteConfigLoader(storage).load();
});

class AdsRemoteConfigLoader {
  AdsRemoteConfigLoader(this._storage);

  final LocalStorage _storage;

  Future<AdsRemoteSettings> load() async {
    // Fetch on every platform so `api_base_url` applies; ads stay Android-only
    // inside [AdsRemoteSettings.fromMap].
    var settings = await _loadBundledDefaults();
    final cached = _readCache();
    if (cached != null) {
      settings = AdsRemoteSettings.fromMap({..._toMap(settings), ...cached});
    }

    final url = AdConfig.remoteConfigUrl.trim();
    if (url.isEmpty) {
      RailwaySearchConfig.applyRemoteBaseUrl(settings.apiBaseUrl);
      return settings;
    }

    try {
      final remote = await _fetchRemote(url);
      if (remote != null) {
        await _writeCache(remote);
        settings = AdsRemoteSettings.fromMap({..._toMap(settings), ...remote});
      }
    } on Object {
      // Keep cached / bundled values when offline.
    }
    RailwaySearchConfig.applyRemoteBaseUrl(settings.apiBaseUrl);
    return settings;
  }

  Future<AdsRemoteSettings> _loadBundledDefaults() async {
    try {
      final raw =
          await rootBundle.loadString('assets/ads/remote_config_defaults.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AdsRemoteSettings.fromMap(decoded);
      }
      if (decoded is Map) {
        return AdsRemoteSettings.fromMap(Map<String, dynamic>.from(decoded));
      }
    } on Object {
      // ignore
    }
    return AdsRemoteSettings.defaults();
  }

  Future<Map<String, dynamic>?> _fetchRemote(String url) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    final response = await dio.get<dynamic>(url);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  Map<String, dynamic> _toMap(AdsRemoteSettings s) => {
        AdsRemoteConfigKeys.adsEnabled: s.adsEnabled,
        AdsRemoteConfigKeys.nativeEnabled: s.nativeBottomEnabled,
        AdsRemoteConfigKeys.interstitialEnabled: s.interstitialEnabled,
        AdsRemoteConfigKeys.appOpenEnabled: s.appOpenEnabled,
        AdsRemoteConfigKeys.bannerEnabled: s.bannerEnabled,
        AdsRemoteConfigKeys.rewardedEnabled: s.rewardedEnabled,
        AdsRemoteConfigKeys.interstitialAfterSearch: s.interstitialAfterSearch,
        AdsRemoteConfigKeys.interstitialCooldownSec: s.interstitialIntervalSeconds,
        AdsRemoteConfigKeys.fullscreenMinGapSec: s.fullscreenMinGapSeconds,
        AdsRemoteConfigKeys.interstitialLoadWaitMs: s.interstitialLoadWaitMs,
        AdsRemoteConfigKeys.nativeEveryN: s.nativeEveryNResults,
        AdsRemoteConfigKeys.splashMinMs: s.splashMinMs,
        AdsRemoteConfigKeys.apiBaseUrl: s.apiBaseUrl,
        AdsRemoteConfigKeys.native: s.nativeUnitId,
        AdsRemoteConfigKeys.interstitial: s.interstitialUnitId,
        AdsRemoteConfigKeys.appOpen: s.appOpenUnitId,
        AdsRemoteConfigKeys.banner: s.bannerUnitId,
        AdsRemoteConfigKeys.rewarded: s.rewardedUnitId,
      };

  Map<String, dynamic>? _readCache() {
    final prefs = _storage.prefs;
    final raw = prefs.getString(StorageKeys.adsRemoteConfigJson);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on Object {
      // ignore
    }
    return null;
  }

  Future<void> _writeCache(Map<String, dynamic> remote) async {
    final prefs = _storage.prefs;
    await prefs.setString(StorageKeys.adsRemoteConfigJson, jsonEncode(remote));
    await prefs.setInt(
      StorageKeys.adsRemoteConfigFetchedAt,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
