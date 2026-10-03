import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/app_exception_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/picked_media.dart';
import '../../core/utils/url_validator.dart';
import '../../core/widgets/ad_bottom_scaffold.dart';
import '../../core/widgets/app_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../models/home_search_mode.dart';
import '../../models/user_models.dart';
import '../../services/analytics_service.dart';
import '../controllers.dart';
import 'app_drawer.dart';
import 'home_icons.dart';
import 'image_source_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.focusSearch = false});

  final bool focusSearch;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeMode {
  const _HomeMode({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.searchMode,
    this.badge = '',
    this.pro = false,
    this.social = false,
  });

  final String title;
  final String subtitle;
  final HomeIconKind icon;
  final HomeSearchMode searchMode;
  final String badge;
  final bool pro;
  final bool social;
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _name = TextEditingController();

  List<_HomeMode> _modes(AppLocalizations l10n) => [
        _HomeMode(
          title: l10n.modeFaceTitle,
          subtitle: l10n.modeFaceSubtitle,
          icon: HomeIconKind.face,
          searchMode: HomeSearchMode.face,
          badge: l10n.badgeNew,
        ),
        _HomeMode(
          title: l10n.modeSocialTitle,
          subtitle: l10n.modeSocialSubtitle,
          icon: HomeIconKind.twitter,
          searchMode: HomeSearchMode.social,
          badge: l10n.badgeNew,
          social: true,
        ),
        _HomeMode(
          title: l10n.modeObjectTitle,
          subtitle: l10n.modeObjectSubtitle,
          icon: HomeIconKind.plant,
          searchMode: HomeSearchMode.object,
        ),
        _HomeMode(
          title: l10n.modeSimilarTitle,
          subtitle: l10n.modeSimilarSubtitle,
          icon: HomeIconKind.photo,
          searchMode: HomeSearchMode.similar,
          badge: l10n.badgePro,
          pro: true,
        ),
        _HomeMode(
          title: l10n.modeWebTitle,
          subtitle: l10n.modeWebSubtitle,
          icon: HomeIconKind.globe,
          searchMode: HomeSearchMode.web,
        ),
        _HomeMode(
          title: l10n.modeDuplicateTitle,
          subtitle: l10n.modeDuplicateSubtitle,
          icon: HomeIconKind.duplicate,
          searchMode: HomeSearchMode.duplicate,
        ),
      ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _openMode(_HomeMode mode) async {
    if (mode.pro) {
      context.push('/subscription');
      return;
    }
    if (mode.social) {
      context.push('/social-search');
      return;
    }
    await _pickAndSearch(mode.searchMode);
  }

  Future<void> _pickAndSearch([HomeSearchMode mode = HomeSearchMode.general]) async {
    final typed = _name.text.trim();
    if (UrlValidator.isValidHttpUrl(typed)) {
      final search = ref.read(searchControllerProvider.notifier);
      search.beginSearch(
        image: PendingImage(remoteUrl: typed),
        mode: mode,
      );
      search.scheduleSearch();
      if (mounted) context.push('/searching');
      return;
    }

    final source = await ImageSourceSheet.show(context);
    if (source == null || !mounted) return;

    try {
      if (source == ImageSource.gallery) {
        await ref.read(analyticsServiceProvider).galleryOpened();
      }
      final file = await PickedMedia.pickOriginal(source: source);
      if (file == null || !mounted) return;
      await ref.read(analyticsServiceProvider).imageSelected();
      final search = ref.read(searchControllerProvider.notifier);
      search.beginSearch(
        image: PendingImage(localPath: file.path),
        mode: mode,
      );
      search.scheduleSearch();
      if (mounted) context.push('/searching');
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedAppException(AppLocalizations.of(context), error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modes = _modes(l10n);
    final textColor = AppColors.text(context);
    final muted = AppColors.muted(context);
    final cardColor = AppColors.card(context);

    return AdBottomScaffold(
      backgroundColor: AppColors.page(context),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Builder(
                              builder: (context) => IconButton(
                                onPressed: () => Scaffold.of(context).openDrawer(),
                                icon: const Icon(Icons.menu, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l10n.appName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ProChip(onTap: () => context.push('/subscription')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.whoAreYouLookingFor,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      controller: _name,
                      hint: l10n.typeFullNameHint,
                      prefix: Icon(
                        Icons.search,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      onSubmitted: (_) => _pickAndSearch(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              itemCount: modes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final mode = modes[index];
                return Material(
                  color: cardColor,
                  elevation: 1,
                  shadowColor: const Color(0x14000000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: BorderSide(color: AppColors.border(context), width: 1.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _openMode(mode),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 52, 16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: HomeTileIcon(kind: mode.icon),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mode.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      mode.subtitle,
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (mode.badge.isNotEmpty)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: ProChip(label: mode.badge, compact: true),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
