import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reverse_image_search/core/storage/local_storage.dart';
import 'package:reverse_image_search/core/storage/subscription_vault.dart';
import 'package:reverse_image_search/core/theme/app_theme.dart';
import 'package:reverse_image_search/features/controllers.dart';
import 'package:reverse_image_search/features/home/home_screen.dart';
import 'package:reverse_image_search/features/language/language_screen.dart';
import 'package:reverse_image_search/features/search/social_search_screen.dart';
import 'package:reverse_image_search/features/splash/splash_screen.dart';
import 'package:reverse_image_search/features/subscription/pro_screen.dart';
import 'package:reverse_image_search/l10n/app_localizations.dart';
import 'package:reverse_image_search/models/search_history_item.dart';
import 'package:reverse_image_search/models/favorite_item.dart';

class _EmptyHistory extends HistoryController {
  @override
  Future<List<SearchHistoryItem>> build() async => [];
}

class _EmptyFavorites extends FavoritesController {
  @override
  Future<List<FavoriteItem>> build() async => [];
}

class _QuietIap extends IapController {
  @override
  IapState build() => const IapState(available: false, loading: false);
}

Widget _wrap(Widget child, SharedPreferences prefs) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      subscriptionVaultProvider.overrideWithValue(SubscriptionVault.memory()),
      historyControllerProvider.overrideWith(_EmptyHistory.new),
      favoritesControllerProvider.overrideWith(_EmptyFavorites.new),
      iapControllerProvider.overrideWith(_QuietIap.new),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash shows app name and tagline', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(const SplashScreen(), prefs));
    expect(find.text('Deep Image Search'), findsOneWidget);
    expect(find.text('This action may perform an ad'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('language screen lists languages', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(const LanguageScreen(), prefs));
    expect(find.text('Select Language'), findsOneWidget);
    expect(find.text('English (Default)'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('pro screen always offers continue with free', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(const ProScreen(), prefs));
    expect(find.text('UNLOCK ALL FEATURES'), findsOneWidget);
    expect(find.textContaining('CONTINUE FOR FREE'), findsOneWidget);
  });

  testWidgets('home shows search tiles', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(const HomeScreen(), prefs));
    expect(find.textContaining('Who are you'), findsOneWidget);
    expect(find.text('AI Face Analysis'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Search from Web'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Search from Web'), findsOneWidget);
  });

  testWidgets('drawer matches sidebar items', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(const HomeScreen(), prefs));
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Share App'), findsOneWidget);
    expect(find.text('Select Language'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('More Apps'), findsOneWidget);
    expect(find.text('Rate Us'), findsOneWidget);
    expect(find.text('Community Guidelines'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);
  });

  testWidgets('social media search lists platforms', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(const SocialSearchScreen(), prefs));
    expect(find.text('Social Media Deep Search'), findsOneWidget);
    expect(find.text('Analyze your image through AI.'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('LinkedIn'), findsOneWidget);
    expect(find.text('Twitter'), findsOneWidget);
  });
}
