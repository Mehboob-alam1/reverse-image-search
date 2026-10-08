/// Monetization aligned with SerpApi Starter (~1,000 searches / month @ \$25).
///
/// Competitor apps (Lens, Reverse Image Search Lens, etc.) typically charge
/// \$2.99–\$6.99/week with a 3-day free trial and market “Pro” access; many
/// do not pay per-search API fees. With SerpApi at ~\$0.025/search, caps keep
/// margins healthy as the user base grows.
class SubscriptionConfig {
  SubscriptionConfig._();

  /// One-time searches before subscribing (all search modes).
  static const int freeLifetimeSearches = 5;

  /// Introductory trial length (configure matching free trial in Play Console /
  /// App Store Connect). Billing after trial is handled by the store.
  static const Duration introTrialDuration = Duration(days: 3);

  /// Searches included during the intro trial window.
  static const int introTrialSearchAllowance = 12;

  /// Searches per paid weekly period while subscription is active.
  static const int weeklySearchAllowance = 40;

  /// Optional monthly plan (better value for heavy users).
  static const int monthlySearchAllowance = 120;
  static const Duration monthlyPeriod = Duration(days: 30);

  /// Suggested store price points (USD) — set actual prices in the consoles.
  static const String suggestedWeeklyPriceLabel = '\$4.99/week';
  static const String suggestedMonthlyPriceLabel = '\$9.99/month';

  /// SerpApi Starter throughput guard (~200/hour). Client-side spacing only.
  static const int minSecondsBetweenSearches = 18;

  static const String weeklyProductId = 'reverse_image_search_pro_weekly';
  static const String monthlyProductId = 'reverse_image_search_pro_monthly';
  static const String yearlyProductId = 'reverse_image_search_pro_yearly';

  static Duration periodForProduct(String productId) {
    if (productId == weeklyProductId) {
      return const Duration(days: 7);
    }
    if (productId == monthlyProductId) {
      return monthlyPeriod;
    }
    if (productId == yearlyProductId) {
      return const Duration(days: 365);
    }
    return const Duration(days: 7);
  }

  static int searchAllowanceForProduct(String productId, {required bool introTrial}) {
    if (introTrial) return introTrialSearchAllowance;
    if (productId == weeklyProductId) return weeklySearchAllowance;
    if (productId == monthlyProductId) return monthlySearchAllowance;
    if (productId == yearlyProductId) return 52 * weeklySearchAllowance;
    return weeklySearchAllowance;
  }
}
