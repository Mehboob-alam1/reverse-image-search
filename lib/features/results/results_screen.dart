import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/search_stack_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ad_bottom_scaffold.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/inline_native_ad.dart';
import '../../l10n/app_localizations.dart';
import '../../models/search_response.dart';
import '../../models/search_result.dart';
import '../../services/ads/ads_controller.dart';
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

  // ───────────────────────── helpers ─────────────────────────

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

  List<SearchResult> _itemsForFilter(
    SearchResultsBundle results,
    _ResultsFilter filter,
  ) {
    return switch (filter) {
      _ResultsFilter.all => _dedupe(results.all),
      _ResultsFilter.visual => results.visualMatches,
      _ResultsFilter.exact => results.exactMatches,
      _ResultsFilter.products => results.products,
      _ResultsFilter.about => const [],
    };
  }

  /// Result tiles + native ads every N items (from remote ads config).
  List<_FeedRow> _feedRows(List<SearchResult> items) {
    final rows = <_FeedRow>[];
    final every = ref.read(adsManagerProvider).settings.nativeEveryNResults;
    final isPro = ref.watch(authControllerProvider).isPro;
    for (var i = 0; i < items.length; i++) {
      rows.add(_FeedRow.result(items[i]));
      if (every > 0 &&
          (i + 1) % every == 0 &&
          i + 1 < items.length &&
          !isPro) {
        rows.add(_FeedRow.ad('n$i'));
      }
    }
    return rows;
  }

  Widget _resultTile(
    SearchResult item,
    Set<String> favoriteIds, {
    bool compact = false,
  }) {
    return ResultCard(
      result: item,
      compact: compact,
      isFavorite: favoriteIds.contains(item.favoriteId),
      onOpen: () => _open(item),
      onFavorite: () =>
          ref.read(favoritesControllerProvider.notifier).toggle(item),
      onShare: () {
        ref.read(analyticsServiceProvider).resultShared();
        const ShareService().shareResult(
          title: item.title,
          url: item.sourceUrl ?? item.imageUrl ?? '',
        );
      },
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, String title) {
    return AppBar(
      title: Text(title),
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.page(context),
      leading: BackButton(onPressed: () => _backToHome(context)),
    );
  }

  // ───────────────────────── build ─────────────────────────

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
        backgroundColor: AppColors.page(context),
        appBar: _appBar(context, l10n.searchResults),
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
        backgroundColor: AppColors.page(context),
        appBar: _appBar(context, l10n.searchResults),
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
    final feedRows = _feedRows(listItems);

    return AdBottomScaffold(
      nativeAdSlotKey: 'results-${session.response!.searchId}',
      backgroundColor: AppColors.page(context),
      appBar: _appBar(context, l10n.searchResults),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 520;
          final useGrid = _filter == _ResultsFilter.visual && wide;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _QueryHeader(session: session, l10n: l10n),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterBarDelegate(
                  background: AppColors.page(context),
                  child: _FilterBar(
                    filter: _filter,
                    l10n: l10n,
                    counts: {
                      _ResultsFilter.all: allCount,
                      _ResultsFilter.visual: results.visualMatches.length,
                      _ResultsFilter.exact: results.exactMatches.length,
                      _ResultsFilter.products: results.products.length,
                    },
                    onSelected: (f) => setState(() => _filter = f),
                  ),
                ),
              ),
              if (_filter == _ResultsFilter.about)
                ..._aboutSlivers(context, l10n)
              else if (listItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    title: l10n.noResultsTitle,
                    body: l10n.noResultsBody,
                    icon: Icons.search_off,
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text(
                      l10n.resultsOpenHint,
                      style: TextStyle(
                        color: AppColors.muted(context),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
                if (useGrid)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _resultTile(
                          listItems[index],
                          favoriteIds,
                          compact: true,
                        ),
                        childCount: listItems.length,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final row = feedRows[index];
                          if (row.isAd) {
                            return InlineNativeAd(
                              key: ValueKey('feed-ad-${row.adKey}'),
                              slotId: row.adKey!,
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _resultTile(row.result!, favoriteIds),
                          );
                        },
                        childCount: feedRows.length,
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _aboutSlivers(BuildContext context, AppLocalizations l10n) {
    final about =
        ref.watch(searchControllerProvider).response?.results.aboutImage;
    if (about == null || !about.hasContent) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            title: l10n.aboutUnavailable,
            body: '',
            icon: Icons.info_outline,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        sliver: SliverToBoxAdapter(child: _AboutContent(about: about)),
      ),
    ];
  }
}

class _FeedRow {
  const _FeedRow._({this.result, this.adKey});
  factory _FeedRow.result(SearchResult r) => _FeedRow._(result: r);
  factory _FeedRow.ad(String key) => _FeedRow._(adKey: key);

  final SearchResult? result;
  final String? adKey;
  bool get isAd => adKey != null;
}

// ───────────────────────── query header ─────────────────────────

class _QueryHeader extends StatelessWidget {
  const _QueryHeader({required this.session, required this.l10n});

  final SearchSession session;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final pending = session.pending;
    final queryUrl = pending?.remoteUrl ?? session.response?.queryImage;
    final about = session.response?.results.aboutImage;
    final lensWebUrl = about?.metadata[SearchStackConfig.metadataLensWebUrl];
    final hasImage =
        pending != null || (queryUrl != null && queryUrl.isNotEmpty);
    final hasLens = lensWebUrl != null && lensWebUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (hasImage)
              ImagePreview(
                filePath: pending?.localPath,
                networkUrl: queryUrl,
                height: 190,
                radius: 24,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            // Bottom scrim so overlay chips stay readable on any photo.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.45, 1],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.62),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _EnginePill(about: about)),
                  if (hasLens) ...[
                    const SizedBox(width: 8),
                    _LensButton(
                      label: l10n.openInGoogleLens,
                      onTap: () =>
                          const UrlService().openExternal(lensWebUrl),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnginePill extends StatelessWidget {
  const _EnginePill({required this.about});

  final AboutImageInfo? about;

  String _label() {
    final provider =
        about?.metadata[SearchStackConfig.metadataInsightsProvider];
    if (provider != null && provider.isNotEmpty) {
      return '${SearchStackConfig.railwayEngineLabel} · $provider';
    }
    if (AppEnv.useApifySearch) {
      return '${SearchStackConfig.lensEngineLabel} · Apify';
    }
    return SearchStackConfig.railwayEngineLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.travel_explore, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _label(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LensButton extends StatelessWidget {
  const _LensButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── filter bar ─────────────────────────

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  _FilterBarDelegate({required this.child, required this.background});

  final Widget child;
  final Color background;

  static const double _height = 56;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: background,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _FilterBarDelegate old) =>
      old.child != child || old.background != background;
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.counts,
    required this.l10n,
    required this.onSelected,
  });

  final _ResultsFilter filter;
  final Map<_ResultsFilter, int> counts;
  final AppLocalizations l10n;
  final ValueChanged<_ResultsFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = <(_ResultsFilter, String)>[
      (_ResultsFilter.all, l10n.tabAll),
      (_ResultsFilter.visual, l10n.tabVisual),
      (_ResultsFilter.exact, l10n.tabExact),
      (_ResultsFilter.products, l10n.tabProducts),
      (_ResultsFilter.about, l10n.tabAbout),
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: options.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final opt = options[i];
        return _FilterPill(
          label: opt.$2,
          count: counts[opt.$1],
          selected: filter == opt.$1,
          onTap: () => onSelected(opt.$1),
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.text(context);
    final border = AppColors.muted(context).withValues(alpha: 0.28);

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : border,
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.24)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── about tab ─────────────────────────

class _AboutContent extends StatelessWidget {
  const _AboutContent({required this.about});

  final AboutImageInfo about;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = about.metadata[SearchStackConfig.metadataResultsSummary];
    final aiProvider =
        about.metadata[SearchStackConfig.metadataInsightsProvider];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (about.summary != null)
          _AboutSection(
            icon: Icons.image_search_outlined,
            title: l10n.imageContext,
            child: _BodyText(about.summary!),
          ),
        if (about.possibleSource != null)
          _AboutSection(
            icon: Icons.link_rounded,
            title: l10n.possibleSource,
            child: _BodyText(about.possibleSource!),
          ),
        if (summary != null && summary.isNotEmpty)
          _AboutSection(
            icon: Icons.notes_rounded,
            title: l10n.searchResultsOverview,
            child: _BodyText(summary),
          ),
        if (about.relatedSearches.isNotEmpty)
          _AboutSection(
            icon: Icons.manage_search_rounded,
            title: l10n.relatedSearches,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: about.relatedSearches
                  .map(
                    (q) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        q,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        if (about.relatedWebsites.isNotEmpty)
          _AboutSection(
            icon: Icons.public_rounded,
            title: l10n.relatedWebsites,
            padChild: false,
            child: Column(
              children: [
                for (var i = 0; i < about.relatedWebsites.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.muted(context).withValues(alpha: 0.15),
                    ),
                  _WebsiteTile(url: about.relatedWebsites[i]),
                ],
              ],
            ),
          ),
        if (aiProvider != null && aiProvider.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.insightsPoweredBy(aiProvider),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
            ),
          ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.icon,
    required this.title,
    required this.child,
    this.padChild = true,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final bool padChild;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.muted(context).withValues(alpha: 0.16),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.text(context),
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: padChild
                ? const EdgeInsets.fromLTRB(16, 0, 16, 16)
                : const EdgeInsets.only(bottom: 6),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.text(context),
        fontSize: 14.5,
        height: 1.5,
      ),
    );
  }
}

class _WebsiteTile extends StatelessWidget {
  const _WebsiteTile({required this.url});

  final String url;

  String get _host {
    final uri = Uri.tryParse(url);
    final host = uri?.host ?? '';
    return host.isEmpty ? url : host.replaceFirst('www.', '');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => const UrlService().openExternal(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.muted(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.open_in_new,
              size: 16,
              color: AppColors.muted(context),
            ),
          ],
        ),
      ),
    );
  }
}