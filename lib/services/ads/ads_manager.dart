import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
    unawaited(_loadInterstitial(isPro: isPro));
    unawaited(_loadAppOpen(isPro: isPro));
    unawaited(_loadNative(isPro: isPro));
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

  Future<void> _loadNative({required bool isPro}) async {
    if (!adsAllowed(isPro: isPro) || !_settings.nativeBottomEnabled) return;
    if (_isLoadingNative || _nativeAd != null) return;
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
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _isLoadingNative = false;
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
      _scheduleNativeRetry(isPro: isPro);
    }
  }

  void _scheduleNativeRetry({required bool isPro}) {
    if (_nativeRetry >= 3) return;
    _nativeRetry++;
    final delay = Duration(seconds: 4 * _nativeRetry);
    Future.delayed(delay, () => _loadNative(isPro: isPro));
  }

  Future<void> _loadInterstitial({required bool isPro}) async {
    if (!adsAllowed(isPro: isPro) || !_settings.interstitialEnabled) return;
    if (_isLoadingInterstitial || _interstitial != null) return;
    _isLoadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: _settings.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialRetry = 0;
          _isLoadingInterstitial = false;
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

  Future<void> _loadAppOpen({required bool isPro}) async {
    if (!adsAllowed(isPro: isPro) || !_settings.appOpenEnabled) return;
    if (_isLoadingAppOpen || _appOpen != null) return;
    _isLoadingAppOpen = true;
    await AppOpenAd.load(
      adUnitId: _settings.appOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpen = ad;
          _appOpenRetry = 0;
          _isLoadingAppOpen = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _appOpen = null;
              _isShowingFullScreen = false;
              _loadAppOpen(isPro: isPro);
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _appOpen = null;
              _isShowingFullScreen = false;
              _loadAppOpen(isPro: isPro);
            },
          );
        },
        onAdFailedToLoad: (_) {
          _isLoadingAppOpen = false;
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

  Future<bool> showAppOpenIfReady({
    required bool isPro,
    required int lastInterstitialMs,
  }) async {
    if (!adsAllowed(isPro: isPro) || !_settings.appOpenEnabled) return false;
    if (!_splashFinished) return false;
    if (_isShowingFullScreen || _appOpen == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastInterstitialMs < 8000) return false;
    final ad = _appOpen!;
    _appOpen = null;
    _isShowingFullScreen = true;
    ad.show();
    return true;
  }

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
