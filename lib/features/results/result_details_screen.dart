import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/ad_bottom_scaffold.dart';
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

  String? get _pageUrl {
    final u = result.sourceUrl;
    if (u != null && u.isNotEmpty) return u;
    return result.imageUrl;
  }

  String? _host(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      return Uri.parse(url).host.replaceFirst(RegExp(r'^www\.'), '');
    } on Object {
      return null;
    }
  }

  _MatchStyle _matchStyle() {
    return switch (result.category) {
      'exact_match' => const _MatchStyle(
          label: 'Exact match',
          subtitle: 'Same or very similar image on the web',
          icon: Icons.fingerprint,
          color: AppColors.success,
        ),
      'product' => const _MatchStyle(
          label: 'Product listing',
          subtitle: 'Shopping or store page',
          icon: Icons.shopping_bag_outlined,
          color: AppColors.accentGold,
        ),
      'visual_match' => const _MatchStyle(
          label: 'Visual match',
          subtitle: 'Related image from visual search',
          icon: Icons.image_search_rounded,
          color: AppColors.primaryLight,
        ),
      _ => const _MatchStyle(
          label: 'Web match',
          subtitle: 'Page linked to this image',
          icon: Icons.travel_explore,
          color: AppColors.primary,
        ),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesControllerProvider).value ?? [];
    final isFav = favorites.any((e) => e.result.favoriteId == result.favoriteId);
    final url = _pageUrl ?? '';
    final domain = result.sourceDomain ?? _host(url);
    final imageUrl = result.imageUrl ?? result.thumbnail;
    final style = _matchStyle();
    final textTheme = Theme.of(context).textTheme;

    Future<void> toggleFavorite() async {
      await ref.read(favoritesControllerProvider.notifier).toggle(result);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFav ? l10n.unfavorite : l10n.favorite),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    void share() {
      ref.read(analyticsServiceProvider).resultShared();
      const ShareService().shareResult(title: result.title, url: url);
    }

    return AdBottomScaffold(
      nativeAdSlotKey: 'details-${result.favoriteId}',
      backgroundColor: AppColors.page(context),
      appBar: AppBar(
        title: Text(
          l10n.resultDetails,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: isFav ? l10n.unfavorite : l10n.favorite,
            onPressed: toggleFavorite,
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.error : AppColors.brandIcon(context),
            ),
          ),
          IconButton(
            tooltip: l10n.share,
            onPressed: share,
            icon: Icon(Icons.share_outlined, color: AppColors.brandIcon(context)),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroImage(imageUrl: imageUrl, domain: domain),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MatchTypeChip(style: style),
                        const SizedBox(height: 14),
                        Text(
                          result.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: AppColors.text(context),
                          ),
                        ),
                        if (result.price != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            result.price!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        if (domain != null)
                          _SourceCard(
                            domain: domain,
                            url: url,
                            onOpen: url.isEmpty
                                ? null
                                : () => const UrlService().openExternal(url),
                          ),
                        const SizedBox(height: 20),
                        if (result.description != null &&
                            result.description!.isNotEmpty &&
                            result.description != result.title)
                          _InfoCard(
                            icon: Icons.subject_rounded,
                            title: l10n.imageContext,
                            child: Text(
                              result.description!,
                              style: textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                                color: AppColors.muted(context),
                              ),
                            ),
                          ),
                        if (url.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _InfoCard(
                            icon: Icons.link_rounded,
                            title: 'Page URL',
                            child: SelectableText(
                              url,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _InfoCard(
                          icon: Icons.info_outline_rounded,
                          title: 'About this result',
                          child: Text(
                            'This match comes from public web indexes. '
                            'Open the source site to verify ownership, context, and usage rights.',
                            style: textTheme.bodySmall?.copyWith(
                              height: 1.45,
                              color: AppColors.muted(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (url.isNotEmpty)
            _DetailActionBar(
              l10n: l10n,
              domain: domain,
              onOpen: () => const UrlService().openExternal(url),
              onCopy: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.copied),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              onShare: share,
            ),
        ],
      ),
    );
  }
}

class _MatchStyle {
  const _MatchStyle({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrl, this.domain});

  final String? imageUrl;
  final String? domain;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                color: AppColors.primary.withValues(alpha: 0.08),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, _, _) => const _HeroFallback(),
            )
          else
            const _HeroFallback(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
          if (domain != null)
            Positioned(
              left: 16,
              bottom: 14,
              right: 16,
              child: Row(
                children: [
                  _DomainAvatar(domain: domain!, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      domain!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.12),
      child: Icon(
        Icons.image_outlined,
        size: 72,
        color: AppColors.brandIconMuted(context),
      ),
    );
  }
}

class _DomainAvatar extends StatelessWidget {
  const _DomainAvatar({required this.domain, this.size = 44});

  final String domain;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = domain.isNotEmpty ? domain[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

class _MatchTypeChip extends StatelessWidget {
  const _MatchTypeChip({required this.style});

  final _MatchStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, color: style.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: style.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  style.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted(context),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.domain,
    required this.url,
    this.onOpen,
  });

  final String domain;
  final String url;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _DomainAvatar(domain: domain),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      domain,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to open source website',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted(context),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailActionBar extends StatelessWidget {
  const _DetailActionBar({
    required this.l10n,
    required this.onOpen,
    required this.onCopy,
    required this.onShare,
    this.domain,
  });

  final AppLocalizations l10n;
  final VoidCallback onOpen;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final String? domain;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: AppColors.card(context),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(
                label: domain != null ? 'Visit $domain' : l10n.openWebsite,
                onPressed: onOpen,
                icon: Icons.language_rounded,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.link, size: 18),
                      label: Text(l10n.copyLink),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: Text(l10n.share),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
