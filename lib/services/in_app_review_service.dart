import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import '../core/constants/app_constants.dart';
import 'analytics_service.dart';
import 'url_service.dart';

final inAppReviewServiceProvider = Provider<InAppReviewService>((ref) {
  return InAppReviewService(analytics: ref.read(analyticsServiceProvider));
});

class InAppReviewService {
  InAppReviewService({required AnalyticsService analytics}) : _analytics = analytics;

  final AnalyticsService _analytics;
  final InAppReview _review = InAppReview.instance;

  /// Prefer native in-app review; fall back to Play Store / App Store listing.
  Future<void> requestReviewOrOpenStore() async {
    await _analytics.rateUsTapped();
    try {
      if (await _review.isAvailable()) {
        await _review.requestReview();
        return;
      }
    } on Object catch (e) {
      debugPrint('In-app review unavailable: $e');
    }
    await const UrlService().openStore(
      'https://play.google.com/store/apps/details?id=${AppConstants.packageName}',
    );
  }
}
