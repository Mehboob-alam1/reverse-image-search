import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

import 'analytics_service.dart';

final inAppUpdateServiceProvider = Provider<InAppUpdateService>((ref) {
  return InAppUpdateService(analytics: ref.read(analyticsServiceProvider));
});

/// Play Store in-app updates (Android only). No-op on iOS / web / debug failures.
class InAppUpdateService {
  InAppUpdateService({required AnalyticsService analytics}) : _analytics = analytics;

  final AnalyticsService _analytics;
  bool _checked = false;

  Future<void> checkAndUpdate({bool preferImmediate = false}) async {
    if (_checked || kIsWeb || !Platform.isAndroid) return;
    _checked = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }
      await _analytics.inAppUpdateAvailable();

      if (preferImmediate &&
          info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }
      if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
        }
        return;
      }
      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } on Object catch (e) {
      debugPrint('In-app update skipped: $e');
    }
  }
}
