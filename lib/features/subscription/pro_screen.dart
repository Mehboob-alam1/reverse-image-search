import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/local_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/analytics_service.dart';

class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(analyticsServiceProvider).subscriptionViewed();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = [
      (l10n.featureWebSearching, true, true),
      (l10n.featureDuplicateImages, true, true),
      (l10n.featureFaceDetection, false, true),
      (l10n.featureUnlimitedAccess, false, true),
      (l10n.featureRemoveAds, false, true),
      (l10n.featureVipSupport, false, true),
    ];

    return Scaffold(
      backgroundColor: AppColors.page(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: _continueFree,
                icon: const Icon(Icons.close),
              ),
            ),
            const SizedBox(height: 8),
            Icon(Icons.travel_explore, size: 88, color: AppColors.primary.withValues(alpha: 0.85)),
            const SizedBox(height: 16),
            Text(
              l10n.unlockAllFeatures,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.whatsIncluded,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border(context), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: rows.map((row) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.$1,
                              style: TextStyle(fontSize: 15, color: AppColors.text(context)),
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: Icon(
                              row.$2 ? Icons.check_circle : Icons.circle,
                              size: 20,
                              color: row.$2
                                  ? AppColors.primary
                                  : AppColors.brandIconMuted(context),
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: Icon(
                              row.$3 ? Icons.check_circle : Icons.circle,
                              size: 20,
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
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                l10n.proTrialWeekly,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.muted(context), height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _continueFree,
                  child: Text(
                    l10n.continueForFree,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(l10n.noPaymentNow, style: TextStyle(color: AppColors.text(context))),
              ],
            ),
            const SizedBox(height: 20),
          ],
          ),
        ),
      ),
    );
  }
}
