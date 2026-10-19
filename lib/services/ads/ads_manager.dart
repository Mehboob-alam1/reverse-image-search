import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show VoidCallback, kIsWeb;
import 'package:flutter/material.dart' show Color;
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_config.dart';
import 'ads_remote_config.dart';

typedef AdsVoidCallback = void Function();

class AdsManager {
  AdsManager();

  AdsRemoteSettings _settings = AdsRemoteSettings.defaults();
  bool _initialized = false;
  bool _splashFinished = false;

  InterstitialAd? _interstitial;
  AppOpenAd? _appOpen;
  NativeAd? _nativeAd;
  RewardedAd? _rewarded;
  bool _isLoadingInterstitial = false;
  bool _isLoadingAppOpen = false;
  bool _isLoadingNative = false;
  bool _isLoadingRewarded = false;
  bool _isShowingFullScreen = false;
  bool _appOpenShownThisSession = false;
  int _lastFullscreenAtMs = 0;
  int _interstitialRetry = 0;
  int _appOpenRetry = 0;
  int _nativeRetry = 0;
  int _rewardedRetry = 0;

  AdsRemoteSettings get settings => _settings;

  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  bool adsAllowed({required bool isPro}) {
    return isAndroid &&
        AdConfig.enableAdsOnAndroid &&
        _settings.adsEnabled &&
        !isPro;
  }

  Future<void> applyRemoteSettings(AdsRemoteSettings settings) async {
    _settings = settings;
    // Remote disable (or iOS / Pro path) must drop any preloaded creatives.
    if (!adsAllowed(isPro: false) || !settings.adsEnabled) {
      _disposeLoadedAds();
    }
  }

  void _disposeLoadedAds() {
    _interstitial?.dispose();
    _interstitial = null;
    _appOpen?.dispose();
    _appOpen = null;
    _nativeAd?.dispose();
    _nativeAd = null;
    _rewarded?.dispose();
    _rewarded = null;
  }

  Future<void> initializeMobileAds() async {
    if (!isAndroid || _initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  Future<void> preloadAll({required bool isPro}) async {
    if (!adsAllowed(isPro: isPro)) return;
    await initializeMobileAds();
    await Future.wait([
      _waitForInterstitial(isPro: isPro),
      _waitForAppOpen(isPro: isPro),
      _waitForNative(isPro: isPro),
      _waitForRewarded(isPro: isPro),
    ]);
  }

  Future<void> _waitForRewarded({required bool isPro}) async {
    if (!adsAllowed(isPro: isPro) || !_settings.rewardedEnabled) return;
    if (_rewarded != null) return;
    final done = Completer<void>();
    unawaited(_loadRewarded(isPro: isPro, onReady: () {
      if (!done.isCompleted) done.complete();
    }));
    try {
      await done.future.timeout(AdConfig.adLoadTimeout);
    } on Object {
      if (!done.isCompleted) done.complete();
    }
  }

  Future<void> _waitForInterstitial({required bool isPro}) async {
    if (!adsAllowed(isPro: isPro) || !_settings.interstitialEnabled) return;
    if (_interstitial != null) return;
    final done = Completer<void>();
    unawaited(_loadInterstitial(isPro: isPro, onReady: () {
      if (!done.isCompleted) done.complete();
    }));
    try {
      await done.future.timeout(AdConfig.adLoadTimeout);
    } on Object {
      if (!done.isCompleted) done.complete();
    }
  }

  Future<void> _waitForAppOpen({required bool isPro}) async {
    if (!adsAllowed(isPro: isPro) || !_settings.appOpenEnabled) return;
    if (_appOpen != null) return;
    final done = Completer<void>();
    unawaited(_loadAppOpen(isPro: isPro, onReady: () {
      if (!done.isCompleted) done.complete();
    }));
    try {
      await done.future.timeout(AdConfig.adLoadTimeout);
    } on Object {
      if (!done.isCompleted) done.complete();
    }
  }

  Future<void> _waitForNative({required bool isPro}) async {
    if (!adsAllowed(isPro: isPro) || !_settings.nativeBottomEnabled) return;
    if (_nativeAd != null) return;
    final done = Completer<void>();
    unawaited(_loadNative(isPro: isPro, onReady: () {
      if (!done.isCompleted) done.complete();
    }));
    try {
      await done.future.timeout(AdConfig.adLoadTimeout);
    } on Object {
      if (!done.isCompleted) done.complete();
    }
  }

  void markSplashFinished() => _splashFinished = true;

  NativeAd? takeNativeAd({required bool isPro}) {
    final ad = _nativeAd;
    _nativeAd = null;
    if (ad != null) {
      unawaited(_loadNative(isPro: isPro));
    }
    return ad;
  }

  NativeAd? peekNativeAd() => _nativeAd;

  /// Loads a native ad owned by the caller (e.g. one [NativeAdBar] instance).
  /// Must be [dispose]d when the widget is removed — never share one ad across widgets.
  Future<NativeAd?> createDedicatedNativeAd({
    required bool isPro,
    TemplateType templateType = TemplateType.small,
  }) async {
    if (!adsAllowed(isPro: isPro) || !_settings.nativeBottomEnabled) {
      return null;
    }
    await initializeMobileAds();
    final completer = Completer<NativeAd?>();
    late NativeAd ad;
    ad = NativeAd(
      adUnitId: _settings.nativeUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (loaded) {
          if (!completer.isCompleted) {
            completer.complete(loaded as NativeAd);
          }
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: templateType,
        mainBackgroundColor: const Color(0xFFF5F5F5),
        cornerRadius: 12,
      ),
    );
    try {
      await ad.load().timeout(AdConfig.adLoadTimeout, onTimeout: () {
        ad.dispose();
        throw TimeoutException('dedicated native ad');
      });
    } on Object {
      if (!completer.isCompleted) completer.complete(null);
    }
    try {
      return await completer.future.timeout(
        AdConfig.adLoadTimeout,
        onTimeout: () {
          ad.dispose();
          return null;
        },
      );
    } on Object {
      return null;
    }
  }

  Future<void> _loadNative({
    required bool isPro,
    VoidCallback? onReady,
  }) async {
    if (!adsAllowed(isPro: isPro) || !_settings.nativeBottomEnabled) {
      onReady?.call();
      return;
    }
    if (_nativeAd != null) {
      onReady?.call();
      return;
    }
    if (_isLoadingNative) return;
    _isLoadingNative = true;
    try {
      final ad = NativeAd(
        adUnitId: _settings.nativeUnitId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (loaded) {
            _nativeAd = loaded as NativeAd;
            _nativeRetry = 0;
            _isLoadingNative = false;
            onReady?.call();
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _isLoadingNative = false;
            onReady?.call();
            _scheduleNativeRetry(isPro: isPro);
          },
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.small,
          mainBackgroundColor: const Color(0xFFF5F5F5),
          cornerRadius: 12,
        ),
      );
      await ad.load().timeout(AdConfig.adLoadTimeout, onTimeout: () {
        ad.dispose();
        throw TimeoutException('native ad');
      });
    } on Object {
      _isLoadingNative = false;
      onReady?.call();
      _scheduleNativeRetry(isPro: isPro);
    }
  }

  void _scheduleNativeRetry({required bool isPro}) {
    if (_nativeRetry >= 3) return;
    _nativeRetry++;
    final delay = Duration(seconds: 4 * _nativeRetry);
    Future.delayed(delay, () => _loadNative(isPro: isPro));
  }

  Future<void> _loadInterstitial({
    required bool isPro,
    VoidCallback? onReady,
  }) async {
    if (!adsAllowed(isPro: isPro) || !_settings.interstitialEnabled) {
      onReady?.call();
      return;
    }
    if (_interstitial != null) {
      onReady?.call();
      return;
    }
    if (_isLoadingInterstitial) return;
    _isLoadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: _settings.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialRetry = 0;
          _isLoadingInterstitial = false;
          onReady?.call();
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
              _isShowingFullScreen = false;
              _loadInterstitial(isPro: isPro);
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitial = null;
              _isShowingFullScreen = false;
              _loadInterstitial(isPro: isPro);
            },
          );
        },
        onAdFailedToLoad: (_) {
          _isLoadingInterstitial = false;
          onReady?.call();
          _scheduleInterstitialRetry(isPro: isPro);
        },
      ),
    );
  }

  void _scheduleInterstitialRetry({required bool isPro}) {
    if (_interstitialRetry >= 3) return;
    _interstitialRetry++;
    Future.delayed(Duration(seconds: 5 * _interstitialRetry), () {
      _loadInterstitial(isPro: isPro);
    });
  }

  Future<void> _loadAppOpen({
    required bool isPro,
    VoidCallback? onReady,
  }) async {
    if (!adsAllowed(isPro: isPro) || !_settings.appOpenEnabled) {
      onReady?.call();
      return;
    }
    if (_appOpen != null) {
      onReady?.call();
      return;
    }
    if (_isLoadingAppOpen) return;
    _isLoadingAppOpen = true;
    await AppOpenAd.load(
      adUnitId: _settings.appOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpen = ad;
          _appOpenRetry = 0;
          _isLoadingAppOpen = false;
          onReady?.call();
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _appOpen = null;
              _isShowingFullScreen = false;
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _appOpen = null;
              _isShowingFullScreen = false;
            },
          );
        },
        onAdFailedToLoad: (_) {
          _isLoadingAppOpen = false;
          onReady?.call();
          _scheduleAppOpenRetry(isPro: isPro);
        },
      ),
    );
  }

  void _scheduleAppOpenRetry({required bool isPro}) {
    if (_appOpenRetry >= 3) return;
    _appOpenRetry++;
    Future.delayed(Duration(seconds: 6 * _appOpenRetry), () {
      _loadAppOpen(isPro: isPro);
    });
  }

  /// One app-open ad per app session, shown on the first screen after splash.
  Future<bool> showAppOpenOnce({
    required bool isPro,
  }) async {
    if (!adsAllowed(isPro: isPro) || !_settings.appOpenEnabled) return false;
    if (!_splashFinished) return false;
    if (_appOpenShownThisSession) return false;
    if (_isShowingFullScreen || _appOpen == null) return false;
    if (!_fullscreenGapOk()) return false;
    _appOpenShownThisSession = true;
    final ad = _appOpen!;
    _appOpen = null;
    _markFullscreenShown();
    ad.show();
    return true;
  }

  bool get hasPreloadedNative => _nativeAd != null;

  bool _fullscreenGapOk() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final gap = _settings.fullscreenMinGapSeconds * 1000;
    return now - _lastFullscreenAtMs >= gap;
  }

  void _markFullscreenShown() {
    _isShowingFullScreen = true;
    _lastFullscreenAtMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// After successful search: wait briefly for a loaded interstitial, respect
  /// interval + fullscreen gap, show if ready (never blocks navigation long).
  Future<bool> showInterstitialIfReady({
    required bool isPro,
    required int lastShownMs,
    required void Function(int shownAtMs) onShown,
  }) async {
    if (!adsAllowed(isPro: isPro) ||
        !_settings.interstitialEnabled ||
        !_settings.interstitialAfterSearch) {
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final minGap = _settings.interstitialIntervalSeconds * 1000;
    if (now - lastShownMs < minGap) return false;
    if (_isShowingFullScreen) return false;
    if (!_fullscreenGapOk()) return false;

    if (_interstitial == null) {
      unawaited(_loadInterstitial(isPro: isPro));
      final deadline = DateTime.now().add(
        Duration(milliseconds: _settings.interstitialLoadWaitMs),
      );
      while (_interstitial == null && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!adsAllowed(isPro: isPro) || _isShowingFullScreen) return false;
      }
    }

    final ad = _interstitial;
    if (ad == null) return false;
    _interstitial = null;
    final shownAt = DateTime.now().millisecondsSinceEpoch;
    _markFullscreenShown();
    onShown(shownAt);
    ad.show();
    return true;
  }

  Future<BannerAd?> createBannerAd({
    required bool isPro,
    int? widthDp,
  }) async {
    if (!adsAllowed(isPro: isPro) || !_settings.bannerEnabled) return null;
    await initializeMobileAds();
    final completer = Completer<BannerAd?>();
    AdSize size = AdSize.banner;
    if (widthDp != null && widthDp > 0) {
      final adaptive =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        widthDp,
      );
      if (adaptive != null) size = adaptive;
    }
    late BannerAd ad;
    ad = BannerAd(
      adUnitId: _settings.bannerUnitId,
      size: size,
      // AdMob collapsible banner (expand/collapse handled by the SDK, no custom bar).
      request: const AdRequest(extras: {'collapsible': 'bottom'}),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (!completer.isCompleted) completer.complete(loaded as BannerAd);
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    try {
      await ad.load().timeout(AdConfig.adLoadTimeout, onTimeout: () {
        ad.dispose();
        throw TimeoutException('banner ad');
      });
    } on Object {
      if (!completer.isCompleted) completer.complete(null);
    }
    try {
      return await completer.future.timeout(
        AdConfig.adLoadTimeout,
        onTimeout: () {
          ad.dispose();
          return null;
        },
      );
    } on Object {
      return null;
    }
  }

  Future<void> _loadRewarded({
    required bool isPro,
    VoidCallback? onReady,
  }) async {
    if (!adsAllowed(isPro: isPro) || !_settings.rewardedEnabled) {
      onReady?.call();
      return;
    }
    if (_rewarded != null) {
      onReady?.call();
      return;
    }
    if (_isLoadingRewarded) return;
    _isLoadingRewarded = true;
    await RewardedAd.load(
      adUnitId: _settings.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedRetry = 0;
          _isLoadingRewarded = false;
          onReady?.call();
        },
        onAdFailedToLoad: (_) {
          _isLoadingRewarded = false;
          onReady?.call();
          if (_rewardedRetry < 3) {
            _rewardedRetry++;
            Future.delayed(Duration(seconds: 5 * _rewardedRetry), () {
              _loadRewarded(isPro: isPro);
            });
          }
        },
      ),
    );
  }

  /// Shows a rewarded ad. Returns true only if the user earned the reward.
  Future<bool> showRewardedAd({required bool isPro}) async {
    if (!adsAllowed(isPro: isPro) || !_settings.rewardedEnabled) return false;
    if (_isShowingFullScreen) return false;
    if (_rewarded == null) {
      await _waitForRewarded(isPro: isPro);
    }
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;

    final done = Completer<bool>();
    var didEarn = false;
    _markFullscreenShown();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (dismissed) {
        dismissed.dispose();
        _isShowingFullScreen = false;
        _loadRewarded(isPro: isPro);
        if (!done.isCompleted) done.complete(didEarn);
      },
      onAdFailedToShowFullScreenContent: (failed, _) {
        failed.dispose();
        _isShowingFullScreen = false;
        _loadRewarded(isPro: isPro);
        if (!done.isCompleted) done.complete(false);
      },
    );
    ad.show(
      onUserEarnedReward: (_, __) {
        didEarn = true;
      },
    );
    return done.future;
  }

  void dispose() {
    _disposeLoadedAds();
  }
}
