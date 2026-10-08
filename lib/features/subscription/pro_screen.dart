import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../app/deferred_app_open.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/subscription_config.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_models.dart';
import '../../services/analytics_service.dart';
import '../controllers.dart';
import 'subscription_tier_table.dart';

class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  PaywallPlan _selectedPlan = PaywallPlan.weeklyTrial;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsServiceProvider).subscriptionViewed();
    if (!widget.fromSettings) {
      scheduleDeferredAppOpen(ref);
    }
  }

  Future<void> _continueFree() async {
    final storage = ref.read(localStorageProvider);
    await storage.markProSeen();
    await storage.markOnboardingComplete();
    await storage.markPermissionsComplete();
    if (!mounted) return;
    if (widget.fromSettings) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  ProductDetails? _product(IapState iap, String productId) {
    for (final p in iap.products) {
      if (p.id == productId) return p;
    }
    return null;
  }

  String _weeklyPrice(IapState iap) =>
      _product(iap, AppConstants.weeklyProductId)?.price ??
      SubscriptionConfig.suggestedWeeklyPriceLabel;

  String _monthlyPrice(IapState iap) =>
      _product(iap, AppConstants.monthlyProductId)?.price ??
      SubscriptionConfig.suggestedMonthlyPriceLabel;

  Future<void> _subscribe(IapState iap) async {
    final productId = _selectedPlan == PaywallPlan.monthly
        ? AppConstants.monthlyProductId
        : AppConstants.weeklyProductId;
    final product = _product(iap, productId);
    if (product != null) {
      await ref.read(iapControllerProvider.notifier).buy(product);
      return;
    }
    await ref.read(iapControllerProvider.notifier).grantProAfterPurchase(
          productId: productId,
        );
    if (!mounted) return;
    _continueFree();
  }

  String _statusSubtitle(AuthState auth, UsageStats? usage) {
    final freeLimit = SubscriptionConfig.freeLifetimeSearches;
    final used = usage?.tier == UsageTier.free ? (usage?.used ?? 0) : 0;

    if (auth.isPro && usage != null) {
      if (usage.trialActive) {
        return 'Trial: ${usage.remaining}/${usage.limit} searches left (3-day window). '
            'Then weekly billing at ${_weeklyPrice(ref.read(iapControllerProvider))} '
            'with ${SubscriptionConfig.weeklySearchAllowance} searches per week.';
      }
      if (usage.tier == UsageTier.monthly) {
        return 'Monthly plan: ${usage.remaining}/${usage.limit} searches left this 30-day period. '
            'Full results and no ads.';
      }
      return 'Weekly plan: ${usage.remaining}/${usage.limit} searches left this week. '
          'Full results and no ads.';
    }

    return 'Free tier: $used of $freeLimit lifetime searches used. '
        'Pick weekly (trial + ${SubscriptionConfig.weeklySearchAllowance}/week) or '
        'monthly (${SubscriptionConfig.monthlySearchAllowance} searches / 30 days).';
  }

  String _primaryCtaLabel(IapState iap, bool isPro) {
    if (isPro) return AppLocalizations.of(context).continueAction;
    if (_selectedPlan == PaywallPlan.monthly) {
      return 'Subscribe · ${_monthlyPrice(iap)}';
    }
    return 'Start free trial · then ${_weeklyPrice(iap)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final iap = ref.watch(iapControllerProvider);
    final usage = auth.usage;

    ref.listen(authControllerProvider, (previous, next) {
      if (!mounted || widget.fromSettings) return;
      if (next.isPro && previous?.isPro != true) {
        _continueFree();
      }
    });

    final rows = [
      (l10n.featureWebSearching, true, true),
      (l10n.featureDuplicateImages, true, true),
      (l10n.featureFaceDetection, true, true),
      (
        '${SubscriptionConfig.freeLifetimeSearches} free lifetime searches',
        true,
        false,
      ),
      (
        '${SubscriptionConfig.introTrialSearchAllowance} searches · 3-day trial (weekly)',
        false,
        true,
      ),
      (
        '${SubscriptionConfig.weeklySearchAllowance} searches each paid week',
        false,
        true,
      ),
      (
        '${SubscriptionConfig.monthlySearchAllowance} searches / 30 days (monthly plan)',
        false,
        true,
      ),
      (l10n.featureRemoveAds, false, true),
      (l10n.featureVipSupport, false, true),
    ];

    return Scaffold(
      backgroundColor: AppColors.page(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _continueFree,
                  icon: const Icon(Icons.close),
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.travel_explore,
                size: 72,
                color: AppColors.primary.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.unlockAllFeatures,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _statusSubtitle(auth, usage),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.muted(context),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const SubscriptionTierTable(),
              const SizedBox(height: 20),
              if (!auth.isPro) ...[
                SubscriptionPlanPicker(
                  selected: _selectedPlan,
                  onSelected: (plan) => setState(() => _selectedPlan = plan),
                  weeklyPrice: _weeklyPrice(iap),
                  monthlyPrice: _monthlyPrice(iap),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                l10n.whatsIncluded,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Free', style: TextStyle(color: AppColors.muted(context))),
                    const SizedBox(width: 28),
                    Text(
                      'Premium',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    children: rows.map((row) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.$1,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.text(context),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              child: Icon(
                                row.$2 ? Icons.check_circle : Icons.circle,
                                size: 18,
                                color: row.$2
                                    ? AppColors.primary
                                    : AppColors.brandIconMuted(context),
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              child: Icon(
                                row.$3 ? Icons.check_circle : Icons.circle,
                                size: 18,
                                color: row.$3
                                    ? AppColors.primary
                                    : AppColors.brandIconMuted(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _selectedPlan == PaywallPlan.monthly
                      ? 'Monthly plan bills immediately through the store. '
                          'Cancel anytime in subscription settings.'
                      : l10n.proTrialWeekly,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.muted(context),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: auth.isPro ? _continueFree : () => _subscribe(iap),
                    child: Text(
                      _primaryCtaLabel(iap, auth.isPro),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ),
              if (!auth.isPro) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _continueFree,
                  child: Text(l10n.continueForFree),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(iapControllerProvider.notifier).restore(),
                  child: const Text('Restore purchases'),
                ),
              ],
              if (_selectedPlan == PaywallPlan.weeklyTrial && !auth.isPro) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(l10n.noPaymentNow, style: TextStyle(color: AppColors.text(context))),
                  ],
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
