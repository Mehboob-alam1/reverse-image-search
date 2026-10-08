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
  bool _isLoadingInterstitial = false;
  bool _isLoadingAppOpen = false;
  bool _isLoadingNative = false;
  bool _isShowingFullScreen = false;
  bool _appOpenShownThisSession = false;
  int _interstitialRetry = 0;
  int _appOpenRetry = 0;
  int _nativeRetry = 0;

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
    ]);
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
  Future<NativeAd?> createDedicatedNativeAd({required bool isPro}) async {
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
        templateType: TemplateType.small,
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
    _appOpenShownThisSession = true;
    final ad = _appOpen!;
    _appOpen = null;
    _isShowingFullScreen = true;
    ad.show();
    return true;
  }

  bool get hasPreloadedNative => _nativeAd != null;

  Future<bool> showInterstitialIfReady({
    required bool isPro,
    required int lastShownMs,
    required void Function(int shownAtMs) onShown,
  }) async {
    if (!adsAllowed(isPro: isPro) || !_settings.interstitialEnabled) {
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final minGap = _settings.interstitialIntervalSeconds * 1000;
    if (now - lastShownMs < minGap) return false;
    if (_isShowingFullScreen || _interstitial == null) return false;
    final ad = _interstitial!;
    _interstitial = null;
    _isShowingFullScreen = true;
    onShown(now);
    ad.show();
    return true;
  }

  void dispose() {
    _interstitial?.dispose();
    _appOpen?.dispose();
    _nativeAd?.dispose();
  }
}
