import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/native_ad_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ads/ads_controller.dart';
import '../controllers.dart';

class SearchingScreen extends ConsumerStatefulWidget {
  const SearchingScreen({super.key});

  @override
  ConsumerState<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends ConsumerState<SearchingScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  StreamSubscription<int>? _stepSub;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _stepSub = Stream<int>.periodic(
      const Duration(milliseconds: 1100),
      (i) => i,
    ).take(4).listen((i) {
      if (mounted) setState(() => _step = i);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(searchControllerProvider.notifier).scheduleSearch();
    });
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SearchSession>(searchControllerProvider, (prev, next) {
      final done = !next.loading &&
          (next.response != null || next.error != null);
      if (!done) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (next.response != null) {
          await ref.read(adsControllerProvider.notifier).showInterstitialAfterSearch();
        }
        if (!mounted) return;
        context.go('/results');
      });
    });

    final l10n = AppLocalizations.of(context);
    final pending = ref.watch(searchControllerProvider).pending;
    final steps = [
      l10n.analyzingImage,
      l10n.searchingWeb,
      l10n.findingVisualMatches,
      l10n.findingRelatedResults,
    ];
    final stepLabel = steps[_step.clamp(0, steps.length - 1)];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const NativeAdBar(key: ValueKey('native-searching')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (pending != null)
            ImagePreview(
              filePath: pending.localPath,
              networkUrl: pending.remoteUrl,
              expand: true,
              radius: 0,
            )
          else
            const ColoredBox(color: AppColors.darkBackground),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryDark.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      children: [
                        if (pending != null) ...[
                          ScaleTransition(
                            scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                              CurvedAnimation(
                                parent: _pulseCtrl,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: SizedBox(
                              width: 132,
                              height: 132,
                              child: ClipOval(
                                child: ImagePreview(
                                  filePath: pending.localPath,
                                  networkUrl: pending.remoteUrl,
                                  height: 132,
                                  radius: 0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          stepLabel,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.uploadingSerpApi,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SearchStepRow(current: _step, labels: steps),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchStepRow extends StatelessWidget {
  const _SearchStepRow({required this.current, required this.labels});

  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (index) {
          final done = index < current;
          final active = index == current;
          return Padding(
            padding: EdgeInsets.only(bottom: index == labels.length - 1 ? 0 : 8),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? AppColors.secondary
                        : active
                            ? Colors.white
                            : Colors.white24,
                  ),
                  child: Icon(
                    done ? Icons.check : Icons.circle,
                    size: done ? 14 : 6,
                    color: done || active ? AppColors.primaryDark : Colors.white54,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    labels[index],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white70,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
