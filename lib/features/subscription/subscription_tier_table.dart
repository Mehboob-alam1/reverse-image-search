import 'package:flutter/material.dart';

import '../../core/constants/subscription_config.dart';
import '../../core/theme/app_colors.dart';

/// Marketing + pricing table aligned with SerpApi Starter economics.
class SubscriptionTierTable extends StatelessWidget {
  const SubscriptionTierTable({super.key});

  @override
  Widget build(BuildContext context) {
    final tiers = [
      _TierRow(
        name: 'Free',
        price: '\$0',
        searches: '${SubscriptionConfig.freeLifetimeSearches} lifetime',
        highlight: false,
      ),
      _TierRow(
        name: '3-day trial',
        price: '\$0',
        searches: '${SubscriptionConfig.introTrialSearchAllowance} in trial',
        highlight: false,
      ),
      _TierRow(
        name: 'Weekly',
        price: SubscriptionConfig.suggestedWeeklyPriceLabel,
        searches: '${SubscriptionConfig.weeklySearchAllowance} / week',
        highlight: true,
      ),
      _TierRow(
        name: 'Monthly',
        price: SubscriptionConfig.suggestedMonthlyPriceLabel,
        searches: '${SubscriptionConfig.monthlySearchAllowance} / 30 days',
        highlight: false,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Plan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      'Price',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Searches',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...tiers.map((tier) {
              return Container(
                color: tier.highlight
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : null,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tier.name,
                        style: TextStyle(
                          fontWeight: tier.highlight ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.text(context),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: Text(
                        tier.price,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.muted(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        tier.searches,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text(context),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TierRow {
  const _TierRow({
    required this.name,
    required this.price,
    required this.searches,
    required this.highlight,
  });

  final String name;
  final String price;
  final String searches;
  final bool highlight;
}

enum PaywallPlan { weeklyTrial, monthly }

class SubscriptionPlanPicker extends StatelessWidget {
  const SubscriptionPlanPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.weeklyPrice,
    required this.monthlyPrice,
  });

  final PaywallPlan selected;
  final ValueChanged<PaywallPlan> onSelected;
  final String weeklyPrice;
  final String monthlyPrice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _PlanTile(
            title: 'Weekly + 3-day free trial',
            subtitle:
                '${SubscriptionConfig.introTrialSearchAllowance} searches in trial, '
                'then ${SubscriptionConfig.weeklySearchAllowance}/week',
            price: weeklyPrice,
            badge: 'Popular',
            selected: selected == PaywallPlan.weeklyTrial,
            onTap: () => onSelected(PaywallPlan.weeklyTrial),
          ),
          const SizedBox(height: 10),
          _PlanTile(
            title: 'Monthly',
            subtitle:
                '${SubscriptionConfig.monthlySearchAllowance} searches every 30 days · no trial',
            price: monthlyPrice,
            selected: selected == PaywallPlan.monthly,
            onTap: () => onSelected(PaywallPlan.monthly),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String price;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border(context),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.muted(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.text(context),
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                price,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
