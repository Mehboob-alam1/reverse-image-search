import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/ad_config.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ads/ads_controller.dart';
import '../../services/ads/ads_remote_config.dart';
import '../../services/analytics_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack);
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn);
    _logoCtrl.forward();
    _boot();
  }

  Future<void> _boot() async {
    await ref.read(analyticsServiceProvider).appOpened();
    final started = DateTime.now();

    await ref.read(adsControllerProvider.notifier).bootstrapForSplash();

    AdsRemoteSettings settings;
    try {
      settings = await ref.read(adsRemoteSettingsProvider.future);
    } on Object {
      settings = AdsRemoteSettings.defaults();
    }
    final minSplash = Duration(
      milliseconds: math.max(
        AdConfig.splashMinDuration.inMilliseconds,
        settings.splashMinMs,
      ),
    );
    final elapsed = DateTime.now().difference(started);
    if (elapsed < minSplash) {
      await Future.delayed(minSplash - elapsed);
    }

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
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ads = ref.watch(adsControllerProvider);
    final status = ads.bootstrapMessage.isNotEmpty
        ? ads.bootstrapMessage
        : l10n.splashAdNotice;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.heroGradient,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _AmbientOrbs(pulse: _pulseCtrl),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.72, end: 1).animate(_logoScale),
                        child: const _SplashLogo(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.appName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.chooseLanguageSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const Spacer(flex: 2),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientOrbs extends StatelessWidget {
  const _AmbientOrbs({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = pulse.value;
        return Stack(
          children: [
            Positioned(
              top: -80 + 12 * math.sin(t * math.pi * 2),
              right: -40,
              child: _orb(160, 0.12),
            ),
            Positioned(
              bottom: 120 + 10 * math.cos(t * math.pi * 2),
              left: -60,
              child: _orb(200, 0.1),
            ),
          ],
        );
      },
    );
  }

  Widget _orb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.45),
                blurRadius: 16,
              ),
            ],
          ),
          child: ClipOval(
            child: Row(
              children: [
                Expanded(child: Container(color: AppColors.primaryLight)),
                Expanded(child: Container(color: AppColors.primaryDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
