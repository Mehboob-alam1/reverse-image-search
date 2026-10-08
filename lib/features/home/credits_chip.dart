import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_models.dart';
import '../controllers.dart';

String _premiumLabel(UsageStats? usage, int remaining, int limit) {
  if (usage?.trialActive == true) return 'Trial $remaining/$limit';
  if (usage?.tier == UsageTier.monthly) return 'Mo $remaining/$limit';
  if (usage?.tier == UsageTier.weekly) return 'Wk $remaining/$limit';
  return '$remaining/$limit';
}

class CreditsChip extends ConsumerWidget {
  const CreditsChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final usage = auth.usage;
    final remaining = usage?.remaining ?? AppConstants.freeSearchCredits;
    final limit = usage?.limit ?? AppConstants.freeSearchCredits;
    if (auth.isPro) {
      return GestureDetector(
        onTap: () => context.push('/subscription'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            _premiumLabel(usage, remaining, limit),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => context.push('/subscription'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          '$remaining left',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
