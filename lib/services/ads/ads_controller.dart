import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/storage/local_storage.dart';
import '../../core/constants/storage_keys.dart';
import '../../features/controllers.dart';
import 'ads_manager.dart';
import 'ads_remote_config.dart';

class AdsUiState {
  const AdsUiState({
    this.ready = false,
    this.showNativeBottom = false,
    this.bootstrapMessage = '',
    this.nativeAd,
  });

  final bool ready;
  final bool showNativeBottom;
  final String bootstrapMessage;
  final NativeAd? nativeAd;

  AdsUiState copyWith({
    bool? ready,
    bool? showNativeBottom,
    String? bootstrapMessage,
    NativeAd? nativeAd,
    bool clearNative = false,
  }) {
    return AdsUiState(
      ready: ready ?? this.ready,
      showNativeBottom: showNativeBottom ?? this.showNativeBottom,
      bootstrapMessage: bootstrapMessage ?? this.bootstrapMessage,
      nativeAd: clearNative ? null : nativeAd ?? this.nativeAd,
    );
  }
}

final adsManagerProvider = Provider<AdsManager>((ref) {
  final manager = AdsManager();
  ref.onDispose(manager.dispose);
  return manager;
});

final adsControllerProvider = NotifierProvider<AdsController, AdsUiState>(
  AdsController.new,
);

class AdsController extends Notifier<AdsUiState> {
  AdsManager get _manager => ref.read(adsManagerProvider);

  bool get _isPro => ref.read(authControllerProvider).isPro;

  @override
  AdsUiState build() => const AdsUiState();

  Future<void> bootstrapForSplash() async {
    state = state.copyWith(bootstrapMessage: 'Loading…');
    final settings = await ref.read(adsRemoteSettingsProvider.future);
    await _manager.applyRemoteSettings(settings);

    if (!_manager.adsAllowed(isPro: _isPro)) {
      state = state.copyWith(ready: true, bootstrapMessage: '');
      _manager.markSplashFinished();
      return;
    }

    state = state.copyWith(bootstrapMessage: 'Preparing experience…');
    await _manager.preloadAll(isPro: _isPro);
    state = state.copyWith(
      ready: true,
      showNativeBottom:
          settings.nativeBottomEnabled && _manager.adsAllowed(isPro: _isPro),
      bootstrapMessage: '',
    );
  }

  Future<void> completeSplashAndShowAppOpen() async {
    _manager.markSplashFinished();
    final lastInterstitial = ref.read(localStorageProvider).prefs.getInt(
          StorageKeys.adsLastInterstitialAt,
        ) ??
        0;
    await _manager.showAppOpenIfReady(
      isPro: _isPro,
      lastInterstitialMs: lastInterstitial,
    );
    _refreshNativeSlot();
  }

  Future<bool> showInterstitialAfterSearch() async {
    final prefs = ref.read(localStorageProvider).prefs;
    final last = prefs.getInt(StorageKeys.adsLastInterstitialAt) ?? 0;
    var shown = false;
    shown = await _manager.showInterstitialIfReady(
      isPro: _isPro,
      lastShownMs: last,
      onShown: (ms) => prefs.setInt(StorageKeys.adsLastInterstitialAt, ms),
    );
    return shown;
  }

  void onAppResume() {
    if (!state.ready) return;
    final lastInterstitial = ref.read(localStorageProvider).prefs.getInt(
          StorageKeys.adsLastInterstitialAt,
        ) ??
        0;
    unawaited(
      _manager.showAppOpenIfReady(
        isPro: _isPro,
        lastInterstitialMs: lastInterstitial,
      ),
    );
  }

  void _refreshNativeSlot() {
    if (!_manager.adsAllowed(isPro: _isPro)) {
      state = state.copyWith(showNativeBottom: false, clearNative: true);
      return;
    }
    final ad = _manager.takeNativeAd(isPro: _isPro) ?? _manager.peekNativeAd();
    state = state.copyWith(
      showNativeBottom: _manager.settings.nativeBottomEnabled && ad != null,
      nativeAd: ad,
    );
  }

  void attachNativeIfNeeded() {
    if (state.nativeAd != null) return;
    _refreshNativeSlot();
  }
}
