import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/controllers.dart';
import '../../services/ads/ads_controller.dart';

/// Bottom-anchored AdMob collapsible banner.
///
/// Starts as a large overlay with an SDK collapse control, then shrinks to the
/// requested adaptive banner size. No custom Sponsored bar.
class CollapsibleBannerAd extends ConsumerStatefulWidget {
  const CollapsibleBannerAd({super.key});

  @override
  ConsumerState<CollapsibleBannerAd> createState() => _CollapsibleBannerAdState();
}

class _CollapsibleBannerAdState extends ConsumerState<CollapsibleBannerAd> {
  BannerAd? _ad;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted || _loading || _ad != null) return;
    _loading = true;
    final isPro = ref.read(authControllerProvider).isPro;
    final manager = ref.read(adsManagerProvider);
    if (!manager.adsAllowed(isPro: isPro) || !manager.settings.bannerEnabled) {
      _loading = false;
      return;
    }

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) {
      _loading = false;
      return;
    }

    final completer = Completer<BannerAd?>();
    late final BannerAd banner;
    banner = BannerAd(
      adUnitId: manager.settings.bannerUnitId,
      size: size,
      request: const AdRequest(extras: {'collapsible': 'bottom'}),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) completer.complete(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );

    try {
      await banner.load();
    } catch (_) {
      banner.dispose();
      if (!completer.isCompleted) completer.complete(null);
    }

    final loaded = await completer.future;
    if (!mounted) {
      loaded?.dispose();
      _loading = false;
      return;
    }
    setState(() {
      _ad = loaded;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();

    // Keep the Flutter slot at collapsed adaptive size; AdMob draws the
    // expanded overlay on top of content when the creative is collapsible.
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        ),
      ),
    );
  }
}
