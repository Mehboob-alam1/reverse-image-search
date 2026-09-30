import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/app_exception_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/picked_media.dart';
import '../../l10n/app_localizations.dart';
import '../../models/home_search_mode.dart';
import '../../models/user_models.dart';
import '../../services/analytics_service.dart';
import '../controllers.dart';
import '../home/image_source_sheet.dart';

class SocialPlatform {
  const SocialPlatform({
    required this.id,
    required this.icon,
    required this.color,
    required this.domains,
  });

  final String id;
  final IconData icon;
  final Color color;
  final List<String> domains;
}

const socialPlatforms = [
  SocialPlatform(
    id: 'instagram',
    icon: FontAwesomeIcons.instagram,
    color: Color(0xFF222222),
    domains: ['instagram.com'],
  ),
  SocialPlatform(
    id: 'facebook',
    icon: FontAwesomeIcons.facebook,
    color: Color(0xFF1877F2),
    domains: ['facebook.com', 'fb.com'],
  ),
  SocialPlatform(
    id: 'linkedin',
    icon: FontAwesomeIcons.linkedin,
    color: Color(0xFF0A66C2),
    domains: ['linkedin.com'],
  ),
  SocialPlatform(
    id: 'twitter',
    icon: FontAwesomeIcons.twitter,
    color: AppColors.primary,
    domains: ['twitter.com', 'x.com'],
  ),
];

String _platformName(AppLocalizations l10n, String id) {
  switch (id) {
    case 'instagram':
      return l10n.instagram;
    case 'facebook':
      return l10n.facebook;
    case 'linkedin':
      return l10n.linkedin;
    case 'twitter':
      return l10n.twitter;
    default:
      return id;
  }
}

class SocialSearchScreen extends ConsumerWidget {
  const SocialSearchScreen({super.key});

  Future<void> _search(BuildContext context, WidgetRef ref, SocialPlatform platform) async {
    final source = await ImageSourceSheet.show(context);
    if (source == null || !context.mounted) return;

    try {
      if (source == ImageSource.gallery) {
        await ref.read(analyticsServiceProvider).galleryOpened();
      }
      final file = await PickedMedia.pickOriginal(source: source);
      if (file == null || !context.mounted) return;
      await ref.read(analyticsServiceProvider).imageSelected();
      final search = ref.read(searchControllerProvider.notifier);
      search.beginSearch(
        image: PendingImage(localPath: file.path),
        mode: HomeSearchMode.social,
        siteFilter: platform.domains,
      );
      search.scheduleSearch();
      if (context.mounted) context.push('/searching');
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedAppException(AppLocalizations.of(context), error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.page(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.modeSocialTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              l10n.analyzeImageThroughAi,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text(context),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: socialPlatforms.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final platform = socialPlatforms[index];
                return Material(
                  color: AppColors.card(context),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: AppColors.border(context), width: 1.2),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _search(context, ref, platform),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      child: Row(
                        children: [
                          FaIcon(
                            platform.icon,
                            color: platform.id == 'instagram'
                                ? AppColors.text(context)
                                : platform.color,
                            size: 22,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _platformName(l10n, platform.id),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.loadingAd,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
