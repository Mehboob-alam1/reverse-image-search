import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants/storage_keys.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage(ref.watch(sharedPreferencesProvider));
});

class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  SharedPreferences get prefs => _prefs;

  bool get hasSelectedLanguage =>
      _prefs.getBool(StorageKeys.hasCompletedLanguageSelection) ?? false;

  bool get hasSeenPro => _prefs.getBool(StorageKeys.hasSeenProScreen) ?? false;

  bool get hasCompletedOnboarding =>
      _prefs.getBool(StorageKeys.hasCompletedOnboarding) ?? false;

  bool get hasCompletedPermissions =>
      _prefs.getBool(StorageKeys.hasCompletedPermissions) ?? false;

  String get languageCode =>
      _prefs.getString(StorageKeys.selectedLanguage) ?? 'en';

  String get themeMode => _prefs.getString(StorageKeys.themeMode) ?? 'system';

  String get defaultSearchMode =>
      _prefs.getString(StorageKeys.defaultSearchMode) ?? 'all';

  bool get openResultsExternally =>
      _prefs.getBool(StorageKeys.openResultsExternally) ?? true;

  bool get saveHistoryAutomatically =>
      _prefs.getBool(StorageKeys.saveHistoryAutomatically) ?? true;

  bool get notificationsEnabled =>
      _prefs.getBool(StorageKeys.notificationsEnabled) ?? true;

  Future<void> setLanguage(String code) async {
    await _prefs.setString(StorageKeys.selectedLanguage, code);
    await _prefs.setBool(StorageKeys.hasCompletedLanguageSelection, true);
  }

  Future<void> markProSeen() =>
      _prefs.setBool(StorageKeys.hasSeenProScreen, true);

  Future<void> markOnboardingComplete() =>
      _prefs.setBool(StorageKeys.hasCompletedOnboarding, true);

  Future<void> markPermissionsComplete() =>
      _prefs.setBool(StorageKeys.hasCompletedPermissions, true);

  Future<void> setThemeMode(String mode) =>
      _prefs.setString(StorageKeys.themeMode, mode);

  Future<void> setDefaultSearchMode(String mode) =>
      _prefs.setString(StorageKeys.defaultSearchMode, mode);

  Future<void> setOpenResultsExternally(bool value) =>
      _prefs.setBool(StorageKeys.openResultsExternally, value);

  Future<void> setSaveHistoryAutomatically(bool value) =>
      _prefs.setBool(StorageKeys.saveHistoryAutomatically, value);

  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(StorageKeys.notificationsEnabled, value);

  String guestId() {
    final existing = _prefs.getString(StorageKeys.guestId);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = const Uuid().v4();
    _prefs.setString(StorageKeys.guestId, created);
    return created;
  }

  List<Map<String, dynamic>> readJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> writeJsonList(String key, List<Map<String, dynamic>> items) {
    return _prefs.setString(key, jsonEncode(items));
  }

  Future<void> clearAuthScopedData() async {
    await _prefs.remove(StorageKeys.localFavorites);
    await _prefs.remove(StorageKeys.localHistory);
    await _prefs.remove(StorageKeys.localSearchCache);
    await _prefs.remove(StorageKeys.recentSearches);
  }
}
