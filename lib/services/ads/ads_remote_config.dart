import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/ad_config.dart';
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
    required this.interstitialIntervalSeconds,
    required this.splashMinMs,
    required this.nativeUnitId,
    required this.interstitialUnitId,
    required this.appOpenUnitId,
    required this.bannerUnitId,
    required this.rewardedUnitId,
  });

  factory AdsRemoteSettings.defaults() {
    return AdsRemoteSettings(
      adsEnabled: AdConfig.enableAdsOnAndroid,
      nativeBottomEnabled: true,
      interstitialEnabled: true,
      appOpenEnabled: true,
      bannerEnabled: true,
      rewardedEnabled: true,
      interstitialIntervalSeconds: AdConfig.defaultInterstitialIntervalSeconds,
      splashMinMs: AdConfig.splashMinDuration.inMilliseconds,
      nativeUnitId: AdConfig.androidNativeUnitId,
      interstitialUnitId: AdConfig.androidInterstitialUnitId,
      appOpenUnitId: AdConfig.androidAppOpenUnitId,
      bannerUnitId: AdConfig.androidBannerUnitId,
      rewardedUnitId: AdConfig.androidRewardedUnitId,
    );
  }

  factory AdsRemoteSettings.fromMap(Map<String, dynamic> map) {
    final defaults = AdsRemoteSettings.defaults();
    String unit(String key, String fallback) {
      final v = map[key]?.toString().trim() ?? '';
      return v.isEmpty ? fallback : v;
    }

    return AdsRemoteSettings(
      adsEnabled: _bool(map[AdsRemoteConfigKeys.adsEnabled], defaults.adsEnabled),
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
      interstitialIntervalSeconds: _int(
        map[AdsRemoteConfigKeys.interstitialIntervalSec],
        defaults.interstitialIntervalSeconds,
      ).clamp(30, 600),
      splashMinMs: _int(map[AdsRemoteConfigKeys.splashMinMs], defaults.splashMinMs)
          .clamp(1500, 8000),
      nativeUnitId: unit(AdsRemoteConfigKeys.nativeUnitId, defaults.nativeUnitId),
      interstitialUnitId:
          unit(AdsRemoteConfigKeys.interstitialUnitId, defaults.interstitialUnitId),
      appOpenUnitId: unit(AdsRemoteConfigKeys.appOpenUnitId, defaults.appOpenUnitId),
      bannerUnitId: unit(AdsRemoteConfigKeys.bannerUnitId, defaults.bannerUnitId),
      rewardedUnitId:
          unit(AdsRemoteConfigKeys.rewardedUnitId, defaults.rewardedUnitId),
    );
  }

  final bool adsEnabled;
  final bool nativeBottomEnabled;
  final bool interstitialEnabled;
  final bool appOpenEnabled;
  final bool bannerEnabled;
  final bool rewardedEnabled;
  final int interstitialIntervalSeconds;
  final int splashMinMs;
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
    var settings = await _loadBundledDefaults();
    final cached = _readCache();
    if (cached != null) {
      settings = AdsRemoteSettings.fromMap({..._toMap(settings), ...cached});
    }
    if (AdConfig.remoteConfigUrl.isEmpty) {
      return settings;
    }
    if (!_cacheExpired()) {
      return settings;
    }
    try {
      final remote = await _fetchRemote();
      if (remote != null) {
        await _writeCache(remote);
        settings = AdsRemoteSettings.fromMap({..._toMap(settings), ...remote});
      }
    } on Object {
      // Keep cached / bundled values when offline.
    }
    return settings;
  }

  Future<AdsRemoteSettings> _loadBundledDefaults() async {
    try {
      final raw = await rootBundle.loadString('assets/ads/remote_config_defaults.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AdsRemoteSettings.fromMap(decoded);
      }
    } on Object {
      // ignore
    }
    return AdsRemoteSettings.defaults();
  }

  Future<Map<String, dynamic>?> _fetchRemote() async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    final response = await dio.get<dynamic>(AdConfig.remoteConfigUrl);
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
        AdsRemoteConfigKeys.interstitialIntervalSec: s.interstitialIntervalSeconds,
        AdsRemoteConfigKeys.splashMinMs: s.splashMinMs,
        AdsRemoteConfigKeys.nativeUnitId: s.nativeUnitId,
        AdsRemoteConfigKeys.interstitialUnitId: s.interstitialUnitId,
        AdsRemoteConfigKeys.appOpenUnitId: s.appOpenUnitId,
        AdsRemoteConfigKeys.bannerUnitId: s.bannerUnitId,
        AdsRemoteConfigKeys.rewardedUnitId: s.rewardedUnitId,
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

  bool _cacheExpired() {
    final prefs = _storage.prefs;
    final ts = prefs.getInt(StorageKeys.adsRemoteConfigFetchedAt);
    if (ts == null) return true;
    final fetched = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(fetched) > AdConfig.remoteConfigCacheTtl;
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
