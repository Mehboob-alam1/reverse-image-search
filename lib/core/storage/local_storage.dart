import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../constants/storage_keys.dart';
import '../constants/subscription_config.dart';
import '../../models/user_models.dart';

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

  bool get isProEntitled =>
      _prefs.getBool(StorageKeys.isProEntitled) ?? false;

  Future<void> setProEntitled(bool value) =>
      _prefs.setBool(StorageKeys.isProEntitled, value);

  int get searchCreditsUsed =>
      _prefs.getInt(StorageKeys.searchCreditsUsed) ?? 0;

  bool get hasStartedIntroTrial =>
      _prefs.getBool(StorageKeys.hasStartedIntroTrial) ?? false;

  DateTime? get subscriptionExpiresAt {
    final ms = _prefs.getInt(StorageKeys.subscriptionExpiresAt);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  String get subscriptionPlan =>
      _prefs.getString(StorageKeys.subscriptionPlan) ?? 'none';

  int get subscriptionPeriodSearchesUsed =>
      _prefs.getInt(StorageKeys.subscriptionPeriodSearchesUsed) ?? 0;

  int get subscriptionPeriodSearchAllowance =>
      _prefs.getInt(StorageKeys.subscriptionPeriodSearchAllowance) ??
      SubscriptionConfig.weeklySearchAllowance;

  DateTime? get subscriptionPeriodStartAt {
    final ms = _prefs.getInt(StorageKeys.subscriptionPeriodStartAt);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  DateTime? get lastSearchAt {
    final ms = _prefs.getInt(StorageKeys.lastSearchAtMs);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// True while subscription/trial window is active (premium UX, not unlimited API).
  bool get hasActivePremiumAccess {
    if (!isProEntitled) return false;
    final expires = subscriptionExpiresAt;
    if (expires == null) return true;
    return DateTime.now().isBefore(expires);
  }

  void _expireSubscriptionIfNeededSync() {
    final expires = subscriptionExpiresAt;
    if (expires != null && !DateTime.now().isBefore(expires)) {
      _prefs.setBool(StorageKeys.isProEntitled, false);
      _prefs.setString(StorageKeys.subscriptionPlan, 'none');
    }
  }

  Future<void> _expireSubscriptionIfNeeded() async {
    _expireSubscriptionIfNeededSync();
  }

  void _maybeRollSubscriptionPeriod() {
    if (!hasActivePremiumAccess) return;
    final plan = subscriptionPlan;
    if (plan == 'trial') return;

    final start = subscriptionPeriodStartAt;
    if (start == null) return;

    final periodLength = switch (plan) {
      'monthly' => SubscriptionConfig.monthlyPeriod,
      'yearly' => const Duration(days: 365),
      _ => const Duration(days: 7),
    };

    final now = DateTime.now();
    if (now.difference(start) < periodLength) return;

    final allowance = subscriptionPeriodSearchAllowance;
    _prefs.setInt(StorageKeys.subscriptionPeriodStartAt, now.millisecondsSinceEpoch);
    _prefs.setInt(StorageKeys.subscriptionPeriodSearchesUsed, 0);
    _prefs.setInt(StorageKeys.subscriptionPeriodSearchAllowance, allowance);
  }

  Future<void> _ensureLegacyPremiumMetadata() async {
    if (isProEntitled && subscriptionExpiresAt == null) {
      final now = DateTime.now();
      await _prefs.setInt(
        StorageKeys.subscriptionExpiresAt,
        now.add(const Duration(days: 7)).millisecondsSinceEpoch,
      );
      await _prefs.setString(StorageKeys.subscriptionPlan, 'weekly');
      await _startSearchPeriod(
        now,
        allowance: SubscriptionConfig.weeklySearchAllowance,
      );
    }
  }

  Future<void> _startSearchPeriod(DateTime start, {required int allowance}) async {
    await _prefs.setInt(
      StorageKeys.subscriptionPeriodStartAt,
      start.millisecondsSinceEpoch,
    );
    await _prefs.setInt(StorageKeys.subscriptionPeriodSearchAllowance, allowance);
    await _prefs.setInt(StorageKeys.subscriptionPeriodSearchesUsed, 0);
  }

  /// Called from IAP when a subscription is purchased or restored.
  Future<void> activateSubscriptionFromPurchase({
    required String productId,
    required bool restored,
  }) async {
    final now = DateTime.now();
    final eligibleForIntroTrial =
        !hasStartedIntroTrial && !restored && productId == AppConstants.weeklyProductId;

    if (eligibleForIntroTrial) {
      await _prefs.setBool(StorageKeys.hasStartedIntroTrial, true);
      await _prefs.setString(StorageKeys.subscriptionPlan, 'trial');
      final trialEnds = now.add(SubscriptionConfig.introTrialDuration);
      await _prefs.setInt(
        StorageKeys.subscriptionExpiresAt,
        trialEnds.millisecondsSinceEpoch,
      );
      await setProEntitled(true);
      await _startSearchPeriod(
        now,
        allowance: SubscriptionConfig.introTrialSearchAllowance,
      );
      return;
    }

    final period = SubscriptionConfig.periodForProduct(productId);
    final allowance = SubscriptionConfig.searchAllowanceForProduct(
      productId,
      introTrial: false,
    );
    final plan = switch (productId) {
      AppConstants.monthlyProductId => 'monthly',
      AppConstants.yearlyProductId => 'yearly',
      _ => 'weekly',
    };

    final currentExpiry = subscriptionExpiresAt;
    final base = (currentExpiry != null && currentExpiry.isAfter(now))
        ? currentExpiry
        : now;
    await _prefs.setString(StorageKeys.subscriptionPlan, plan);
    await _prefs.setInt(
      StorageKeys.subscriptionExpiresAt,
      base.add(period).millisecondsSinceEpoch,
    );
    await setProEntitled(true);
    await _startSearchPeriod(now, allowance: allowance);
  }

  SubscriptionInfo buildSubscriptionInfo() {
    final active = hasActivePremiumAccess;
    final plan = subscriptionPlan;
    return SubscriptionInfo(
      isPro: active,
      productId: active ? _productIdForPlan(plan) : null,
      status: active ? plan : 'free',
      expiresAt: subscriptionExpiresAt,
      willRenew: active && plan != 'trial',
      trialActive: active && plan == 'trial',
    );
  }

  String? _productIdForPlan(String plan) {
    return switch (plan) {
      'monthly' => AppConstants.monthlyProductId,
      'yearly' => AppConstants.yearlyProductId,
      'trial' || 'weekly' => AppConstants.weeklyProductId,
      _ => null,
    };
  }

  UsageStats buildUsageStats() {
    _expireSubscriptionIfNeededSync();
    _maybeRollSubscriptionPeriod();

    if (hasActivePremiumAccess) {
      final limit = subscriptionPeriodSearchAllowance;
      final used = subscriptionPeriodSearchesUsed;
      final remaining = (limit - used).clamp(0, limit);
      final plan = subscriptionPlan;
      final tier = switch (plan) {
        'trial' => UsageTier.trial,
        'monthly' => UsageTier.monthly,
        'yearly' => UsageTier.yearly,
        _ => UsageTier.weekly,
      };
      final periodStart = subscriptionPeriodStartAt ?? DateTime.now();
      final periodEnds = switch (plan) {
        'trial' => subscriptionExpiresAt,
        'monthly' => periodStart.add(SubscriptionConfig.monthlyPeriod),
        'yearly' => periodStart.add(const Duration(days: 365)),
        _ => periodStart.add(const Duration(days: 7)),
      };
      return UsageStats(
        used: used,
        limit: limit,
        remaining: remaining,
        isPro: true,
        tier: tier,
        trialActive: plan == 'trial',
        periodEndsAt: periodEnds,
      );
    }

    final limit = AppConstants.freeSearchCredits;
    final used = searchCreditsUsed;
    final remaining = (limit - used).clamp(0, limit);
    return UsageStats(
      used: used,
      limit: limit,
      remaining: remaining,
      isPro: false,
      tier: UsageTier.free,
    );
  }

  Future<void> incrementSearchCreditsUsed() async {
    await _prefs.setInt(StorageKeys.lastSearchAtMs, DateTime.now().millisecondsSinceEpoch);
    if (hasActivePremiumAccess) {
      await _prefs.setInt(
        StorageKeys.subscriptionPeriodSearchesUsed,
        subscriptionPeriodSearchesUsed + 1,
      );
      return;
    }
    await _prefs.setInt(
      StorageKeys.searchCreditsUsed,
      searchCreditsUsed + 1,
    );
  }

  Duration? cooldownBeforeNextSearch() {
    final last = lastSearchAt;
    if (last == null) return null;
    final elapsed = DateTime.now().difference(last);
    final minGap = Duration(
      seconds: SubscriptionConfig.minSecondsBetweenSearches,
    );
    if (elapsed >= minGap) return null;
    return minGap - elapsed;
  }

  Future<void> clearAuthScopedData() async {
    await _prefs.remove(StorageKeys.localFavorites);
    await _prefs.remove(StorageKeys.localHistory);
    await _prefs.remove(StorageKeys.localSearchCache);
    await _prefs.remove(StorageKeys.recentSearches);
  }

  Future<void> refreshSubscriptionState() async {
    await _expireSubscriptionIfNeeded();
    await _ensureLegacyPremiumMetadata();
    _maybeRollSubscriptionPeriod();
  }
}
