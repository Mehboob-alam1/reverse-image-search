import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/ad_bottom_scaffold.dart';
import '../../core/widgets/app_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../services/analytics_service.dart';
import '../../services/share_service.dart';
import '../controllers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favoritesAsync = ref.watch(favoritesControllerProvider);

    return AdBottomScaffold(
      nativeAdSlotKey: 'favorites',
      backgroundColor: AppColors.page(context),
      appBar: AppBar(
        title: Text(l10n.favoritesTitle),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        ),
      ),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorView(
          title: l10n.searchFailedTitle,
          body: l10n.searchFailedBody,
          onRetry: () => ref.invalidate(favoritesControllerProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: l10n.noFavoritesTitle,
              body: l10n.noFavoritesBody,
              icon: Icons.favorite_border,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(favoritesControllerProvider.notifier).toggle(item.result);
                  },
                  child: ResultCard(
                    result: item.result,
                    isFavorite: true,
                    onOpen: () => context.push('/result-details', extra: item.result),
                    onFavorite: () =>
                        ref.read(favoritesControllerProvider.notifier).toggle(item.result),
                    onShare: () {
                      ref.read(analyticsServiceProvider).resultShared();
                      const ShareService().shareResult(
                        title: item.result.title,
                        url: item.result.sourceUrl ?? item.result.imageUrl ?? '',
                      );
                    },
                    compact: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
