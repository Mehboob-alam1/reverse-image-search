import 'package:flutter/material.dart';

import 'native_ad_bar.dart';

/// Standard scaffold with optional bottom native ad.
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
  /// Unique per screen so each route owns its own native ad instance.
  final String nativeAdSlotKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: body,
      bottomNavigationBar: NativeAdBar(key: ValueKey('native-$nativeAdSlotKey')),
    );
  }
}
