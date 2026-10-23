import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// Encrypted local store for subscription / credit entitlement.
///
/// Uses platform secure storage (EncryptedSharedPreferences / Keychain).
/// This raises the bar vs plain SharedPreferences but is **not** unbreakable
/// on a rooted/jailbroken device or patched APK.
class SubscriptionVault {
  SubscriptionVault._(this._storage, this._cache);

  final FlutterSecureStorage? _storage;
  final Map<String, String> _cache;

  static const _bundleKey = 'sub_entitlement_v1';

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const FlutterSecureStorage _defaultSecure = FlutterSecureStorage(
    aOptions: _androidOptions,
  );

  /// Opens vault from secure storage and migrates legacy plaintext prefs once.
  static Future<SubscriptionVault> open({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? migrateFrom,
  }) async {
    final storage = secureStorage ?? _defaultSecure;
    final vault = SubscriptionVault._(storage, {});
    await vault._load();
    if (migrateFrom != null) {
      await vault._migrateFromPrefs(migrateFrom);
    }
    return vault;
  }

  /// In-memory vault for unit tests (no platform channel).
  factory SubscriptionVault.memory([Map<String, String>? seed]) {
    return SubscriptionVault._(null, Map<String, String>.from(seed ?? {}));
  }

  Future<void> _load() async {
    final storage = _storage;
    if (storage == null) return;
    final raw = await storage.read(key: _bundleKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((key, value) {
          if (key is String) {
            _cache[key] = value?.toString() ?? '';
          }
        });
      }
    } on Object {
      // Corrupt blob — start clean; user can Restore Purchases.
      _cache.clear();
    }
  }

  Future<void> _persist() async {
    final storage = _storage;
    if (storage == null) return;
    await storage.write(key: _bundleKey, value: jsonEncode(_cache));
  }

  Future<void> _migrateFromPrefs(SharedPreferences prefs) async {
    const legacyKeys = [
      StorageKeys.isProEntitled,
      StorageKeys.subscriptionPlan,
      StorageKeys.subscriptionExpiresAt,
      StorageKeys.subscriptionPeriodStartAt,
      StorageKeys.subscriptionPeriodSearchAllowance,
      StorageKeys.subscriptionPeriodSearchesUsed,
      StorageKeys.hasStartedIntroTrial,
      StorageKeys.searchCreditsUsed,
      StorageKeys.rewardedBonusCredits,
      StorageKeys.lastSearchAtMs,
    ];

    var migrated = false;
    for (final key in legacyKeys) {
      if (_cache.containsKey(key)) continue;
      if (!prefs.containsKey(key)) continue;
      final value = prefs.get(key);
      if (value == null) continue;
      _cache[key] = value.toString();
      migrated = true;
    }

    if (!migrated) return;
    await _persist();
    for (final key in legacyKeys) {
      await prefs.remove(key);
    }
  }

  bool? getBool(String key) {
    final raw = _cache[key];
    if (raw == null || raw.isEmpty) return null;
    if (raw == 'true') return true;
    if (raw == 'false') return false;
    return null;
  }

  int? getInt(String key) {
    final raw = _cache[key];
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  String? getString(String key) {
    final raw = _cache[key];
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  Future<void> setBool(String key, bool value) async {
    _cache[key] = value.toString();
    await _persist();
  }

  Future<void> setInt(String key, int value) async {
    _cache[key] = value.toString();
    await _persist();
  }

  Future<void> setString(String key, String value) async {
    _cache[key] = value;
    await _persist();
  }

  /// Updates memory immediately and schedules encrypted persist (non-blocking).
  void putBool(String key, bool value) {
    _cache[key] = value.toString();
    _persist();
  }

  void putInt(String key, int value) {
    _cache[key] = value.toString();
    _persist();
  }

  void putString(String key, String value) {
    _cache[key] = value;
    _persist();
  }

  Future<void> remove(String key) async {
    _cache.remove(key);
    await _persist();
  }
}
