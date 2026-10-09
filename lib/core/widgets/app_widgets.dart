import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../l10n/app_localizations.dart';
import '../../models/search_result.dart';
import '../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null || loading ? null : AppColors.buttonGradient,
        color: onPressed == null || loading ? AppColors.primary.withValues(alpha: 0.4) : null,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: onPressed == null || loading ? null : AppShadows.button,
      ),
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(label),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.onSubmitted,
    this.onChanged,
    this.prefix,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefix,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.inbox,
    this.action,
  });

  final String title;
  final String body;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: AppColors.brandIcon(context)),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(body, textAlign: TextAlign.center),
                ],
                if (action != null) ...[const SizedBox(height: 20), action!],
              ],
            ),
          ),
        );
      },
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.title,
    required this.body,
    this.onRetry,
  });

  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.error,
      title: title,
      body: body,
      action: onRetry == null
          ? null
          : PrimaryButton(label: l10n.retry, onPressed: onRetry, icon: Icons.refresh),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(label!, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

class ResultSkeleton extends StatelessWidget {
  const ResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: Colors.white,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(width: 84, height: 84, color: base),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: 160, color: base),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 100, color: base),
                    const SizedBox(height: 8),
                    Container(height: 32, width: 80, color: base),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentGold,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}

class UsageProgress extends StatelessWidget {
  const UsageProgress({
    super.key,
    required this.used,
    required this.limit,
    required this.label,
  });

  final int used;
  final int limit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final value = limit == 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: value, minHeight: 8),
        ),
      ],
    );
  }
}

class ModeTile extends StatelessWidget {
  const ModeTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: AppShadows.card,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            if (badge != null) const ProBadge()
            else
              Icon(Icons.chevron_right, color: AppColors.brandIcon(context)),
          ],
        ),
      ),
    );
  }
}

class LanguageTile extends StatelessWidget {
  const LanguageTile({
    super.key,
    required this.name,
    required this.nativeName,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String nativeName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(name),
      subtitle: nativeName == name ? null : Text(nativeName),
      trailing: selected
          ? Icon(Icons.check_circle, color: AppColors.brandIcon(context))
          : Icon(Icons.circle, color: AppColors.brandIconMuted(context), size: 22),
    );
  }
}

class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ??
          Icon(Icons.chevron_right, color: AppColors.brandIcon(context)),
      onTap: onTap,
    );
  }
}

class ImagePreview extends StatelessWidget {
  const ImagePreview({
    super.key,
    this.filePath,
    this.networkUrl,
    this.height = 220,
    this.expand = false,
    this.radius = 20,
    this.fit = BoxFit.contain,
    this.semanticLabel,
  });

  final String? filePath;
  final String? networkUrl;
  final double height;
  final bool expand;
  final double radius;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (filePath != null && filePath!.isNotEmpty) {
      child = Image.file(
        File(filePath!),
        fit: fit,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) =>
            Icon(Icons.broken_image, color: AppColors.brandIcon(context)),
      );
    } else if (networkUrl != null && networkUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: networkUrl!,
        fit: fit,
        alignment: Alignment.center,
        placeholder: (_, _) => const ResultSkeleton(),
        errorWidget: (_, _, _) =>
            Icon(Icons.broken_image, color: AppColors.brandIcon(context)),
      );
    } else {
      child = Icon(Icons.image, size: 48, color: AppColors.brandIcon(context));
    }

    return Semantics(
      label: semanticLabel ?? 'Image preview',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(radius),
          border: expand ? null : Border.all(color: AppColors.cardBorder, width: 1.2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: expand
              ? SizedBox.expand(child: child)
              : SizedBox(width: double.infinity, height: height, child: child),
        ),
      ),
    );
  }
}

/// Loads result images with browser-like headers and tries [urls] in order.
class MatchNetworkImage extends StatefulWidget {
  const MatchNetworkImage({
    super.key,
    required this.urls,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.error,
  });

  final List<String> urls;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? error;

  static const Map<String, String> imageHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
  };

  @override
  State<MatchNetworkImage> createState() => _MatchNetworkImageState();
}

class _MatchNetworkImageState extends State<MatchNetworkImage> {
  int _index = 0;

  @override
  void didUpdateWidget(MatchNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urls != widget.urls) {
      _index = 0;
    }
  }

  void _advance() {
    if (!mounted) return;
    if (_index + 1 < widget.urls.length) {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return widget.error ?? const SizedBox.shrink();
    }
    final url = widget.urls[_index.clamp(0, widget.urls.length - 1)];
    final loading = widget.placeholder ??
        const Center(child: CircularProgressIndicator(strokeWidth: 2));
    final failed = widget.error ??
        Icon(Icons.broken_image, color: AppColors.brandIcon(context));

    return CachedNetworkImage(
      key: ValueKey('$url#$_index'),
      imageUrl: url,
      fit: widget.fit,
      alignment: widget.alignment,
      httpHeaders: MatchNetworkImage.imageHeaders,
      placeholder: (_, _) => loading,
      errorWidget: (_, _, _) {
        if (_index + 1 < widget.urls.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _advance());
          return loading;
        }
        return failed;
      },
    );
  }
}

class NetworkThumb extends StatelessWidget {
  const NetworkThumb({
    super.key,
    this.url,
    this.urls,
    this.size = 84,
    this.filePath,
  });

  final String? url;
  final List<String>? urls;
  final String? filePath;
  final double size;

  List<String> get _resolvedUrls {
    if (urls != null && urls!.isNotEmpty) return urls!;
    if (url != null && url!.trim().isNotEmpty) return [url!.trim()];
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: filePath != null
            ? Image.file(
                File(filePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.image, color: AppColors.brandIcon(context)),
              )
            : _resolvedUrls.isEmpty
                ? const ColoredBox(
                    color: Color(0x11000000),
                    child: Icon(Icons.image, color: AppColors.primary),
                  )
                : MatchNetworkImage(
                    urls: _resolvedUrls,
                    fit: BoxFit.cover,
                    error: Icon(Icons.broken_image, color: AppColors.brandIcon(context)),
                  ),
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.result,
    required this.onOpen,
    required this.onShare,
    required this.onFavorite,
    this.isFavorite = false,
    this.compact = false,
  });

  final SearchResult result;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final bool isFavorite;
  final bool compact;

  String _categoryLabel(String category) {
    return switch (category) {
      'exact_match' => 'Exact',
      'product' => 'Product',
      'visual_match' => 'Visual',
      _ => 'Match',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.card(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(
          color: isFavorite
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.border(context),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: NetworkThumb(
                      urls: result.imageCandidateUrls,
                      size: compact ? 72 : 88,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            _categoryLabel(result.category),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          result.title,
                          maxLines: compact ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                        ),
                        if (result.sourceDomain != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.language,
                                size: 14,
                                color: AppColors.muted(context),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  result.sourceDomain!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (result.price != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            result.price!,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (!compact &&
                  result.description != null &&
                  result.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  result.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.muted(context),
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ResultIconAction(
                    tooltip: isFavorite ? l10n.unfavorite : l10n.favorite,
                    onPressed: onFavorite,
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? AppColors.error : AppColors.brandIcon(context),
                  ),
                  if (!compact)
                    _ResultIconAction(
                      tooltip: l10n.share,
                      onPressed: onShare,
                      icon: Icons.share_outlined,
                      color: AppColors.brandIcon(context),
                    ),
                  FilledButton.tonal(
                    onPressed: onOpen,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(result.isProduct ? l10n.viewProduct : l10n.open),
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

class _ResultIconAction extends StatelessWidget {
  const _ResultIconAction({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.color,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: color),
    );
  }
}
