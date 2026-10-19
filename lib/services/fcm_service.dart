import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firebase/firebase_bootstrap.dart';
import 'analytics_service.dart';

/// Top-level background handler (must not be a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseBootstrap.ensureInitialized();
  debugPrint('FCM background: ${message.messageId} ${message.notification?.title}');
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(analytics: ref.read(analyticsServiceProvider));
});

class FcmService {
  FcmService({required AnalyticsService analytics}) : _analytics = analytics;

  final AnalyticsService _analytics;
  String? _token;

  String? get token => _token;

  Future<void> initialize() async {
    if (kIsWeb || !FirebaseBootstrap.ready) return;

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    if (Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'FCM foreground: ${message.notification?.title} / ${message.notification?.body}',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM opened app: ${message.data}');
    });

    messaging.onTokenRefresh.listen((token) async {
      _token = token;
      await _analytics.fcmTokenRefreshed();
      debugPrint('FCM token refresh: $token');
    });

    try {
      _token = await messaging.getToken();
      debugPrint('FCM token: $_token');
    } on Object catch (e) {
      debugPrint('FCM getToken failed: $e');
    }
  }
}
