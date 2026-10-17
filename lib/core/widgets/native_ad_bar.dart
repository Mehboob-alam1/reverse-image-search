import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/controllers.dart';
import '../../services/ads/ads_controller.dart';

/// One bottom native ad slot — owns its [NativeAd] and disposes on unmount.
class NativeAdBar extends ConsumerStatefulWidget {
  const NativeAdBar({super.key});

  @override
  ConsumerState<NativeAdBar> createState() => _NativeAdBarState();
}

class _NativeAdBarState extends ConsumerState<NativeAdBar> {
  NativeAd? _ad;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _acquireAd());
  }

  Future<void> _acquireAd() async {
    if (!mounted || _loading || _ad != null) return;
    _loading = true;

    final isPro = ref.read(authControllerProvider).isPro;
    final manager = ref.read(adsManagerProvider);
    if (!manager.adsAllowed(isPro: isPro) ||
        !manager.settings.nativeBottomEnabled) {
      _loading = false;
      return;
    }

    NativeAd? ad = manager.takeNativeAd(isPro: isPro);
    ad ??= await manager.createDedicatedNativeAd(isPro: isPro);

    if (!mounted) {
      ad?.dispose();
      return;
    }
    setState(() {
      _ad = ad;
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

    // No padding/clip around AdWidget — assets must stay inside NativeAdView.
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: AdWidget(ad: ad),
      ),
    );
  }
}
