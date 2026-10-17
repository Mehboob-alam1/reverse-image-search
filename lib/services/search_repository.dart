import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/search_stack_config.dart';
import '../core/errors/app_exception.dart';
import '../models/search_response.dart';
import '../models/search_type.dart';
import 'apify_lens_service.dart';
import 'google_lens_search_service.dart';
import 'image_insights_service.dart';
import 'railway_search_service.dart';
import 'search_debug_log.dart';
import 'temporary_image_host_service.dart';

final temporaryImageHostServiceProvider = Provider<TemporaryImageHostService>((ref) {
  final logger = ref.read(searchDebugLogProvider.notifier);
  return TemporaryImageHostService(onLog: logger.log);
});

final railwaySearchServiceProvider = Provider<RailwaySearchService>((ref) {
  final logger = ref.read(searchDebugLogProvider.notifier);
  return RailwaySearchService(onLog: logger.log);
});

final apifyLensServiceProvider = Provider<ApifyLensService>((ref) {
  final logger = ref.read(searchDebugLogProvider.notifier);
  return ApifyLensService(
    imageHost: ref.watch(temporaryImageHostServiceProvider),
    onLog: logger.log,
  );
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
    railway: ref.watch(railwaySearchServiceProvider),
    apify: ref.watch(apifyLensServiceProvider),
    freeLens: ref.watch(googleLensSearchServiceProvider),
    insights: ref.watch(imageInsightsServiceProvider),
    log: ref.read(searchDebugLogProvider.notifier).log,
  );
});

class SearchRepository {
  SearchRepository({
    required RailwaySearchService railway,
    required ApifyLensService apify,
    required GoogleLensSearchService freeLens,
    required ImageInsightsService insights,
    required SearchLogCallback log,
  })  : _railway = railway,
        _apify = apify,
        _freeLens = freeLens,
        _insights = insights,
        _log = log;

  final RailwaySearchService _railway;
  final ApifyLensService _apify;
  final GoogleLensSearchService _freeLens;
  final ImageInsightsService _insights;
  final SearchLogCallback _log;

  Future<SearchResponse> searchByUrl({
    required String url,
    required SearchType searchType,
    String localeCode = 'en',
  }) async {
    final response = await _runMatchSearch(
      searchType: searchType,
      railway: () => _railway.searchByUrl(url: url, searchType: searchType),
      apify: () => _apify.searchByUrl(url: url, searchType: searchType),
      freeLens: () => _freeLens.searchByUrl(url: url, searchType: searchType),
    );
    return _maybeEnrich(
      response: response,
      imageUrl: url,
      localeCode: localeCode,
    );
  }

  Future<SearchResponse> searchImage({
    String? imageUrl,
    File? file,
    required SearchType searchType,
    String localeCode = 'en',
  }) async {
    final response = await _runMatchSearch(
      searchType: searchType,
      railway: () {
        if (file != null) {
          return _railway.searchFile(file: file, searchType: searchType);
        }
        return _railway.searchByUrl(url: imageUrl ?? '', searchType: searchType);
      },
      apify: () {
        if (file != null) {
          return _apify.searchFile(file: file, searchType: searchType);
        }
        return _apify.searchByUrl(url: imageUrl ?? '', searchType: searchType);
      },
      freeLens: () {
        if (file != null) {
          return _freeLens.searchFile(file: file, searchType: searchType);
        }
        return _freeLens.searchByUrl(url: imageUrl ?? '', searchType: searchType);
      },
    );

    final enrichUrl = response.queryImage.startsWith('http')
        ? response.queryImage
        : imageUrl;

    return _maybeEnrich(
      response: response,
      file: file,
      imageUrl: enrichUrl,
      localeCode: localeCode,
    );
  }

  /// Skip OpenAI when Railway already returned analysis (saves cost).
  Future<SearchResponse> _maybeEnrich({
    required SearchResponse response,
    File? file,
    String? imageUrl,
    required String localeCode,
  }) async {
    final about = response.results.aboutImage;
    final hasApiAnalysis = about != null &&
        ((about.summary != null && about.summary!.isNotEmpty) ||
            about.relatedSearches.isNotEmpty);
    if (hasApiAnalysis) {
      _log('Skipping GPT enrich — Railway analysis already present.');
      return response;
    }
    return _insights.enrich(
      response: response,
      file: file,
      imageUrl: imageUrl,
      localeCode: localeCode,
      topResults: response.results.all,
    );
  }

  Future<SearchResponse> _runMatchSearch({
    required SearchType searchType,
    required Future<SearchResponse> Function() railway,
    required Future<SearchResponse> Function() apify,
    required Future<SearchResponse> Function() freeLens,
  }) async {
    _log('Search stack: Railway reverse-image API (primary)…');
    try {
      final result = await railway();
      if (!result.results.isEmpty || (result.results.aboutImage?.hasContent ?? false)) {
        _log(
          'Railway matches: ${result.results.all.length} '
          '(exact=${result.results.exactMatches.length}, '
          'visual=${result.results.visualMatches.length})',
        );
        return result;
      }
      _log('Railway returned empty — trying fallbacks…');
    } on AppException catch (error) {
      _log('Railway failed → fallback: ${error.message}');
    }

    if (ApifyLensService.isConfigured) {
      _log('Fallback: Apify Google Lens…');
      try {
        final result = await apify();
        if (!result.results.isEmpty) return result;
      } on AppException catch (error) {
        _log('Apify failed: ${error.message}');
      }
    }

    _log('Fallback: free Lens prepare + ${SearchStackConfig.insightsOpenAiLabel}');
    return freeLens();
  }

  Future<SearchResponse> getSearch(String id) async {
    throw UnimplementedError('Saved search lookup is local-only.');
  }
}
