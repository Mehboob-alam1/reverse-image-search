import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/search_type.dart';
import '../models/user_models.dart';

final featureAccessProvider = Provider<FeatureAccessService>((ref) {
  return const FeatureAccessService();
});

class FeatureAccessService {
  const FeatureAccessService();

  bool canAccess(
    PremiumFeature feature, {
    required bool isPro,
  }) {
    if (isPro) return true;
    switch (feature) {
      case PremiumFeature.adFree:
      case PremiumFeature.unlimitedSearch:
      case PremiumFeature.advancedFilters:
        return false;
      case PremiumFeature.exactMatches:
      case PremiumFeature.productSearch:
      case PremiumFeature.favorites:
        return true;
    }
  }

  bool canSearchType(SearchType type, {required bool isPro}) {
    if (isPro) return true;
    return type != SearchType.exactMatches || true;
  }

  bool canSearch(UsageStats? usage) {
    if (usage == null) return true;
    return usage.remaining > 0;
  }
}
