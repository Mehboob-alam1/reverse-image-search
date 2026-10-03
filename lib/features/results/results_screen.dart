import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/widgets/ad_bottom_scaffold.dart';
import '../../core/widgets/app_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../models/search_result.dart';
import '../../services/analytics_service.dart';
import '../../services/share_service.dart';
import '../../services/url_service.dart';
import '../controllers.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index = ref.read(searchControllerProvider).homeSearchMode.resultsTabIndex;
      if (_tabs.index != index) {
        _tabs.animateTo(index.clamp(0, 4));
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(searchControllerProvider);
    final favorites = ref.watch(favoritesControllerProvider).value ?? [];
    final favoriteIds = favorites.map((e) => e.result.id).toSet();

    if (session.error != null) {
      final copy = _errorCopy(l10n, session.error!);
      return Scaffold(
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
      if (session.loading) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.searchResults),
            leading: BackButton(onPressed: () => _backToHome(context)),
          ),
          body: const LoadingView(),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.searchResults),
          leading: BackButton(onPressed: () => _backToHome(context)),
        ),
        body: ErrorView(
          title: l10n.searchFailedTitle,
          body: l10n.searchFailedBody,
          onRetry: () => context.go('/home'),
        ),
      );
    }

    return AdBottomScaffold(
      appBar: AppBar(
        title: Text(l10n.searchResults),
        leading: BackButton(onPressed: () => _backToHome(context)),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.tabAll),
            Tab(text: l10n.tabVisual),
            Tab(text: l10n.tabExact),
            Tab(text: l10n.tabProducts),
            Tab(text: l10n.tabAbout),
          ],
        ),
      ),
      body: Column(
        children: [
          if (session.pending != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: ImagePreview(
                filePath: session.pending!.localPath,
                networkUrl: session.pending!.remoteUrl ?? session.response?.queryImage,
                height: 220,
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ResultList(items: results.all, emptyTitle: l10n.noResultsTitle, emptyBody: l10n.noResultsBody, favoriteIds: favoriteIds, onOpen: _open),
                _ResultList(items: results.visualMatches, emptyTitle: l10n.noResultsTitle, emptyBody: l10n.noResultsBody, favoriteIds: favoriteIds, onOpen: _open),
                _ResultList(items: results.exactMatches, emptyTitle: l10n.noExactMatches, emptyBody: '', favoriteIds: favoriteIds, onOpen: _open),
                _ResultList(items: results.products, emptyTitle: l10n.noResultsTitle, emptyBody: l10n.noResultsBody, favoriteIds: favoriteIds, onOpen: _open),
                _AboutTab(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l10n.copyrightNotice, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _ResultList extends ConsumerWidget {
  const _ResultList({
    required this.items,
    required this.emptyTitle,
    required this.emptyBody,
    required this.favoriteIds,
    required this.onOpen,
  });

  final List<SearchResult> items;
  final String emptyTitle;
  final String emptyBody;
  final Set<String> favoriteIds;
  final ValueChanged<SearchResult> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return EmptyState(title: emptyTitle, body: emptyBody, icon: Icons.search);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ResultCard(
            result: item,
            isFavorite: favoriteIds.contains(item.id),
            onOpen: () => onOpen(item),
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
      },
    );
  }
}

class _AboutTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final about = ref.watch(searchControllerProvider).response?.results.aboutImage;
    if (about == null || !about.hasContent) {
      return EmptyState(title: l10n.aboutUnavailable, body: '', icon: Icons.info);
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
          ...about.relatedWebsites.map((url) => ListTile(
                title: Text(url),
                onTap: () => const UrlService().openExternal(url),
              )),
        ],
        if (about.relatedSearches.isNotEmpty) ...[
          Text(l10n.relatedSearches, style: Theme.of(context).textTheme.titleMedium),
          ...about.relatedSearches.map((item) => ListTile(title: Text(item))),
        ],
      ],
    );
  }
}
