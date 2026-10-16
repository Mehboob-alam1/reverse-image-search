import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/search_stack_config.dart';
import '../core/errors/app_exception.dart';
import '../models/search_response.dart';
import '../models/search_type.dart';
import 'apify_lens_service.dart';
import 'google_lens_search_service.dart';
import 'image_insights_service.dart';
import 'search_debug_log.dart';
import 'temporary_image_host_service.dart';

final temporaryImageHostServiceProvider = Provider<TemporaryImageHostService>((ref) {
  final logger = ref.read(searchDebugLogProvider.notifier);
  return TemporaryImageHostService(onLog: logger.log);
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
    apify: ref.watch(apifyLensServiceProvider),
    freeLens: ref.watch(googleLensSearchServiceProvider),
    insights: ref.watch(imageInsightsServiceProvider),
    log: ref.read(searchDebugLogProvider.notifier).log,
  );
});

class SearchRepository {
  SearchRepository({
    required ApifyLensService apify,
    required GoogleLensSearchService freeLens,
    required ImageInsightsService insights,
    required SearchLogCallback log,
  })  : _apify = apify,
        _freeLens = freeLens,
        _insights = insights,
        _log = log;

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
      apify: () => _apify.searchByUrl(url: url, searchType: searchType),
      freeLens: () => _freeLens.searchByUrl(url: url, searchType: searchType),
    );
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
    final response = await _runMatchSearch(
      searchType: searchType,
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

    return _insights.enrich(
      response: response,
      file: file,
      imageUrl: enrichUrl,
      localeCode: localeCode,
      topResults: response.results.all,
    );
  }

  Future<SearchResponse> _runMatchSearch({
    required SearchType searchType,
    required Future<SearchResponse> Function() apify,
    required Future<SearchResponse> Function() freeLens,
  }) async {
    if (ApifyLensService.isConfigured) {
      _log(
        'Search stack: Apify Google Lens matches + '
        '${SearchStackConfig.insightsOpenAiLabel} insights',
      );
      try {
        final result = await apify();
        if (!result.results.isEmpty) {
          _log(
            'Apify matches: ${result.results.all.length} '
            '(visual=${result.results.visualMatches.length}, '
            'exact=${result.results.exactMatches.length}, '
            'products=${result.results.products.length})',
          );
          return result;
        }
        _log('Apify returned 0 matches — falling back to free Lens + AI.');
      } on AppException catch (error) {
        _log('Apify failed → free Lens fallback: ${error.message}');
      }
    } else {
      _log(
        'No APIFY_TOKEN — in-app match list needs Apify. '
        'Using free Lens link + AI About only.',
      );
    }

    return freeLens();
  }

  Future<SearchResponse> getSearch(String id) async {
    throw UnimplementedError('Saved search lookup is local-only.');
  }
}
