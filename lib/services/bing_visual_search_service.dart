import 'dart:io';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/api_config.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/url_validator.dart';
import '../models/search_response.dart';
import '../models/search_result.dart';
import '../models/search_type.dart';
import 'search_debug_log.dart';

/// Microsoft Bing Visual Search — uploads the image file directly (no tmpfiles/catbox).
/// https://learn.microsoft.com/en-us/bing/search-apis/bing-visual-search/how-to/get-insights
class BingVisualSearchService {
  BingVisualSearchService({Dio? dio, SearchLogCallback? onLog})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: AppConstants.apiTimeout,
                sendTimeout: const Duration(seconds: 60),
              ),
            ),
        onLog = onLog;

  final Dio _dio;
  final SearchLogCallback? onLog;

  void _log(String message) => onLog?.call(message);

  static bool get isConfigured => ApiConfig.bingVisualSearchKey.isNotEmpty;

  Future<SearchResponse> searchFile({
    required File file,
    required SearchType searchType,
  }) async {
    if (!isConfigured) {
      throw const AppException(
        code: AppErrorCode.unavailable,
        message: 'Bing Visual Search key is not set in api_config.dart',
      );
    }

    final length = await file.length();
    if (length > 1024 * 1024) {
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'Bing requires images under 1 MB. Pick a smaller photo.',
      );
    }

    _log('Bing Visual Search: uploading image bytes (no public URL host)…');
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.bing.microsoft.com/v7.0/images/visualsearch',
        data: FormData.fromMap({
          'image': await MultipartFile.fromFile(
            file.path,
            filename: 'search.jpg',
          ),
        }),
        options: Options(
          headers: {'Ocp-Apim-Subscription-Key': ApiConfig.bingVisualSearchKey},
        ),
      );
      _log('Bing Visual Search: HTTP ${response.statusCode}');
      final raw = response.data ?? const {};
      return _normalize(raw, file.path, searchType);
    } on DioException catch (error) {
      _log('Bing Visual Search failed: ${error.response?.statusCode} ${error.message}');
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        throw const AppException(
          code: AppErrorCode.unauthorized,
          message: 'Bing Visual Search key rejected. Check bingVisualSearchKey.',
        );
      }
      throw AppException(
        code: AppErrorCode.unavailable,
        message: error.message ?? 'Bing Visual Search failed.',
      );
    }
  }

  SearchResponse _normalize(
    Map<String, dynamic> raw,
    String queryImage,
    SearchType searchType,
  ) {
    final visual = <SearchResult>[];
    final exact = <SearchResult>[];
    var index = 0;

    final tags = raw['tags'];
    if (tags is List) {
      for (final tag in tags.whereType<Map>()) {
        final actions = tag['actions'];
        if (actions is! List) continue;
        for (final action in actions.whereType<Map>()) {
          final type = action['actionType']?.toString() ?? '';
          final data = action['data'];
          if (data is! Map) continue;
          final values = data['value'];
          if (values is! List) continue;

          for (final item in values.whereType<Map>()) {
            final map = Map<String, dynamic>.from(item);
            final result = SearchResult(
              id: 'bing_${index++}',
              title: (map['name'] ?? map['text'] ?? 'Match').toString(),
              category: type == 'PagesIncluding' ? 'exact_match' : 'visual_match',
              thumbnail: map['thumbnailUrl']?.toString(),
              imageUrl: map['contentUrl']?.toString() ?? map['thumbnailUrl']?.toString(),
              sourceUrl: map['hostPageUrl']?.toString() ?? map['webSearchUrl']?.toString(),
              sourceDomain: UrlValidator.domainOf(
                map['hostPageUrl']?.toString() ?? map['webSearchUrl']?.toString() ?? '',
              ),
              description: map['datePublished']?.toString(),
            );
            if (result.category == 'exact_match') {
              exact.add(result);
            } else {
              visual.add(result);
            }
          }
        }
      }
    }

    _log(
      'Bing Visual Search counts: visual=${visual.length} exact=${exact.length}',
    );

    return SearchResponse(
      searchId: const Uuid().v4(),
      queryImage: queryImage,
      searchType: searchType,
      results: SearchResultsBundle(
        visualMatches: visual,
        exactMatches: exact,
        products: const [],
      ),
    );
  }
}
