import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/search_debug_log_panel.dart';
import '../../l10n/app_localizations.dart';
import '../controllers.dart';

class SearchingScreen extends ConsumerStatefulWidget {
  const SearchingScreen({super.key});

  @override
  ConsumerState<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends ConsumerState<SearchingScreen> {
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final messagesTicker = Stream<int>.periodic(
      const Duration(milliseconds: 900),
      (i) => i,
    ).take(4);
    final sub = messagesTicker.listen((i) {
      if (mounted) setState(() => _step = i);
    });

    try {
      await ref.read(searchControllerProvider.notifier).search();
    } finally {
      await sub.cancel();
      if (mounted) context.go('/results');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending = ref.watch(searchControllerProvider).pending;
    final steps = [
      l10n.analyzingImage,
      l10n.searchingWeb,
      l10n.findingVisualMatches,
      l10n.findingRelatedResults,
    ];

    return Scaffold(
      backgroundColor: Colors.black,
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
            const ColoredBox(color: Colors.black),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.black87],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                const Spacer(),
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 18),
                Text(
                  steps[_step.clamp(0, steps.length - 1)],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.uploadingSerpApi,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.primary,
                    backgroundColor: Colors.white24,
                  ),
                ),
                const SizedBox(height: 16),
                if (ApiConfig.showSearchDebugLog)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: SearchDebugLogPanel(maxHeight: 200),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
