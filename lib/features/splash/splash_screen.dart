import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/analytics_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: AppConstants.splashDuration,
    )..forward();
    _boot();
  }

  Future<void> _boot() async {
    await ref.read(analyticsServiceProvider).appOpened();
    _timer = Timer(AppConstants.splashDuration, () {
      if (!mounted) return;
      if (GoRouter.maybeOf(context) == null) return;
      final storage = ref.read(localStorageProvider);
      if (!storage.hasSelectedLanguage) {
        context.go('/language');
      } else if (!storage.hasSeenPro) {
        context.go('/pro');
      } else {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const _SearchLogo(),
            const SizedBox(height: 28),
            Text(
              AppLocalizations.of(context).appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              AppLocalizations.of(context).splashAdNotice,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: _progress.value,
                      minHeight: 3,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _SearchLogo extends StatelessWidget {
  const _SearchLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 5),
            ),
            child: ClipOval(
              child: Row(
                children: [
                  Expanded(child: Container(color: const Color(0xFF7ED0A5))),
                  Expanded(child: Container(color: const Color(0xFF2E8B57))),
                ],
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 8,
            child: Transform.rotate(
              angle: 0.7,
              child: SizedBox(
                width: 28,
                height: 7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
