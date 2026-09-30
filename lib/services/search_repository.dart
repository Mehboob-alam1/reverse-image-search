import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_config.dart';
import '../core/errors/app_exception.dart';
import '../models/search_response.dart';
import '../models/search_type.dart';
import 'bing_visual_search_service.dart';
import 'search_debug_log.dart';
import 'serp_api_service.dart';

final serpApiServiceProvider = Provider<SerpApiService>((ref) {
  final logger = ref.read(searchDebugLogProvider.notifier);
  return SerpApiService(onLog: logger.log);
});

final bingVisualSearchServiceProvider = Provider<BingVisualSearchService>((ref) {
  final logger = ref.read(searchDebugLogProvider.notifier);
  return BingVisualSearchService(onLog: logger.log);
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(
    serp: ref.watch(serpApiServiceProvider),
    bing: ref.watch(bingVisualSearchServiceProvider),
    log: ref.read(searchDebugLogProvider.notifier).log,
  );
});

class SearchRepository {
  SearchRepository({
    required SerpApiService serp,
    required BingVisualSearchService bing,
    required SearchLogCallback log,
  })  : _serpApi = serp,
        _bing = bing,
        _log = log;

  final SerpApiService _serpApi;
  final BingVisualSearchService _bing;
  final SearchLogCallback _log;

  Future<SearchResponse> searchByUrl({
    required String url,
    required SearchType searchType,
  }) {
    return _serpApi.searchByUrl(url: url, searchType: searchType);
  }

  Future<SearchResponse> searchImage({
    String? imageUrl,
    File? file,
    required SearchType searchType,
  }) async {
    if (file != null && BingVisualSearchService.isConfigured) {
      _log('Using Bing Visual Search (direct upload, not SerpApi).');
      try {
        return await _bing.searchFile(file: file, searchType: searchType);
      } on AppException catch (error) {
        _log('Bing failed → falling back to SerpApi: ${error.message}');
      }
    } else if (file != null && ApiConfig.bingVisualSearchKey.isEmpty) {
      _log(
        'Tip: set ApiConfig.bingVisualSearchKey to skip tmpfiles/catbox hosting.',
      );
    }

    if (file != null) {
      _log('SearchRepository: SerpApi file search (upload + lens).');
      return _serpApi.searchFile(file: file, searchType: searchType);
    }
    return _serpApi.searchByUrl(url: imageUrl ?? '', searchType: searchType);
  }

  Future<SearchResponse> getSearch(String id) async {
    throw UnimplementedError('Saved search lookup is local-only.');
  }
}
