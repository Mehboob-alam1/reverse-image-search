import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/controllers.dart';
import '../l10n/app_localizations.dart';
import 'ads_lifecycle_handler.dart';
import 'routes/app_router.dart';

class ReverseImageSearchApp extends ConsumerWidget {
  const ReverseImageSearchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return AdsLifecycleHandler(
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        locale: locale,
        localeResolutionCallback: (chosen, supported) {
          if (chosen == null) return supported.first;
          for (final item in supported) {
            if (item.languageCode == chosen.languageCode) return item;
          }
          return const Locale('en');
        },
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
