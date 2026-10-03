import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ads/ads_controller.dart';

/// Compact native ad strip for bottom of main screens (Android only).
class NativeAdBar extends ConsumerStatefulWidget {
  const NativeAdBar({super.key});

  @override
  ConsumerState<NativeAdBar> createState() => _NativeAdBarState();
}

class _NativeAdBarState extends ConsumerState<NativeAdBar> {
  NativeAd? _ad;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adsControllerProvider.notifier).attachNativeIfNeeded();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = ref.watch(adsControllerProvider);
    if (!ads.showNativeBottom || ads.nativeAd == null) {
      return const SizedBox.shrink();
    }

    if (_ad != ads.nativeAd) {
      _ad?.dispose();
      _ad = ads.nativeAd;
    }

    final ad = _ad!;
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          width: double.infinity,
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
