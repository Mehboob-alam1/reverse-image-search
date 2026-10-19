import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/railway_search_config.dart';
import '../core/constants/search_stack_config.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/url_validator.dart';
import '../models/search_response.dart';
import '../models/search_result.dart';
import '../models/search_type.dart';
import 'search_debug_log.dart';

/// Client for the Railway reverse-image search API (`POST /api/search`).
class RailwaySearchService {
  RailwaySearchService({Dio? dio, SearchLogCallback? onLog})
      : onLog = onLog,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: RailwaySearchConfig.baseUrl,
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: RailwaySearchConfig.searchTimeout,
                sendTimeout: RailwaySearchConfig.searchTimeout,
              ),
            );

  final Dio _dio;
  final SearchLogCallback? onLog;

  void _log(String message) => onLog?.call(message);

  void _syncBaseUrl() {
    _dio.options.baseUrl = RailwaySearchConfig.baseUrl;
  }

  Future<bool> health() async {
    _syncBaseUrl();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        RailwaySearchConfig.healthPath,
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );
      return response.statusCode == 200 && response.data?['ok'] == true;
    } on Object {
      return false;
    }
  }

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
    _log('Railway API: downloading image URL for upload…');
    try {
      final download = await _dio.get<List<int>>(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final bytes = download.data;
      if (bytes == null || bytes.isEmpty) {
        throw const AppException(
          code: AppErrorCode.invalidImage,
          message: 'Could not download that image URL.',
        );
      }
      final name = _filenameFromUrl(imageUrl);
      return _searchMultipart(
        bytes: bytes,
        filename: name,
        queryImageLabel: imageUrl,
        searchType: searchType,
      );
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw AppException(
        code: AppErrorCode.network,
        message: 'Could not fetch image URL: ${error.message}',
      );
    }
  }

  Future<SearchResponse> searchFile({
    required File file,
    required SearchType searchType,
  }) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'The selected image is empty.',
      );
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'Image must be under 10 MB for search.',
      );
    }
    final filename = file.uri.pathSegments.isEmpty
        ? 'search.jpg'
        : file.uri.pathSegments.last;
    return _searchMultipart(
      bytes: bytes,
      filename: filename,
      queryImageLabel: file.path,
      searchType: searchType,
    );
  }

  Future<SearchResponse> _searchMultipart({
    required List<int> bytes,
    required String filename,
    required String queryImageLabel,
    required SearchType searchType,
  }) async {
    _syncBaseUrl();
    _log(
      'Railway API: POST ${RailwaySearchConfig.baseUrl}/api/search '
      '(web=${RailwaySearchConfig.defaultWeb}, '
      'k=${RailwaySearchConfig.defaultK}, ${bytes.length} bytes)…',
    );
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        RailwaySearchConfig.searchPath,
        queryParameters: {
          'web': RailwaySearchConfig.defaultWeb,
          'k': RailwaySearchConfig.defaultK,
          'min_score': RailwaySearchConfig.defaultMinScore,
        },
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: RailwaySearchConfig.searchTimeout,
          sendTimeout: RailwaySearchConfig.searchTimeout,
        ),
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw AppException(
          code: AppErrorCode.unavailable,
          message: 'Search failed (HTTP $status).',
        );
      }
      final raw = response.data ?? const <String, dynamic>{};
      final normalized = normalize(raw, queryImageLabel, searchType);
      _log(
        'Railway API done in ${raw['took_ms'] ?? '?'}ms — '
        'matches=${normalized.results.exactMatches.length} '
        'similar=${normalized.results.visualMatches.length}',
      );
      return normalized;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      final detail = error.response?.data?.toString() ?? error.message ?? 'Network error';
      throw AppException(
        code: AppErrorCode.network,
        message: 'Search API: $detail',
      );
    }
  }

  SearchResponse normalize(
    Map<String, dynamic> raw,
    String queryImage,
    SearchType searchType,
  ) {
    final matches = _mapList(
      raw['matches'],
      category: 'exact_match',
      idPrefix: 'match',
    );
    final exact = _mapList(
      raw['exact'],
      category: 'exact_match',
      idPrefix: 'exact',
    );
    final similarWeb = _mapList(
      raw['similar_web'],
      category: 'visual_match',
      idPrefix: 'simweb',
    );
    final similar = _mapList(
      raw['similar'],
      category: 'visual_match',
      idPrefix: 'similar',
    );

    final exactMatches = _dedupe([...matches, ...exact]);
    final visualMatches = _dedupe([...similarWeb, ...similar]);

    return SearchResponse(
      searchId: const Uuid().v4(),
      queryImage: queryImage.startsWith('/') || queryImage.contains(':\\')
          ? 'local://upload'
          : queryImage,
      searchType: searchType,
      results: SearchResultsBundle(
        visualMatches: visualMatches,
        exactMatches: exactMatches,
        products: const [],
        aboutImage: _aboutFromAnalysis(raw),
      ),
    );
  }

  AboutImageInfo _aboutFromAnalysis(Map<String, dynamic> raw) {
    final analysis = raw['analysis'];
    final engines = raw['engines'];
    final metadata = <String, String>{
      SearchStackConfig.metadataInsightsProvider: 'Railway search API',
    };

    if (engines is Map) {
      final lens = engines['google_lens']?.toString();
      if (lens != null && lens.startsWith('http')) {
        metadata[SearchStackConfig.metadataLensWebUrl] = lens;
      }
      for (final key in ['bing', 'yandex', 'tineye']) {
        final url = engines[key]?.toString();
        if (url != null && url.startsWith('http')) {
          metadata['engine_$key'] = url;
        }
      }
    }

    if (analysis is! Map) {
      return AboutImageInfo(metadata: metadata);
    }
    final map = Map<String, dynamic>.from(analysis);

    final objects = _labelList(map['objects']);
    final landmarks = _labelList(map['landmarks']);
    final scenes = _labelList(map['scenes']);
    final webTags = _labelList(map['web_tags']);
    final related = <String>{...objects, ...landmarks, ...scenes, ...webTags}.toList();

    final faces = map['faces'];
    final faceCount = faces is Map ? faces['count'] : null;
    if (faceCount != null) {
      metadata['faces'] = faceCount.toString();
    }

    final ocr = map['text_ocr'];
    if (ocr is Map && ocr['has_text'] == true) {
      final text = ocr['text']?.toString();
      if (text != null && text.isNotEmpty) {
        metadata['ocr'] = text;
      }
    }

    final summaryParts = <String>[];
    if (objects.isNotEmpty) {
      summaryParts.add('Objects: ${objects.take(6).join(', ')}');
    }
    if (landmarks.isNotEmpty) {
      summaryParts.add('Landmarks: ${landmarks.take(4).join(', ')}');
    }
    if (scenes.isNotEmpty) {
      summaryParts.add('Scene: ${scenes.take(3).join(', ')}');
    }
    if (faceCount != null && faceCount.toString() != '0') {
      summaryParts.add('Faces detected: $faceCount');
    }

    return AboutImageInfo(
      summary: summaryParts.isEmpty ? null : summaryParts.join('. '),
      relatedSearches: related.take(12).toList(),
      metadata: metadata,
    );
  }

  List<String> _labelList(dynamic value) {
    if (value is! List) return const [];
    final out = <String>[];
    for (final item in value) {
      if (item is Map) {
        final label = item['label']?.toString().trim();
        if (label != null && label.isNotEmpty) out.add(label);
      } else {
        final s = item.toString().trim();
        if (s.isNotEmpty) out.add(s);
      }
    }
    return out;
  }

  List<SearchResult> _mapList(
    dynamic value, {
    required String category,
    required String idPrefix,
  }) {
    if (value is! List) return const [];
    final out = <SearchResult>[];
    for (var i = 0; i < value.length; i++) {
      final item = value[i];
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final pageUrl = map['page_url']?.toString() ?? map['url']?.toString();
      final imageUrl = map['image_url']?.toString() ?? map['image']?.toString();
      final thumb = map['thumb']?.toString() ?? map['thumbnail']?.toString();
      final source = map['source']?.toString();
      final score = map['score'];
      out.add(
        SearchResult(
          id: '${idPrefix}_$i',
          title: map['title']?.toString() ?? source ?? 'Web match',
          category: category,
          thumbnail: thumb ?? imageUrl,
          imageUrl: imageUrl ?? thumb,
          sourceUrl: pageUrl,
          sourceDomain: _domainFromSource(source) ?? UrlValidator.domainOf(pageUrl ?? ''),
          description: score != null ? 'Score: $score' : null,
        ),
      );
    }
    return out;
  }

  String? _domainFromSource(String? source) {
    if (source == null || source.isEmpty) return null;
    // e.g. "web:example.com"
    final cleaned = source.contains(':') ? source.split(':').last : source;
    return cleaned.replaceFirst(RegExp(r'^www\.'), '');
  }

  List<SearchResult> _dedupe(List<SearchResult> items) {
    final seen = <String>{};
    final out = <SearchResult>[];
    for (final item in items) {
      final key = item.favoriteId;
      if (seen.add(key)) out.add(item);
    }
    return out;
  }

  String _filenameFromUrl(String url) {
    try {
      final path = Uri.parse(url).path;
      final name = p.basename(path);
      if (name.isNotEmpty && name.contains('.')) return name;
    } on Object {
      // ignore
    }
    return 'search.jpg';
  }
}
