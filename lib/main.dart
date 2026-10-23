import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/storage/local_storage.dart';
import 'core/storage/subscription_vault.dart';
import 'services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseOk = await FirebaseBootstrap.ensureInitialized();
  if (firebaseOk) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  final prefs = await SharedPreferences.getInstance();
  final vault = await SubscriptionVault.open(migrateFrom: prefs);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        subscriptionVaultProvider.overrideWithValue(vault),
      ],
      child: const ReverseImageSearchApp(),
    ),
  );
}
