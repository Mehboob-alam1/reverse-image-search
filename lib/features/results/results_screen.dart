import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ad_bottom_scaffold.dart';
import '../../core/widgets/app_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../models/search_response.dart';
import '../../models/search_result.dart';
import '../../services/analytics_service.dart';
import '../../services/share_service.dart';
import '../../services/url_service.dart';
import '../controllers.dart';

enum _ResultsFilter { all, visual, exact, products, about }

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  _ResultsFilter _filter = _ResultsFilter.all;

  (String, String) _errorCopy(AppLocalizations l10n, AppException error) {
    switch (error.code) {
      case AppErrorCode.network:
        return (l10n.noInternetTitle, l10n.noInternetBody);
      case AppErrorCode.rateLimit:
        return (l10n.rateLimitTitle, l10n.rateLimitBody);
      case AppErrorCode.invalidImage:
        return (l10n.unsupportedImageTitle, l10n.unsupportedImageBody);
      case AppErrorCode.unavailable:
        return (l10n.serviceUnavailableTitle, l10n.serviceUnavailableBody);
      default:
        return (l10n.searchFailedTitle, l10n.searchFailedBody);
    }
  }

  void _backToHome(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _open(SearchResult result) async {
    await ref.read(analyticsServiceProvider).resultOpened();
    if (!mounted) return;
    context.push('/result-details', extra: result);
  }

  List<SearchResult> _dedupe(List<SearchResult> items) {
    final seen = <String>{};
    final out = <SearchResult>[];
    for (final item in items) {
      if (seen.add(item.favoriteId)) out.add(item);
    }
    return out;
  }

  List<SearchResult> _itemsForFilter(SearchResultsBundle results, _ResultsFilter filter) {
    return switch (filter) {
      _ResultsFilter.all => _dedupe(results.all),
      _ResultsFilter.visual => results.visualMatches,
      _ResultsFilter.exact => results.exactMatches,
      _ResultsFilter.products => results.products,
      _ResultsFilter.about => const [],
    };
  }

  Widget _resultTile(
    SearchResult item,
    Set<String> favoriteIds,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ResultCard(
        result: item,
        isFavorite: favoriteIds.contains(item.favoriteId),
        onOpen: () => _open(item),
        onFavorite: () => ref.read(favoritesControllerProvider.notifier).toggle(item),
        onShare: () {
          ref.read(analyticsServiceProvider).resultShared();
          const ShareService().shareResult(
            title: item.title,
            url: item.sourceUrl ?? item.imageUrl ?? '',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(searchControllerProvider);
    final favorites = ref.watch(favoritesControllerProvider).value ?? [];
    final favoriteIds = favorites.map((e) => e.result.favoriteId).toSet();

    if (session.error != null) {
      final copy = _errorCopy(l10n, session.error!);
      return AdBottomScaffold(
        nativeAdSlotKey: 'results-error',
        appBar: AppBar(
          title: Text(l10n.searchResults),
          leading: BackButton(onPressed: () => _backToHome(context)),
        ),
        body: ErrorView(
          title: copy.$1,
          body: copy.$2,
          onRetry: () => context.go('/home'),
        ),
      );
    }

    final results = session.response?.results;
    if (results == null) {
      return AdBottomScaffold(
        nativeAdSlotKey: 'results-loading',
        appBar: AppBar(
          title: Text(l10n.searchResults),
          leading: BackButton(onPressed: () => _backToHome(context)),
        ),
        body: session.loading
            ? const LoadingView()
            : ErrorView(
                title: l10n.searchFailedTitle,
                body: l10n.searchFailedBody,
                onRetry: () => context.go('/home'),
              ),
      );
    }

    final allCount = _dedupe(results.all).length;
    final listItems = _itemsForFilter(results, _filter);

    return AdBottomScaffold(
      nativeAdSlotKey: 'results-${session.response!.searchId}',
      backgroundColor: AppColors.page(context),
      appBar: AppBar(
        title: Text('${l10n.searchResults} ($allCount)'),
        leading: BackButton(onPressed: () => _backToHome(context)),
      ),
      body: _filter == _ResultsFilter.about
          ? _AboutTab()
          : listItems.isEmpty
              ? CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(session, results, allCount, l10n)),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        title: l10n.noResultsTitle,
                        body: l10n.noResultsBody,
                        icon: Icons.search_off,
                      ),
                    ),
                  ],
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(session, results, allCount, l10n),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _resultTile(listItems[index], favoriteIds),
                          childCount: listItems.length,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader(
    SearchSession session,
    SearchResultsBundle results,
    int allCount,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResultsQueryHeader(session: session),
        _FilterChips(
          filter: _filter,
          allCount: allCount,
          visualCount: results.visualMatches.length,
          exactCount: results.exactMatches.length,
          productCount: results.products.length,
          l10n: l10n,
          onSelected: (f) => setState(() => _filter = f),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filter,
    required this.allCount,
    required this.visualCount,
    required this.exactCount,
    required this.productCount,
    required this.l10n,
    required this.onSelected,
  });

  final _ResultsFilter filter;
  final int allCount;
  final int visualCount;
  final int exactCount;
  final int productCount;
  final AppLocalizations l10n;
  final ValueChanged<_ResultsFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = [
      (_ResultsFilter.all, '${l10n.tabAll} ($allCount)'),
      (_ResultsFilter.visual, '${l10n.tabVisual} ($visualCount)'),
      (_ResultsFilter.exact, '${l10n.tabExact} ($exactCount)'),
      (_ResultsFilter.products, '${l10n.tabProducts} ($productCount)'),
      (_ResultsFilter.about, l10n.tabAbout),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: options.map((opt) {
          final selected = filter == opt.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selected,
              label: Text(opt.$2),
              onSelected: (_) => onSelected(opt.$1),
              selectedColor: AppColors.primary.withValues(alpha: 0.18),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.text(context),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ResultsQueryHeader extends StatelessWidget {
  const _ResultsQueryHeader({required this.session});

  final SearchSession session;

  @override
  Widget build(BuildContext context) {
    final pending = session.pending;
    final queryUrl = pending?.remoteUrl ?? session.response?.queryImage;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pending != null || (queryUrl != null && queryUrl.isNotEmpty))
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ImagePreview(
                filePath: pending?.localPath,
                networkUrl: queryUrl,
                height: 100,
                radius: 14,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Tap a tile to open full details',
            style: TextStyle(
              color: AppColors.muted(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final about = ref.watch(searchControllerProvider).response?.results.aboutImage;
    if (about == null || !about.hasContent) {
      return EmptyState(title: l10n.aboutUnavailable, body: '', icon: Icons.info_outline);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (about.summary != null) ...[
          Text(l10n.imageContext, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(about.summary!),
          const SizedBox(height: 16),
        ],
        if (about.possibleSource != null) ...[
          Text(l10n.possibleSource, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(about.possibleSource!),
          const SizedBox(height: 16),
        ],
        if (about.relatedWebsites.isNotEmpty) ...[
          Text(l10n.relatedWebsites, style: Theme.of(context).textTheme.titleMedium),
          ...about.relatedWebsites.map(
            (url) => ListTile(
              title: Text(url),
              onTap: () => const UrlService().openExternal(url),
            ),
          ),
        ],
      ],
    );
  }
}
