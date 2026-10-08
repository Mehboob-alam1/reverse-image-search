import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/apify_config.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/url_validator.dart';
import '../models/search_response.dart';
import '../models/search_result.dart';
import '../models/search_type.dart';
import 'search_debug_log.dart';
import 'serp_api_service.dart';

class ApifyLensService {
  ApifyLensService({
    required SerpApiService serpHosting,
    Dio? dio,
    SearchLogCallback? onLog,
  })  : _serpHosting = serpHosting,
        onLog = onLog,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: ApifyConfig.actorTimeout,
                sendTimeout: ApifyConfig.actorTimeout,
              ),
            );

  final Dio _dio;
  final SerpApiService _serpHosting;
  final SearchLogCallback? onLog;

  static bool get isConfigured => AppEnv.apifyToken.isNotEmpty;

  void _log(String message) => onLog?.call(message);

  Future<SearchResponse> searchByUrl({
    required String url,
    required SearchType searchType,
  }) async {
    final imageUrl = url.trim();
    if (!UrlValidator.isValidHttpUrl(imageUrl)) {
      throw const AppException(
        code: AppErrorCode.validation,
        message: 'Please enter a valid image URL.',
      );
    }
    _log('Apify: image URL search');
    return _searchWithImageReference(
      imageUrl: imageUrl,
      searchType: searchType,
    );
  }

  Future<SearchResponse> searchFile({
    required File file,
    required SearchType searchType,
  }) async {
    final bytes = await file.readAsBytes();
    _log('Apify: local file ${file.path} (${bytes.length} bytes)');

    if (bytes.length <= ApifyConfig.maxBase64Bytes) {
      try {
        return await _searchWithImageReference(
          imageBase64: base64Encode(bytes),
          searchType: searchType,
          queryImageLabel: file.path,
        );
      } on AppException catch (error) {
        _log('Apify base64 run failed: ${error.message}');
      }
    } else {
      _log('Apify: file large — hosting public URL first…');
    }

    final hosted = await _serpHosting.hostTemporaryImage(file);
    return _searchWithImageReference(
      imageUrl: hosted,
      searchType: searchType,
      queryImageLabel: hosted,
    );
  }

  Future<SearchResponse> _searchWithImageReference({
    String? imageUrl,
    String? imageBase64,
    required SearchType searchType,
    String? queryImageLabel,
  }) async {
    final hasUrl = imageUrl != null && imageUrl.isNotEmpty;
    final hasB64 = imageBase64 != null && imageBase64.isNotEmpty;
    if (hasUrl == hasB64) {
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'Missing image for Apify search.',
      );
    }
    _assertToken();
    final types = _apifySearchTypes(searchType);
    _log('Apify actor ${ApifyConfig.googleLensActorId} modes: ${types.join(', ')}');

    final futures = types.map(
      (type) => _runActor(
        imageUrl: imageUrl,
        imageBase64: imageBase64,
        searchType: type,
      ),
    );
    final batches = await Future.wait(futures);

    final visual = <SearchResult>[];
    final exact = <SearchResult>[];
    final products = <SearchResult>[];

    for (var i = 0; i < types.length; i++) {
      final type = types[i];
      final rows = batches[i];
      for (final row in rows) {
        if (row['resultType']?.toString() == 'error') {
          _log('Apify error row: ${row['error'] ?? row['message']}');
          continue;
        }
        final item = _mapRow(row, type);
        switch (type) {
          case 'visual_matches':
            visual.add(item);
          case 'exact_matches':
            exact.add(item);
          case 'products':
            products.add(item);
          default:
            visual.add(item);
        }
      }
    }

    final queryImage = queryImageLabel ?? imageUrl ?? 'local://upload';
    final response = SearchResponse(
      searchId: const Uuid().v4(),
      queryImage: imageBase64 != null ? 'local://upload' : queryImage,
      searchType: searchType,
      results: SearchResultsBundle(
        visualMatches: visual,
        exactMatches: exact,
        products: products,
      ),
    );
    _log(
      'Apify done: visual=${visual.length} exact=${exact.length} products=${products.length}',
    );
    return response;
  }

  List<String> _apifySearchTypes(SearchType type) {
    return switch (type) {
      SearchType.visualMatches => ['visual_matches'],
      SearchType.exactMatches => ['exact_matches'],
      SearchType.products => ['products'],
      SearchType.aboutThisImage => ['visual_matches'],
      SearchType.all => ['visual_matches', 'exact_matches', 'products'],
    };
  }

  Future<List<Map<String, dynamic>>> _runActor({
    String? imageUrl,
    String? imageBase64,
    required String searchType,
  }) async {
    final url =
        'https://api.apify.com/v2/acts/${ApifyConfig.googleLensActorId}/run-sync-get-dataset-items';
    _log('Apify run-sync: $searchType…');
    try {
      final response = await _dio.post<List<dynamic>>(
        url,
        queryParameters: {'token': AppEnv.apifyToken},
        data: {
          if (imageBase64 != null && imageBase64.isNotEmpty)
            'image_base64': imageBase64
          else
            'image_url': imageUrl,
          'search_type': searchType,
          'max_results': ApifyConfig.defaultMaxResults,
        },
        options: Options(
          receiveTimeout: ApifyConfig.actorTimeout,
          sendTimeout: ApifyConfig.actorTimeout,
        ),
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        final detail = response.data?.toString() ?? 'HTTP $status';
        throw AppException(
          code: AppErrorCode.unavailable,
          message: 'Apify search failed ($detail)',
        );
      }
      final list = response.data ?? const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (error) {
      final msg = error.response?.data?.toString() ?? error.message ?? 'Network error';
      throw AppException(
        code: AppErrorCode.network,
        message: 'Apify: $msg',
      );
    }
  }

  SearchResult _mapRow(Map<String, dynamic> row, String searchType) {
    final position = row['position']?.toString() ?? '0';
    final category = switch (searchType) {
      'exact_matches' => 'exact_match',
      'products' => 'product',
      _ => 'visual_match',
    };
    final price = row['price'];
    return SearchResult(
      id: 'apify_${category}_$position',
      title: row['title']?.toString() ??
          row['source']?.toString() ??
          'Web match',
      category: category,
      thumbnail: row['thumbnail']?.toString(),
      imageUrl: row['image']?.toString() ?? row['thumbnail']?.toString(),
      sourceUrl: row['url']?.toString(),
      sourceDomain: row['source']?.toString(),
      description: row['title']?.toString(),
      price: price?.toString(),
      currency: row['currency']?.toString(),
    );
  }

  String _mimeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _assertToken() {
    if (!isConfigured) {
      throw const AppException(
        code: AppErrorCode.unavailable,
        message: 'Apify token missing. Set APIFY_TOKEN via --dart-define.',
      );
    }
  }
}
