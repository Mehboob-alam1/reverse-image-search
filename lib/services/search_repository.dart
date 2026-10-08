import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_config.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/search_response.dart';
import '../models/search_type.dart';
import 'apify_lens_service.dart';
import 'bing_visual_search_service.dart';
import 'search_debug_log.dart';
import 'serp_api_service.dart';

final serpApiServiceProvider = Provider<SerpApiService>((ref) {
  final logger = ref.read(searchDebugLogProvider.notifier);
  return SerpApiService(onLog: logger.log);
});

final apifyLensServiceProvider = Provider<ApifyLensService>((ref) {
  final logger = ref.read(searchDebugLogProvider.notifier);
  return ApifyLensService(
    serpHosting: ref.watch(serpApiServiceProvider),
    onLog: logger.log,
  );
});

final bingVisualSearchServiceProvider = Provider<BingVisualSearchService>((ref) {
  final logger = ref.read(searchDebugLogProvider.notifier);
  return BingVisualSearchService(onLog: logger.log);
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(
    apify: ref.watch(apifyLensServiceProvider),
    serp: ref.watch(serpApiServiceProvider),
    bing: ref.watch(bingVisualSearchServiceProvider),
    log: ref.read(searchDebugLogProvider.notifier).log,
  );
});

class SearchRepository {
  SearchRepository({
    required ApifyLensService apify,
    required SerpApiService serp,
    required BingVisualSearchService bing,
    required SearchLogCallback log,
  })  : _apify = apify,
        _serpApi = serp,
        _bing = bing,
        _log = log;

  final ApifyLensService _apify;
  final SerpApiService _serpApi;
  final BingVisualSearchService _bing;
  final SearchLogCallback _log;

  Future<SearchResponse> searchByUrl({
    required String url,
    required SearchType searchType,
  }) {
    return _search(
      searchType: searchType,
      apify: () => _apify.searchByUrl(url: url, searchType: searchType),
      serp: () => _serpApi.searchByUrl(url: url, searchType: searchType),
    );
  }

  Future<SearchResponse> searchImage({
    String? imageUrl,
    File? file,
    required SearchType searchType,
  }) async {
    if (file != null && BingVisualSearchService.isConfigured) {
      _log('Using Bing Visual Search (direct upload).');
      try {
        return await _bing.searchFile(file: file, searchType: searchType);
      } on AppException catch (error) {
        _log('Bing failed → next provider: ${error.message}');
      }
    } else if (file != null && ApiConfig.bingVisualSearchKey.isEmpty) {
      _log(
        'Tip: set ApiConfig.bingVisualSearchKey for direct Bing upload (optional).',
      );
    }

    if (file != null) {
      return _search(
        searchType: searchType,
        apify: () => _apify.searchFile(file: file, searchType: searchType),
        serp: () => _serpApi.searchFile(file: file, searchType: searchType),
      );
    }
    return _search(
      searchType: searchType,
      apify: () => _apify.searchByUrl(url: imageUrl ?? '', searchType: searchType),
      serp: () => _serpApi.searchByUrl(url: imageUrl ?? '', searchType: searchType),
    );
  }

  Future<SearchResponse> _search({
    required SearchType searchType,
    required Future<SearchResponse> Function() apify,
    required Future<SearchResponse> Function() serp,
  }) async {
    if (ApifyLensService.isConfigured) {
      _log('SearchRepository: Apify Google Lens (type=${searchType.apiValue}).');
      try {
        return await apify();
      } on AppException catch (error) {
        _log('Apify failed → SerpApi fallback: ${error.message}');
        if (AppEnv.serpApiKey.isEmpty) rethrow;
      }
    } else {
      _log('SearchRepository: SerpApi (no APIFY_TOKEN).');
    }
    return serp();
  }

  Future<SearchResponse> getSearch(String id) async {
    throw UnimplementedError('Saved search lookup is local-only.');
  }
}
