import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/controllers.dart';
import '../../services/ads/ads_controller.dart';

/// In-feed native ad for the results list.
///
/// Occupies layout space only after a native ad has loaded.
/// Uses [TemplateType.small] (recommended for lists) and does not clip the
/// [AdWidget] — clipping / undersized boxes trigger AdMob's
/// "advertiser assets outside native ad view" validator.
class InlineNativeAd extends ConsumerStatefulWidget {
  const InlineNativeAd({super.key, this.slotId = 'inline'});

  final String slotId;

  @override
  ConsumerState<InlineNativeAd> createState() => _InlineNativeAdState();
}

class _InlineNativeAdState extends ConsumerState<InlineNativeAd> {
  NativeAd? _ad;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final isPro = ref.read(authControllerProvider).isPro;
    final manager = ref.read(adsManagerProvider);
    if (!manager.adsAllowed(isPro: isPro) ||
        !manager.settings.nativeBottomEnabled) {
      return;
    }
    final ad = await manager.createDedicatedNativeAd(
      isPro: isPro,
      templateType: TemplateType.small,
    );
    if (!mounted) {
      ad?.dispose();
      return;
    }
    if (ad == null) return;
    setState(() => _ad = ad);
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();

    // Google recommended bounds for TemplateType.small — no Clip / no extra
    // Flutter chrome around AdWidget (keeps assets inside NativeAdView).
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth.floorToDouble()
              : 320.0;
          return SizedBox(
            width: width,
            height: 120,
            child: AdWidget(ad: ad),
          );
        },
      ),
    );
  }
}
