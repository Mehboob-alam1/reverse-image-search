import 'package:flutter/material.dart';

import 'collapsible_banner_ad.dart';

/// Standard scaffold with a collapsible bottom banner ad (not a fixed simple bar).
class AdBottomScaffold extends StatelessWidget {
  const AdBottomScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.drawer,
    this.floatingActionButton,
    this.nativeAdSlotKey = 'default',
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? drawer;
  final Widget? floatingActionButton;
  /// Kept for call-site compatibility; bottom slot is now a collapsible banner.
  final String nativeAdSlotKey;

  @override
  Widget build(BuildContext context) {
    // Column (not bottomNavigationBar) so AdMob's expanded collapsible overlay
    // can draw over content without being clipped by the nav-bar slot.
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          Expanded(child: body),
          CollapsibleBannerAd(
            key: ValueKey('banner-$nativeAdSlotKey'),
          ),
        ],
      ),
    );
  }
}
