import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ads/ads_controller.dart';

/// Shows the single session app-open ad on the first screen after splash.
void scheduleDeferredAppOpen(WidgetRef ref) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(adsControllerProvider.notifier).showDeferredAppOpenIfAny();
  });
}
