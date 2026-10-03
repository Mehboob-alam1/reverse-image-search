import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ads/ads_controller.dart';

class AdsLifecycleHandler extends ConsumerStatefulWidget {
  const AdsLifecycleHandler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AdsLifecycleHandler> createState() => _AdsLifecycleHandlerState();
}

class _AdsLifecycleHandlerState extends ConsumerState<AdsLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(adsControllerProvider.notifier).onAppResume();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
