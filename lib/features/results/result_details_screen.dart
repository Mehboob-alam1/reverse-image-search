import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../models/search_result.dart';
import '../../services/analytics_service.dart';
import '../../services/share_service.dart';
import '../../services/url_service.dart';
import '../controllers.dart';

class ResultDetailsScreen extends ConsumerWidget {
  const ResultDetailsScreen({super.key, required this.result});

  final SearchResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isFav = ref.watch(favoritesControllerProvider.notifier).isFavorite(result.id);
    final url = result.sourceUrl ?? result.imageUrl ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resultDetails)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ImagePreview(networkUrl: result.imageUrl ?? result.thumbnail, height: 280),
          const SizedBox(height: 16),
          Text(result.title, style: Theme.of(context).textTheme.headlineSmall),
          if (result.sourceDomain != null) ...[
            const SizedBox(height: 8),
            Text(l10n.sourceLabel(result.sourceDomain!)),
          ],
          if (result.description != null) ...[
            const SizedBox(height: 12),
            Text(result.description!),
          ],
          if (result.price != null) ...[
            const SizedBox(height: 12),
            Text(result.price!, style: Theme.of(context).textTheme.titleLarge),
          ],
          const SizedBox(height: 8),
          Text(result.category),
          if (url.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(url, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: l10n.openWebsite,
            onPressed: () => const UrlService().openExternal(url),
            icon: Icons.open_in_new,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: l10n.share,
            onPressed: () {
              ref.read(analyticsServiceProvider).resultShared();
              const ShareService().shareResult(title: result.title, url: url);
            },
          ),
          TextButton.icon(
            onPressed: () => ref.read(favoritesControllerProvider.notifier).toggle(result),
            icon: Icon(
              Icons.favorite,
              color: isFav ? AppColors.error : AppColors.brandIconMuted(context),
            ),
            label: Text(isFav ? l10n.unfavorite : l10n.favorite),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copied)));
              }
            },
            icon: const Icon(Icons.link),
            label: Text(l10n.copyLink),
          ),
        ],
      ),
    );
  }
}
