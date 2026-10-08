import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/storage/local_storage.dart';
import '../models/favorite_item.dart';
import '../models/home_search_mode.dart';
import '../models/search_history_item.dart';
import '../models/search_response.dart';
import '../models/search_result.dart';
import '../models/search_type.dart';
import '../models/user_models.dart';
import '../services/analytics_service.dart';
import '../services/search_debug_log.dart';
import '../services/feature_access_service.dart';
import '../services/search_repository.dart';
import '../services/user_repositories.dart';

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => Locale(ref.read(localStorageProvider).languageCode);

  Future<void> setLanguage(String code) async {
    await ref.read(localStorageProvider).setLanguage(code);
    state = Locale(code);
    await ref.read(analyticsServiceProvider).languageSelected(code);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _parse(ref.read(localStorageProvider).themeMode);

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref.read(localStorageProvider).setThemeMode(mode.name);
  }

  ThemeMode _parse(String value) {
    return ThemeMode.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}

class AuthState {
  const AuthState({
    this.profile,
    this.usage,
    this.subscription,
    this.ready = false,
  });

  final UserProfile? profile;
  final UsageStats? usage;
  final SubscriptionInfo? subscription;
  final bool ready;

  bool get isPro =>
      subscription?.isPro == true || profile?.isPro == true || usage?.isPro == true;

  AuthState copyWith({
    UserProfile? profile,
    UsageStats? usage,
    SubscriptionInfo? subscription,
    bool? ready,
  }) {
    return AuthState(
      profile: profile ?? this.profile,
      usage: usage ?? this.usage,
      subscription: subscription ?? this.subscription,
      ready: ready ?? this.ready,
    );
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(initialize);
    return const AuthState();
  }

  Future<void> initialize() async {
    final storage = ref.read(localStorageProvider);
    await storage.refreshSubscriptionState();
    try {
      final repo = ref.read(userRepositoryProvider);
      final usage = await repo.usage();
      final subscription = await repo.subscription();
      state = AuthState(
        profile: UserProfile(
          uid: storage.guestId(),
          isAnonymous: true,
          isPro: subscription.isPro,
        ),
        usage: usage,
        subscription: subscription,
        ready: true,
      );
    } catch (_) {
      state = AuthState(
        profile: UserProfile(uid: storage.guestId(), isAnonymous: true),
        usage: storage.buildUsageStats(),
        subscription: const SubscriptionInfo(isPro: false),
        ready: true,
      );
    }
  }

  Future<void> clearLocalData() async {
    await ref.read(localStorageProvider).clearAuthScopedData();
    await initialize();
  }

  Future<void> refreshUsage() => initialize();

  Future<void> consumeSearchCredit() async {
    await ref.read(localStorageProvider).incrementSearchCreditsUsed();
    await refreshUsage();
  }
}

class SearchSession {
  const SearchSession({
    this.pending,
    this.response,
    this.loading = false,
    this.error,
    this.siteFilter = const [],
    this.homeSearchMode = HomeSearchMode.general,
  });

  final PendingImage? pending;
  final SearchResponse? response;
  final bool loading;
  final AppException? error;
  final List<String> siteFilter;
  final HomeSearchMode homeSearchMode;

  SearchSession copyWith({
    PendingImage? pending,
    SearchResponse? response,
    bool? loading,
    AppException? error,
    List<String>? siteFilter,
    HomeSearchMode? homeSearchMode,
    bool clearError = false,
    bool clearResponse = false,
  }) {
    return SearchSession(
      pending: pending ?? this.pending,
      response: clearResponse ? null : response ?? this.response,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      siteFilter: siteFilter ?? this.siteFilter,
      homeSearchMode: homeSearchMode ?? this.homeSearchMode,
    );
  }
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchSession>(SearchController.new);

class SearchController extends Notifier<SearchSession> {
  bool _searchKickScheduled = false;

  @override
  SearchSession build() => const SearchSession();

  void beginSearch({
    required PendingImage image,
    required HomeSearchMode mode,
    List<String>? siteFilter,
  }) {
    _searchKickScheduled = false;
    final log = ref.read(searchDebugLogProvider.notifier)..clear();
    log.log('─── New search (${mode.name}) ───');
    if (image.hasLocal) {
      log.log('Local image on device: ${image.localPath}');
      log.log(
        'Next: Apify base64 (≤4 MB) or temporary public URL for Google Lens',
      );
    } else {
      log.log('Image URL (no upload): ${image.remoteUrl}');
    }
    state = SearchSession(
      pending: image,
      homeSearchMode: mode,
      siteFilter: siteFilter ?? mode.siteFilter,
    );
  }

  /// Starts [search] on the next event-loop turn. Safe to call from home + searching screen.
  void scheduleSearch() {
    if (_searchKickScheduled) return;
    _searchKickScheduled = true;
    Future.microtask(() async {
      ref.read(searchDebugLogProvider.notifier).log('scheduleSearch: kickoff');
      try {
        await search();
      } on Object {
        // [search] stores [AppException] on session; navigation listens for completion.
      }
    });
  }

  void applyResponse(SearchResponse response) {
    state = state.copyWith(response: response, loading: false, clearError: true);
  }

  Future<SearchResponse> search() async {
    ref.read(searchDebugLogProvider.notifier).log('SearchController.search() started');
    final pending = state.pending;
    if (pending == null) {
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'Please select an image first.',
      );
    }

    final type = state.homeSearchMode.searchType;

    final auth = ref.read(authControllerProvider);
    final usage = auth.usage;
    if (!ref.read(featureAccessProvider).canSearch(usage)) {
      final tier = usage?.tier;
      final message = tier == UsageTier.free
          ? 'Free searches used. Start a free trial or subscribe for more.'
          : 'Search allowance used for this period. Tokens reset when your plan renews.';
      throw AppException(
        code: AppErrorCode.rateLimit,
        message: message,
      );
    }

    final storage = ref.read(localStorageProvider);
    final cooldown = storage.cooldownBeforeNextSearch();
    if (cooldown != null) {
      throw AppException(
        code: AppErrorCode.rateLimit,
        message:
            'Please wait ${cooldown.inSeconds}s before the next search (API fair use).',
      );
    }

    state = state.copyWith(loading: true, clearError: true, clearResponse: true);
    ref.read(searchDebugLogProvider.notifier).log(
          'Search pipeline started (type=${type.apiValue})',
        );
    await ref.read(analyticsServiceProvider).searchStarted(type.apiValue);
    try {
      final repo = ref.read(searchRepositoryProvider);
      final result = pending.hasLocal
          ? await repo.searchImage(file: File(pending.localPath!), searchType: type)
          : await repo.searchByUrl(url: pending.remoteUrl!, searchType: type);
      ref.read(searchDebugLogProvider.notifier).log(
            'Results ready (${result.results.all.length} matches; mode=${state.homeSearchMode.name})',
          );
      state = state.copyWith(loading: false, response: result);
      await ref.read(authControllerProvider.notifier).consumeSearchCredit();
      await ref.read(analyticsServiceProvider).searchCompleted(
            type.apiValue,
            result.results.all.length,
          );
      if (ref.read(localStorageProvider).saveHistoryAutomatically) {
        await ref.read(historyControllerProvider.notifier).addFromSearch(result);
      }
      return result;
    } on AppException catch (error) {
      ref.read(searchDebugLogProvider.notifier).log('Search error: ${error.message}');
      state = state.copyWith(loading: false, error: error);
      await ref.read(analyticsServiceProvider).searchFailed(error.code.name);
      rethrow;
    } catch (error) {
      ref.read(searchDebugLogProvider.notifier).log('Unexpected error: $error');
      final wrapped = AppException(
        code: AppErrorCode.unavailable,
        message: error.toString(),
      );
      state = state.copyWith(loading: false, error: wrapped);
      await ref.read(analyticsServiceProvider).searchFailed(wrapped.code.name);
      throw wrapped;
    }
  }
}

final historyControllerProvider =
    AsyncNotifierProvider<HistoryController, List<SearchHistoryItem>>(
  HistoryController.new,
);

class HistoryController extends AsyncNotifier<List<SearchHistoryItem>> {
  @override
  Future<List<SearchHistoryItem>> build() {
    return ref.read(historyRepositoryProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(ref.read(historyRepositoryProvider).list);
  }

  Future<void> addFromSearch(SearchResponse response) async {
    final item = SearchHistoryItem(
      id: response.searchId,
      createdAt: DateTime.now(),
      searchType: response.searchType,
      thumbnail: response.queryImage,
      imageUrl: response.queryImage,
      resultCount: response.results.all.length,
    );
    await ref.read(historyRepositoryProvider).saveLocal(item);
    await ref.read(historyRepositoryProvider).saveResponse(response);
    await refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(historyRepositoryProvider).delete(id);
    await refresh();
  }

  Future<void> clear() async {
    await ref.read(historyRepositoryProvider).clear();
    await refresh();
  }
}

final favoritesControllerProvider =
    AsyncNotifierProvider<FavoritesController, List<FavoriteItem>>(
  FavoritesController.new,
);

class FavoritesController extends AsyncNotifier<List<FavoriteItem>> {
  @override
  Future<List<FavoriteItem>> build() {
    return ref.read(favoritesRepositoryProvider).list();
  }

  bool isFavoriteResult(SearchResult result) {
    final key = result.favoriteId;
    return state.value?.any(
          (item) => item.id == key || item.result.favoriteId == key,
        ) ??
        ref.read(favoritesRepositoryProvider).isFavoriteResult(result);
  }

  Future<void> toggle(SearchResult result) async {
    if (isFavoriteResult(result)) {
      await ref.read(favoritesRepositoryProvider).removeResult(result);
    } else {
      await ref.read(favoritesRepositoryProvider).add(result);
      await ref.read(analyticsServiceProvider).resultFavorited();
    }
    state = await AsyncValue.guard(ref.read(favoritesRepositoryProvider).list);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, LocalStorage>(SettingsController.new);

class SettingsController extends Notifier<LocalStorage> {
  @override
  LocalStorage build() => ref.read(localStorageProvider);
}

class IapState {
  const IapState({
    this.products = const [],
    this.available = false,
    this.loading = false,
    this.error,
  });

  final List<ProductDetails> products;
  final bool available;
  final bool loading;
  final String? error;
}

final iapControllerProvider =
    NotifierProvider<IapController, IapState>(IapController.new);

class IapController extends Notifier<IapState> {
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  @override
  IapState build() {
    _purchaseSub?.cancel();
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (_) {},
    );
    ref.onDispose(() => _purchaseSub?.cancel());
    Future.microtask(load);
    return const IapState(loading: true);
  }

  Future<void> load() async {
    final store = InAppPurchase.instance;
    final available = await store.isAvailable();
    if (!available) {
      state = const IapState(available: false, loading: false);
      return;
    }
    final response = await store.queryProductDetails({
      AppConstants.weeklyProductId,
      AppConstants.monthlyProductId,
      AppConstants.yearlyProductId,
    });
    final products = List<ProductDetails>.from(response.productDetails);
    products.sort((a, b) {
      int rank(String id) {
        if (id == AppConstants.weeklyProductId) return 0;
        if (id == AppConstants.monthlyProductId) return 1;
        return 2;
      }

      return rank(a.id).compareTo(rank(b.id));
    });
    state = IapState(
      available: true,
      loading: false,
      products: products,
    );
  }

  Future<void> buy(ProductDetails product) async {
    await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restore() async {
    await InAppPurchase.instance.restorePurchases();
  }

  Future<void> grantProAfterPurchase({String? productId}) async {
    await ref.read(localStorageProvider).activateSubscriptionFromPurchase(
          productId: productId ?? AppConstants.weeklyProductId,
          restored: false,
        );
    await ref.read(authControllerProvider.notifier).refreshUsage();
    await ref.read(analyticsServiceProvider).subscriptionStarted();
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          break;
        case PurchaseStatus.canceled:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await ref.read(localStorageProvider).activateSubscriptionFromPurchase(
                productId: purchase.productID,
                restored: purchase.status == PurchaseStatus.restored,
              );
          await ref.read(authControllerProvider.notifier).refreshUsage();
          if (purchase.status == PurchaseStatus.restored) {
            await ref.read(analyticsServiceProvider).subscriptionRestored();
          } else {
            await ref.read(analyticsServiceProvider).subscriptionStarted();
          }
          break;
      }
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }
}
