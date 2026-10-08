import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/deferred_app_open.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../controllers.dart';

class _Lang {
  const _Lang(this.code, this.flag, {this.isDefault = false});
  final String code;
  final String flag;
  final bool isDefault;
}

const _languages = [
  _Lang('en', '🇬🇧', isDefault: true),
  _Lang('ar', '🇸🇦'),
  _Lang('de', '🇩🇪'),
  _Lang('it', '🇮🇹'),
  _Lang('fr', '🇫🇷'),
  _Lang('hi', '🇮🇳'),
  _Lang('es', '🇪🇸'),
  _Lang('af', '🇿🇦'),
];

String _languageName(AppLocalizations l10n, String code) {
  switch (code) {
    case 'en':
      return l10n.languageNameEnglish;
    case 'ar':
      return l10n.languageNameArabic;
    case 'de':
      return l10n.languageNameGerman;
    case 'it':
      return l10n.languageNameItalian;
    case 'fr':
      return l10n.languageNameFrench;
    case 'hi':
      return l10n.languageNameHindi;
    case 'es':
      return l10n.languageNameSpanish;
    case 'af':
      return l10n.languageNameAfrikaans;
    default:
      return code;
  }
}

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.fromSettings) {
      scheduleDeferredAppOpen(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: AppColors.page(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.fromSettings || Navigator.of(context).canPop()) {
              context.pop();
            }
          },
        ),
        title: Text(
          l10n.selectLanguageTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                minimumSize: const Size(84, 36),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: const StadiumBorder(),
              ),
              onPressed: () async {
                await ref.read(localeProvider.notifier).setLanguage(selected);
                if (!context.mounted) return;
                if (widget.fromSettings) {
                  context.pop();
                } else if (!ref.read(localStorageProvider).hasSeenPro) {
                  context.go('/pro');
                } else {
                  context.go('/home');
                }
              },
              child: Text(l10n.next),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        itemCount: _languages.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, index) {
          final item = _languages[index];
          final isSelected = selected == item.code;
          final name = _languageName(l10n, item.code);
          return Material(
            color: isSelected ? AppColors.primary : AppColors.card(context),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isSelected ? AppColors.primaryLight : AppColors.border(context),
                width: 1.2,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => ref.read(localeProvider.notifier).setLanguage(item.code),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.flag, style: const TextStyle(fontSize: 28)),
                    const Spacer(),
                    Text(
                      item.isDefault ? '$name ${l10n.languageDefault}' : name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.text(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
