import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchLogEntry {
  const SearchLogEntry({
    required this.time,
    required this.message,
  });

  final DateTime time;
  final String message;

  String get formatted {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '[$h:$m:$s.$ms] $message';
  }
}

final searchDebugLogProvider =
    NotifierProvider<SearchDebugLogController, List<SearchLogEntry>>(
  SearchDebugLogController.new,
);

class SearchDebugLogController extends Notifier<List<SearchLogEntry>> {
  @override
  List<SearchLogEntry> build() => const [];

  void clear() => state = const [];

  void log(String message) {
    final entry = SearchLogEntry(time: DateTime.now(), message: message);
    state = [...state, entry];
    debugPrint('[Search] ${entry.formatted}');
  }

  String get fullText => state.map((e) => e.formatted).join('\n');
}

typedef SearchLogCallback = void Function(String message);
