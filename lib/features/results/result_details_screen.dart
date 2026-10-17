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
    final isFav =
    favorites.any((e) => e.result.favoriteId == result.favoriteId);
    final url = _pageUrl ?? '';
    final domain = result.sourceDomain ?? _host(url);
    final imageUrls = result.imageCandidateUrls;
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

    Future<void> copyLink() async {
      await Clipboard.setData(ClipboardData(text: url));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.copied),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    final hasDescription = result.description != null &&
        result.description!.isNotEmpty &&
        result.description != result.title;

    return AdBottomScaffold(
      nativeAdSlotKey: 'details-${result.favoriteId}',
      backgroundColor: AppColors.page(context),
      // The hero image runs behind the app bar, so the scaffold app bar is
      // replaced by a SliverAppBar inside the scroll view.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 320,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: Colors.black,
                  automaticallyImplyLeading: false,
                  leading: _OverlayIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  actions: [
                    _OverlayIconButton(
                      icon: isFav ? Icons.favorite : Icons.favorite_border,
                      iconColor: isFav ? AppColors.error : Colors.white,
                      tooltip: isFav ? l10n.unfavorite : l10n.favorite,
                      onPressed: toggleFavorite,
                    ),
                    _OverlayIconButton(
                      icon: Icons.share_outlined,
                      tooltip: l10n.share,
                      onPressed: share,
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: _HeroImage(imageUrls: imageUrls),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    // Rounded sheet that overlaps the bottom of the hero.
                    transform: Matrix4.translationValues(0, -20, 0),
                    decoration: BoxDecoration(
                      color: AppColors.page(context),
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MatchBadge(style: style),
                        const SizedBox(height: 14),
                        Text(
                          result.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          style.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: AppColors.muted(context),
                          ),
                        ),
                        if (result.price != null) ...[
                          const SizedBox(height: 14),
                          _PriceTag(price: result.price!),
                        ],
                        if (domain != null) ...[
                          const SizedBox(height: 20),
                          _SourceCard(
                            domain: domain,
                            onOpen: url.isEmpty
                                ? null
                                : () => const UrlService().openExternal(url),
                          ),
                        ],
                        if (hasDescription) ...[
                          const SizedBox(height: 14),
                          _Section(
                            icon: Icons.subject_rounded,
                            title: l10n.imageContext,
                            child: Text(
                              result.description!,
                              style: textTheme.bodyMedium?.copyWith(
                                height: 1.55,
                                color: AppColors.text(context),
                              ),
                            ),
                          ),
                        ],
                        if (url.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _Section(
                            icon: Icons.link_rounded,
                            title: 'Page URL',
                            trailing: IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: l10n.copyLink,
                              onPressed: copyLink,
                              icon: Icon(
                                Icons.copy_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            child: SelectableText(
                              url,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _Section(
                          icon: Icons.info_outline_rounded,
                          title: 'About this result',
                          child: Text(
                            'This match comes from public web indexes. '
                                'Open the source site to verify ownership, context, and usage rights.',
                            style: textTheme.bodySmall?.copyWith(
                              height: 1.5,
                              color: AppColors.muted(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (url.isNotEmpty)
            _ActionBar(
              label: domain != null ? 'Visit $domain' : l10n.openWebsite,
              copyTooltip: l10n.copyLink,
              shareTooltip: l10n.share,
              onOpen: () => const UrlService().openExternal(url),
              onCopy: copyLink,
              onShare: share,
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── models ─────────────────────────

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

// ───────────────────────── hero ─────────────────────────

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.black.withValues(alpha: 0.42),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: Padding(
            // Leaves room for the rounded sheet that overlaps the image.
            padding: const EdgeInsets.only(bottom: 20),
            child: imageUrls.isNotEmpty
                ? MatchNetworkImage(
              urls: imageUrls,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              placeholder: Container(
                color: AppColors.primary.withValues(alpha: 0.08),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: const _HeroFallback(),
            )
                : const _HeroFallback(),
          ),
        ),
        // Top scrim keeps the overlay buttons legible on bright images.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.3],
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
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

// ───────────────────────── content pieces ─────────────────────────

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.style});

  final _MatchStyle style;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        decoration: BoxDecoration(
          color: style.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 16, color: style.color),
            const SizedBox(width: 6),
            Text(
              style.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: style.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.price});

  final String price;

  @override
  Widget build(BuildContext context) {
    return Text(
      price,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.success,
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
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
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

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.domain, this.onOpen});

  final String domain;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to open source website',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.north_east_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 32,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ───────────────────────── bottom bar ─────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.label,
    required this.copyTooltip,
    required this.shareTooltip,
    required this.onOpen,
    required this.onCopy,
    required this.onShare,
  });

  final String label;
  final String copyTooltip;
  final String shareTooltip;
  final VoidCallback onOpen;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: label,
                  onPressed: onOpen,
                  icon: Icons.language_rounded,
                ),
              ),
              const SizedBox(width: 10),
              _SquareAction(
                icon: Icons.link_rounded,
                tooltip: copyTooltip,
                onPressed: onCopy,
              ),
              const SizedBox(width: 8),
              _SquareAction(
                icon: Icons.share_outlined,
                tooltip: shareTooltip,
                onPressed: onShare,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(
            width: 50,
            height: 50,
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}