import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/search_debug_log.dart';

class SearchDebugLogPanel extends ConsumerStatefulWidget {
  const SearchDebugLogPanel({
    super.key,
    this.maxHeight = 220,
    this.darkBackground = true,
  });

  final double maxHeight;
  final bool darkBackground;

  @override
  ConsumerState<SearchDebugLogPanel> createState() => _SearchDebugLogPanelState();
}

class _SearchDebugLogPanelState extends ConsumerState<SearchDebugLogPanel> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _copyAll() async {
    final text = ref.read(searchDebugLogProvider.notifier).fullText;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug log copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(searchDebugLogProvider);
    if (logs.isNotEmpty) _scrollToEnd();

    final bg = widget.darkBackground
        ? Colors.black.withValues(alpha: 0.82)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final fg = widget.darkBackground ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
            child: Row(
              children: [
                Text(
                  'Search debug log',
                  style: TextStyle(
                    color: widget.darkBackground ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.copy, size: 18, color: fg),
                  tooltip: 'Copy log',
                  onPressed: logs.isEmpty ? null : _copyAll,
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: logs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Waiting for events…', style: TextStyle(color: fg, fontSize: 12)),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      return SelectableText(
                        logs[index].formatted,
                        style: TextStyle(
                          color: fg,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          height: 1.35,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
