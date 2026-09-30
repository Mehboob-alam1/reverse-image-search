import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/local_storage.dart';
import '../../features/home/home_screen.dart';
import '../../features/language/language_screen.dart';
import '../../features/legal/community_screen.dart';
import '../../features/legal/privacy_screen.dart';
import '../../features/results/result_details_screen.dart';
import '../../features/results/results_screen.dart';
import '../../features/search/searching_screen.dart';
import '../../features/search/social_search_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/subscription/pro_screen.dart';
import '../../models/search_result.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(localStorageProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/language', builder: (_, _) => const LanguageScreen()),
      GoRoute(path: '/pro', builder: (_, _) => const ProScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/social-search', builder: (_, _) => const SocialSearchScreen()),
      GoRoute(
        path: '/searching',
        builder: (_, _) => const SearchingScreen(),
      ),
      GoRoute(path: '/results', builder: (_, _) => const ResultsScreen()),
      GoRoute(
        path: '/result-details',
        builder: (_, state) => ResultDetailsScreen(result: state.extra as SearchResult),
      ),
      GoRoute(
        path: '/language-settings',
        builder: (_, _) => const LanguageScreen(fromSettings: true),
      ),
      GoRoute(
        path: '/subscription',
        builder: (_, _) => const ProScreen(fromSettings: true),
      ),
      GoRoute(path: '/privacy', builder: (_, _) => const PrivacyScreen()),
      GoRoute(path: '/community', builder: (_, _) => const CommunityScreen()),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/') return null;
      if (!storage.hasSelectedLanguage && loc != '/language') {
        return '/language';
      }
      if (loc == '/language') return null;
      if (!storage.hasSeenPro && loc != '/pro') {
        return '/pro';
      }
      return null;
    },
  );
});
