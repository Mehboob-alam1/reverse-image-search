import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firebase/firebase_bootstrap.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

class AnalyticsService {
  FirebaseAnalytics? get _fa =>
      FirebaseBootstrap.ready ? FirebaseAnalytics.instance : null;

  Future<void> log(String name, [Map<String, Object>? params]) async {
    final analytics = _fa;
    if (analytics == null) {
      if (kDebugMode) debugPrint('analytics(local): $name $params');
      return;
    }
    try {
      await analytics.logEvent(name: name, parameters: params);
    } on Object catch (e) {
      debugPrint('analytics failed ($name): $e');
    }
  }

  Future<void> appOpened() => log('app_opened');
  Future<void> languageSelected(String code) =>
      log('language_selected', {'language': code});
  Future<void> onboardingCompleted() => log('onboarding_completed');
  Future<void> galleryOpened() => log('gallery_opened');
  Future<void> cameraOpened() => log('camera_opened');
  Future<void> imageSelected() => log('image_selected');
  Future<void> imageCaptured() => log('image_captured');
  Future<void> imageEdited() => log('image_edited');
  Future<void> searchStarted(String type) =>
      log('search_started', {'search_type': type});
  Future<void> searchCompleted(String type, int count) =>
      log('search_completed', {'search_type': type, 'result_count': count});
  Future<void> searchFailed(String reason) =>
      log('search_failed', {'reason': reason});
  Future<void> resultOpened() => log('result_opened');
  Future<void> resultShared() => log('result_shared');
  Future<void> resultFavorited() => log('result_favorited');
  Future<void> historyOpened() => log('history_opened');
  Future<void> subscriptionViewed() => log('subscription_viewed');
  Future<void> subscriptionStarted() => log('subscription_started');
  Future<void> subscriptionRestored() => log('subscription_restored');
  Future<void> rateUsTapped() => log('rate_us_tapped');
  Future<void> inAppUpdateAvailable() => log('in_app_update_available');
  Future<void> fcmTokenRefreshed() => log('fcm_token_refreshed');
}
