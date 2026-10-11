import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/search_stack_config.dart';
import '../models/search_response.dart';
import '../models/search_type.dart';
import 'google_lens_search_service.dart';
import 'image_insights_service.dart';
import 'search_debug_log.dart';
import 'temporary_image_host_service.dart';

final temporaryImageHostServiceProvider = Provider<TemporaryImageHostService>((ref) {
  final logger = ref.read(searchDebugLogProvider.notifier);
  return TemporaryImageHostService(onLog: logger.log);
});

final googleLensSearchServiceProvider = Provider<GoogleLensSearchService>((ref) {
  final logger = ref.read(searchDebugLogProvider.notifier);
  return GoogleLensSearchService(
    imageHost: ref.watch(temporaryImageHostServiceProvider),
    onLog: logger.log,
  );
});

final imageInsightsServiceProvider = Provider<ImageInsightsService>((ref) {
  final logger = ref.read(searchDebugLogProvider.notifier);
  return ImageInsightsService(onLog: logger.log);
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(
    lens: ref.watch(googleLensSearchServiceProvider),
    insights: ref.watch(imageInsightsServiceProvider),
    log: ref.read(searchDebugLogProvider.notifier).log,
  );
});

class SearchRepository {
  SearchRepository({
    required GoogleLensSearchService lens,
    required ImageInsightsService insights,
    required SearchLogCallback log,
  })  : _lens = lens,
        _insights = insights,
        _log = log;

  final GoogleLensSearchService _lens;
  final ImageInsightsService _insights;
  final SearchLogCallback _log;

  Future<SearchResponse> searchByUrl({
    required String url,
    required SearchType searchType,
    String localeCode = 'en',
  }) async {
    _log(
      'Search stack: free ${SearchStackConfig.lensEngineLabel} + '
      '${SearchStackConfig.insightsOpenAiLabel} / ${SearchStackConfig.insightsQwenLabel}',
    );
    if (!AppEnv.useAiInsights) {
      _log('Tip: set OPENAI_API_KEY or QWEN_API_KEY for in-app About insights.');
    }
    final response = await _lens.searchByUrl(url: url, searchType: searchType);
    return _insights.enrich(
      response: response,
      imageUrl: url,
      localeCode: localeCode,
      topResults: response.results.all,
    );
  }

  Future<SearchResponse> searchImage({
    String? imageUrl,
    File? file,
    required SearchType searchType,
    String localeCode = 'en',
  }) async {
    _log(
      'Search stack: free ${SearchStackConfig.lensEngineLabel} + AI insights',
    );
    final response = file != null
        ? await _lens.searchFile(file: file, searchType: searchType)
        : await _lens.searchByUrl(url: imageUrl ?? '', searchType: searchType);

    final enrichUrl = response.queryImage.startsWith('http')
        ? response.queryImage
        : imageUrl;

    return _insights.enrich(
      response: response,
      file: file,
      imageUrl: enrichUrl,
      localeCode: localeCode,
      topResults: response.results.all,
    );
  }

  Future<SearchResponse> getSearch(String id) async {
    throw UnimplementedError('Saved search lookup is local-only.');
  }
}
