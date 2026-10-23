import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reverse_image_search/core/constants/app_constants.dart';
import 'package:reverse_image_search/core/constants/subscription_config.dart';
import 'package:reverse_image_search/core/storage/local_storage.dart';
import 'package:reverse_image_search/core/storage/subscription_vault.dart';
import 'package:reverse_image_search/models/user_models.dart';

Future<LocalStorage> _readyStorage() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return LocalStorage(prefs, SubscriptionVault.memory());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('free tier uses lifetime search cap', () async {
    final storage = await _readyStorage();
    final stats = storage.buildUsageStats();
    expect(stats.tier, UsageTier.free);
    expect(stats.remaining, AppConstants.freeSearchCredits);
  });

  test('weekly purchase grants period allowance', () async {
    final storage = await _readyStorage();
    await storage.activateSubscriptionFromPurchase(
      productId: AppConstants.weeklyProductId,
      restored: true,
    );
    final stats = storage.buildUsageStats();
    expect(stats.isPro, isTrue);
    expect(stats.limit, SubscriptionConfig.weeklySearchAllowance);
    expect(stats.remaining, SubscriptionConfig.weeklySearchAllowance);
  });

  test('monthly purchase grants 30-day allowance', () async {
    final storage = await _readyStorage();
    await storage.activateSubscriptionFromPurchase(
      productId: AppConstants.monthlyProductId,
      restored: false,
    );
    final stats = storage.buildUsageStats();
    expect(stats.tier, UsageTier.monthly);
    expect(stats.limit, SubscriptionConfig.monthlySearchAllowance);
    expect(stats.remaining, SubscriptionConfig.monthlySearchAllowance);
    expect(stats.trialActive, isFalse);
  });

  test('intro trial only once for new weekly buyers', () async {
    final storage = await _readyStorage();
    await storage.activateSubscriptionFromPurchase(
      productId: AppConstants.weeklyProductId,
      restored: false,
    );
    final trial = storage.buildUsageStats();
    expect(trial.trialActive, isTrue);
    expect(trial.limit, SubscriptionConfig.introTrialSearchAllowance);

    await storage.incrementSearchCreditsUsed();
    final after = storage.buildUsageStats();
    expect(after.used, 1);
    expect(after.remaining, SubscriptionConfig.introTrialSearchAllowance - 1);
  });
}
