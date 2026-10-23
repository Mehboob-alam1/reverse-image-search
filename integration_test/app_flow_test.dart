import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reverse_image_search/app/app.dart';
import 'package:reverse_image_search/core/storage/local_storage.dart';
import 'package:reverse_image_search/core/storage/subscription_vault.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch starts at splash then language', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          subscriptionVaultProvider.overrideWithValue(SubscriptionVault.memory()),
        ],
        child: const ReverseImageSearchApp(),
      ),
    );
    expect(find.text('Reverse Image Search'), findsWidgets);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Select Language'), findsOneWidget);
  });
}
