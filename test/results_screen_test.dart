import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reverse_image_search/core/storage/local_storage.dart';
import 'package:reverse_image_search/core/storage/subscription_vault.dart';
import 'package:reverse_image_search/features/controllers.dart';
import 'package:reverse_image_search/features/results/results_screen.dart';
import 'package:reverse_image_search/l10n/app_localizations.dart';
import 'package:reverse_image_search/models/favorite_item.dart';
import 'package:reverse_image_search/models/search_response.dart';

class _EmptyFavorites extends FavoritesController {
  @override
  Future<List<FavoriteItem>> build() async => [];
}

class _SeededSearch extends SearchController {
  _SeededSearch(this.response);
  final SearchResponse response;

  @override
  SearchSession build() => SearchSession(response: response);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('results screen shows visual match title', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final json = jsonDecode(File('test/fixtures/visual_matches.json').readAsStringSync())
        as Map<String, dynamic>;
    final response = SearchResponse.fromJson(json);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          subscriptionVaultProvider.overrideWithValue(SubscriptionVault.memory()),
          favoritesControllerProvider.overrideWith(_EmptyFavorites.new),
          searchControllerProvider.overrideWith(() => _SeededSearch(response)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ResultsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Search Results'), findsOneWidget);
    expect(find.text('Example Image'), findsOneWidget);
  });
}
