import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ads/ads_controller.dart';
import '../controllers.dart';

/// Shown when the user has no search credits left.
Future<void> showCreditsExhaustedSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CreditsExhaustedSheet(),
  );
}

class _CreditsExhaustedSheet extends ConsumerStatefulWidget {
  const _CreditsExhaustedSheet();

  @override
  ConsumerState<_CreditsExhaustedSheet> createState() =>
      _CreditsExhaustedSheetState();
}

class _CreditsExhaustedSheetState extends ConsumerState<_CreditsExhaustedSheet> {
  bool _watching = false;

  Future<void> _watchAd() async {
    if (_watching) return;
    setState(() => _watching = true);
    final ok =
        await ref.read(adsControllerProvider.notifier).watchRewardedForCredit();
    if (!mounted) return;
    setState(() => _watching = false);
    final l10n = AppLocalizations.of(context);
    if (ok) {
      final remaining =
          ref.read(authControllerProvider).usage?.remaining ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.rewardedCreditEarned(remaining)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.rewardedAdFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final usage = ref.watch(authControllerProvider).usage;
    final used = usage?.used ?? 0;
    final limit = usage?.limit ?? 0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Icon(Icons.hourglass_disabled_rounded, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              l10n.creditsExpiredTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.creditsExpiredBody(used, limit),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _watching ? null : _watchAd,
              icon: _watching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ondemand_video_rounded),
              label: Text(
                _watching ? l10n.loadingAd : l10n.watchAdForCredit,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/subscription');
              },
              child: Text(l10n.upgradeToPro),
            ),
          ],
        ),
      ),
    );
  }
}
