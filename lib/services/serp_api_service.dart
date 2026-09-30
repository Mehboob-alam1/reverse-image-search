import 'dart:async';
import 'dart:convert';
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

class SerpApiService {
  SerpApiService({Dio? dio, Dio? uploadDio, SearchLogCallback? onLog})
      : onLog = onLog,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: AppConstants.apiTimeout,
                sendTimeout: AppConstants.apiTimeout,
              ),
            ),
        _uploadDio = uploadDio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 45),
                sendTimeout: const Duration(seconds: 90),
              ),
            );

  final Dio _dio;
  final Dio _uploadDio;
  final SearchLogCallback? onLog;

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
    _log('Input: using image URL (no upload): $imageUrl');
    return _performImageSearch(imageUrl: imageUrl, searchType: searchType);
  }

  Future<SearchResponse> searchFile({
    required File file,
    required SearchType searchType,
  }) async {
    _log(
      'Reading local file on device: ${file.path} (${await file.length()} bytes)',
    );
    final hostedUrl = await _hostTemporaryImage(file);
    return _performImageSearch(imageUrl: hostedUrl, searchType: searchType);
  }

  /// SerpApi [Google Reverse Image](https://serpapi.com/google-reverse-image) first,
  /// then [Google Lens](https://serpapi.com/google-lens-api) if needed.
  Future<SearchResponse> _performImageSearch({
    required String imageUrl,
    required SearchType searchType,
  }) async {
    _assertSerpApiKey();
    _log('SerpApi key: configured (${AppEnv.serpApiKey.length} characters)');
    AppException? reverseFailure;
    try {
      final reverse = await _fetchGoogleReverseImage(
        imageUrl: imageUrl,
        searchType: searchType,
      );
      _logResultCounts('google_reverse_image', reverse);
      if (!reverse.results.isEmpty) {
        _log('Done: using Google Reverse Image results.');
        return reverse;
      }
      _log('google_reverse_image returned no matches; trying Google Lens…');
    } on AppException catch (error) {
      reverseFailure = error;
      _log('google_reverse_image failed: ${error.message}');
    }
    try {
      final lens = await _fetchGoogleLens(imageUrl: imageUrl, searchType: searchType);
      _logResultCounts('google_lens', lens);
      _log('Done: using Google Lens results.');
      return lens;
    } on AppException catch (error) {
      _log('google_lens failed: ${error.message}');
      if (reverseFailure != null) throw reverseFailure;
      rethrow;
    }
  }

  void _logResultCounts(String engine, SearchResponse response) {
    final r = response.results;
    _log(
      '$engine counts: visual=${r.visualMatches.length} '
      'exact=${r.exactMatches.length} products=${r.products.length} '
      'about=${r.aboutImage?.hasContent == true}',
    );
  }

  void _assertSerpApiKey() {
    if (AppEnv.serpApiKey.isEmpty) {
      throw const AppException(
        code: AppErrorCode.unavailable,
        message: 'SerpApi key is missing. Pass --dart-define=SERPAPI_KEY=your_key',
      );
    }
  }

  Future<SearchResponse> _fetchGoogleReverseImage({
    required String imageUrl,
    required SearchType searchType,
  }) async {
    final raw = await _serpGet(
      queryParameters: {
        'engine': 'google_reverse_image',
        'image_url': imageUrl,
      },
    );
    return normalizeReverseImage(raw, imageUrl, searchType);
  }

  Future<SearchResponse> _fetchGoogleLens({
    required String imageUrl,
    required SearchType searchType,
  }) async {
    final raw = await _serpGet(
      queryParameters: {
        'engine': 'google_lens',
        'url': imageUrl,
        if (searchType != SearchType.all &&
            searchType != SearchType.aboutThisImage)
          'type': searchType.apiValue,
      },
    );
    return normalize(raw, imageUrl, searchType);
  }

  Future<Map<String, dynamic>> _serpGet({
    required Map<String, dynamic> queryParameters,
  }) async {
    final engine = queryParameters['engine'];
    final imageRef =
        queryParameters['image_url'] ?? queryParameters['url'] ?? '';
    _log('SerpApi request: engine=$engine');
    _log('SerpApi image URL: $imageRef');
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://serpapi.com/search.json',
        queryParameters: {
          ...queryParameters,
          'api_key': AppEnv.serpApiKey,
        },
      );
      final raw = response.data ?? const {};
      final meta = raw['search_metadata'];
      if (meta is Map) {
        _log(
          'SerpApi response: HTTP ${response.statusCode} '
          'id=${meta['id']} status=${meta['status']}',
        );
      } else {
        _log('SerpApi response: HTTP ${response.statusCode}');
      }
      _throwIfSerpError(raw);
      return raw;
    } on DioException catch (error) {
      _log('SerpApi HTTP error: ${error.response?.statusCode ?? '—'} ${error.message}');
      final body = error.response?.data;
      if (body is Map<String, dynamic>) {
        _throwIfSerpError(body);
      }
      throw _mapDioError(error);
    }
  }

  AppException _mapDioError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) {
      return const AppException(
        code: AppErrorCode.unauthorized,
        message: 'SerpApi rejected the request. Check SERPAPI_KEY.',
      );
    }
    if (status == 429) {
      return const AppException(
        code: AppErrorCode.rateLimit,
        message: 'Search limit reached.',
      );
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const AppException(
        code: AppErrorCode.network,
        message: 'Please check your connection and try again.',
      );
    }
    return AppException(
      code: AppErrorCode.unavailable,
      message: error.message ?? 'Search service is temporarily unavailable.',
    );
  }

  void _throwIfSerpError(Map<String, dynamic> raw) {
    final error = raw['error']?.toString();
    if (error == null || error.isEmpty) return;
    final lower = error.toLowerCase();
    if (lower.contains('invalid api key') || lower.contains('api key')) {
      throw AppException(
        code: AppErrorCode.unauthorized,
        message: error,
      );
    }
    throw AppException(
      code: AppErrorCode.unavailable,
      message: error,
    );
  }

  Future<String> _hostTemporaryImage(File file) async {
    final filename = file.uri.pathSegments.isEmpty
        ? 'search.jpg'
        : file.uri.pathSegments.last;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'The selected image is empty.',
      );
    }

    if (ApiConfig.imgBbApiKey.isNotEmpty) {
      _log('Upload: trying ImgBB first…');
      try {
        final url = await _uploadImgBb(bytes, filename).timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw const AppException(
            code: AppErrorCode.network,
            message: 'ImgBB upload timed out.',
          ),
        );
        _log('Upload: public image URL → $url');
        return url;
      } on AppException catch (error) {
        _log('Upload: ImgBB failed (${error.message}), trying other hosts…');
      }
    }

    _log('Upload: ${bytes.length} bytes as "$filename" → tmpfiles / catbox / 0x0.st (parallel)');

    final uploads = <Future<String>>[
      _uploadTmpFiles(bytes, filename),
      _uploadCatbox(bytes, filename),
      _uploadZeroX(bytes, filename),
    ];

    try {
      final url = await _firstSuccessfulUpload(uploads);
      _log('Upload: public image URL → $url');
      return url;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'Unable to prepare this image for search. Check your connection.',
      );
    }
  }

  Future<String> _firstSuccessfulUpload(List<Future<String>> uploads) async {
    final completer = Completer<String>();
    var failures = 0;
    AppException? lastError;

    for (final upload in uploads) {
      upload.then((url) {
        if (completer.isCompleted) return;
        if (UrlValidator.isValidHttpUrl(url)) {
          completer.complete(url);
        } else {
          failures++;
          lastError = const AppException(
            code: AppErrorCode.invalidImage,
            message: 'Unable to upload this gallery image.',
          );
          if (failures == uploads.length) {
            completer.completeError(lastError!);
          }
        }
      }).catchError((Object error) {
        failures++;
        _log('Upload host failed ($failures/${uploads.length}): $error');
        if (error is AppException) {
          lastError = error;
        } else {
          lastError = const AppException(
            code: AppErrorCode.invalidImage,
            message: 'Unable to upload this gallery image.',
          );
        }
        if (failures == uploads.length && !completer.isCompleted) {
          completer.completeError(
            lastError ??
                const AppException(
                  code: AppErrorCode.invalidImage,
                  message: 'Unable to prepare this image for search.',
                ),
          );
        }
      });
    }

    return completer.future.timeout(
      const Duration(seconds: 25),
      onTimeout: () => throw const AppException(
        code: AppErrorCode.network,
        message: 'Image upload timed out. Add bingVisualSearchKey or imgBbApiKey in api_config.dart.',
      ),
    );
  }

  Future<String> _uploadImgBb(List<int> bytes, String filename) async {
    _log('Upload [api.imgbb.com]: sending…');
    final response = await _uploadDio.post<Map<String, dynamic>>(
      'https://api.imgbb.com/1/upload',
      queryParameters: {'key': ApiConfig.imgBbApiKey},
      data: FormData.fromMap({'image': base64Encode(bytes)}),
    );
    final data = response.data?['data'];
    if (data is! Map) {
      _log('Upload [api.imgbb.com]: invalid response');
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'ImgBB upload failed.',
      );
    }
    final map = Map<String, dynamic>.from(data);
    final url = map['image'] is Map
        ? (map['image'] as Map)['url']?.toString()
        : map['url']?.toString() ?? map['display_url']?.toString();
    if (url == null || !url.startsWith('http')) {
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'ImgBB upload failed.',
      );
    }
    _log('Upload [api.imgbb.com]: OK');
    return url;
  }

  Future<String> _uploadCatbox(List<int> bytes, String filename) async {
    _log('Upload [catbox.moe]: sending…');
    final response = await _uploadDio.post<String>(
      'https://catbox.moe/user/api.php',
      data: FormData.fromMap({
        'reqtype': 'fileupload',
        'fileToUpload': MultipartFile.fromBytes(bytes, filename: filename),
      }),
      options: Options(responseType: ResponseType.plain),
    );
    final url = response.data?.trim() ?? '';
    if (!url.startsWith('http')) {
      _log('Upload [catbox.moe]: invalid response');
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'Unable to upload this gallery image.',
      );
    }
    _log('Upload [catbox.moe]: OK');
    return url;
  }

  Future<String> _uploadTmpFiles(List<int> bytes, String filename) async {
    _log('Upload [tmpfiles.org]: sending…');
    final response = await _uploadDio.post<Map<String, dynamic>>(
      'https://tmpfiles.org/api/v1/upload',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    final url = response.data?['data']?['url']?.toString() ?? '';
    if (url.isEmpty) {
      _log('Upload [tmpfiles.org]: empty URL in response');
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'Unable to upload this gallery image.',
      );
    }
    _log('Upload [tmpfiles.org]: OK');
    return url.replaceFirst('tmpfiles.org/', 'tmpfiles.org/dl/');
  }

  Future<String> _uploadZeroX(List<int> bytes, String filename) async {
    _log('Upload [0x0.st]: sending…');
    final response = await _uploadDio.post<String>(
      'https://0x0.st',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
      options: Options(
        responseType: ResponseType.plain,
        headers: {'User-Agent': 'DeepImageSearch/1.0'},
      ),
    );
    final url = response.data?.trim() ?? '';
    if (!url.startsWith('http')) {
      _log('Upload [0x0.st]: invalid response');
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'Unable to upload this gallery image.',
      );
    }
    _log('Upload [0x0.st]: OK');
    return url;
  }

  SearchResponse normalizeReverseImage(
    Map<String, dynamic> raw,
    String queryImage,
    SearchType searchType,
  ) {
    final inline = _list(raw['inline_images']);
    final pages = _list(raw['image_results']);
    return SearchResponse(
      searchId: const Uuid().v4(),
      queryImage: queryImage,
      searchType: searchType,
      results: SearchResultsBundle(
        visualMatches: [
          for (var i = 0; i < inline.length; i++)
            _item(inline[i], 'visual_match', i),
        ],
        exactMatches: [
          for (var i = 0; i < pages.length; i++)
            _item(pages[i], 'exact_match', i),
        ],
        products: const [],
        aboutImage: _about(raw['knowledge_graph']),
      ),
    );
  }

  SearchResponse normalize(
    Map<String, dynamic> raw,
    String queryImage,
    SearchType searchType,
  ) {
    final visual = _list(raw['visual_matches']);
    final exact = _list(raw['exact_matches']);
    final products = _list(raw['shopping_results']).isNotEmpty
        ? _list(raw['shopping_results'])
        : visual.where((item) => item['price'] != null).toList();

    return SearchResponse(
      searchId: const Uuid().v4(),
      queryImage: queryImage,
      searchType: searchType,
      results: SearchResultsBundle(
        visualMatches: [
          for (var i = 0; i < visual.length; i++)
            _item(visual[i], 'visual_match', i),
        ],
        exactMatches: [
          for (var i = 0; i < exact.length; i++)
            _item(exact[i], 'exact_match', i),
        ],
        products: [
          for (var i = 0; i < products.length; i++)
            _item(products[i], 'product', i),
        ],
        aboutImage: _about(raw['knowledge_graph'] ?? raw['about_this_image'] ?? raw['image_sources']),
      ),
    );
  }

  SearchResult _item(Map<String, dynamic> item, String category, int index) {
    final sourceUrl = (item['link'] ?? item['source'] ?? item['url'] ?? '').toString();
    final price = item['price'];
    return SearchResult(
      id: item['position'] != null ? '${category}_${item['position']}' : '${category}_$index',
      title: (item['title'] ?? item['source'] ?? 'Untitled').toString(),
      category: category,
      thumbnail: item['thumbnail']?.toString() ?? item['image']?.toString(),
      imageUrl: item['image']?.toString() ?? item['original']?.toString() ?? item['thumbnail']?.toString(),
      sourceUrl: sourceUrl.isEmpty ? null : sourceUrl,
      sourceDomain: item['source']?.toString() ?? UrlValidator.domainOf(sourceUrl),
      description: item['snippet']?.toString() ?? item['title']?.toString(),
      price: price is Map ? price['value']?.toString() : price?.toString(),
      currency: price is Map ? price['currency']?.toString() : item['currency']?.toString(),
    );
  }

  AboutImageInfo? _about(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final websites = <String>[];
    final searches = <String>[];
    final sources = map['sources'];
    if (sources is List) {
      for (final item in sources.whereType<Map>()) {
        final link = item['link']?.toString();
        if (link != null && link.isNotEmpty) websites.add(link);
      }
    }
    final related = map['related_searches'];
    if (related is List) {
      for (final item in related) {
        if (item is Map) {
          searches.add((item['query'] ?? item['name'] ?? '').toString());
        } else {
          searches.add(item.toString());
        }
      }
    }
    final info = AboutImageInfo(
      summary: map['subtitle']?.toString() ?? map['title']?.toString() ?? map['description']?.toString(),
      possibleSource: map['source']?.toString() ?? (websites.isNotEmpty ? websites.first : null),
      relatedWebsites: websites,
      relatedSearches: searches.where((e) => e.isNotEmpty).toList(),
    );
    return info.hasContent ? info : null;
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
