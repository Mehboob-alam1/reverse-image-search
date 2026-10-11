import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/ai_config.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/search_stack_config.dart';
import '../core/errors/app_exception.dart';
import '../models/search_response.dart';
import '../models/search_result.dart';
import '../models/search_type.dart';
import 'google_lens_external.dart';
import 'search_debug_log.dart';
import 'vision_chat_client.dart';

class ImageInsightsService {
  ImageInsightsService({Dio? dio, this.onLog}) : _dio = dio ?? Dio();

  final Dio _dio;
  final SearchLogCallback? onLog;

  void _log(String message) => onLog?.call(message);

  bool get _hasOpenAi => AppEnv.openAiApiKey.isNotEmpty;
  bool get _hasQwen => AppEnv.qwenApiKey.isNotEmpty;

  static bool get isConfigured => AppEnv.openAiApiKey.isNotEmpty || AppEnv.qwenApiKey.isNotEmpty;

  Future<SearchResponse> enrich({
    required SearchResponse response,
    File? file,
    String? imageUrl,
    String localeCode = 'en',
    List<SearchResult> topResults = const [],
  }) async {
    final publicUrl = _resolvePublicUrl(response, imageUrl);
    final lensWeb = publicUrl != null ? GoogleLensExternal.uploadByUrl(publicUrl) : null;

    var bundle = response.results;
    var about = bundle.aboutImage ?? const AboutImageInfo();
    final metadata = Map<String, String>.from(about.metadata);
    if (lensWeb != null) {
      metadata[SearchStackConfig.metadataLensWebUrl] = lensWeb;
    }

    if (!_hasOpenAi && !_hasQwen) {
      _log('AI insights skipped (no OPENAI_API_KEY / QWEN_API_KEY).');
      if (lensWeb == null) return response;
      about = about.copyWith(metadata: metadata);
      return response.copyWith(
        results: SearchResultsBundle(
          visualMatches: bundle.visualMatches,
          exactMatches: bundle.exactMatches,
          products: bundle.products,
          aboutImage: about,
        ),
      );
    }

    try {
      final imagePayload = await _imagePayload(file: file, imageUrl: publicUrl);
      final preferQwen = AiConfig.preferQwenForLocale(localeCode);
      final insights = await _fetchInsights(
        preferQwen: preferQwen,
        localeCode: localeCode,
        imageBase64: imagePayload?.$1,
        imageMime: imagePayload?.$2,
        topResults: topResults,
        existingAbout: about,
      );

      if (insights != null) {
        about = about.merge(insights.about).copyWith(
              metadata: {
                ...metadata,
                ...insights.about.metadata,
                SearchStackConfig.metadataInsightsProvider: insights.providerLabel,
                if (insights.resultsSummary != null)
                  SearchStackConfig.metadataResultsSummary: insights.resultsSummary!,
              },
            );
      } else {
        about = about.copyWith(metadata: metadata);
      }
    } on AppException catch (error) {
      _log('AI insights failed: ${error.message}');
      about = about.copyWith(metadata: metadata);
    } on Object catch (error) {
      _log('AI insights error: $error');
      about = about.copyWith(metadata: metadata);
    }

    return response.copyWith(
      results: SearchResultsBundle(
        visualMatches: bundle.visualMatches,
        exactMatches: bundle.exactMatches,
        products: bundle.products,
        aboutImage: about,
      ),
    );
  }

  String? _resolvePublicUrl(SearchResponse response, String? imageUrl) {
    final q = response.queryImage;
    if (imageUrl != null && imageUrl.startsWith('http')) return imageUrl;
    if (q.startsWith('http')) return q;
    return null;
  }

  Future<(String, String)?> _imagePayload({
    File? file,
    String? imageUrl,
  }) async {
    if (file != null && await file.exists()) {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      final mime = _mimeForPath(file.path);
      return (base64Encode(bytes), mime);
    }
    if (imageUrl != null && imageUrl.startsWith('http')) {
      try {
        final response = await _dio.get<List<int>>(
          imageUrl,
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(seconds: 20),
          ),
        );
        final bytes = response.data;
        if (bytes == null || bytes.isEmpty) return null;
        if (bytes.length > 4 * 1024 * 1024) return null;
        return (base64Encode(bytes), 'image/jpeg');
      } on Object {
        return null;
      }
    }
    return null;
  }

  String _mimeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<_InsightsPayload?> _fetchInsights({
    required bool preferQwen,
    required String localeCode,
    String? imageBase64,
    String? imageMime,
    required List<SearchResult> topResults,
    required AboutImageInfo existingAbout,
  }) async {
    final system = '''
You help a reverse image search app. Reply with JSON only:
{
  "summary": "2-4 sentences about what is in the image and likely context",
  "possibleSource": "best guess of source or subject, or empty string",
  "relatedSearches": ["3-5 short search phrases"],
  "resultsOverview": "If match list provided, 1-2 sentences summarizing top web matches; else empty string"
}
Write summary and resultsOverview in language code "$localeCode". Be factual; say when uncertain.''';

    final matchLines = topResults
        .take(8)
        .map((r) => '- ${r.title} (${r.sourceDomain ?? r.sourceUrl ?? ''})')
        .join('\n');
    final userText = StringBuffer()
      ..writeln('Analyze this image for the user.')
      ..writeln('Existing Lens about text (may be empty): ${existingAbout.summary ?? ''}')
      ..writeln('Top web matches:')
      ..writeln(matchLines.isEmpty ? '(none yet)' : matchLines);

    final clients = <(VisionChatClient, String)>[];
    if (preferQwen && _hasQwen) {
      clients.add((
        VisionChatClient(
          baseUrl: AiConfig.qwenBaseUrl,
          apiKey: AppEnv.qwenApiKey,
          model: AiConfig.qwenVisionModel,
          onLog: onLog,
        ),
        SearchStackConfig.insightsQwenLabel,
      ));
    }
    if (_hasOpenAi) {
      clients.add((
        VisionChatClient(
          baseUrl: AiConfig.openAiBaseUrl,
          apiKey: AppEnv.openAiApiKey,
          model: AiConfig.openAiMiniModel,
          onLog: onLog,
        ),
        SearchStackConfig.insightsOpenAiLabel,
      ));
    }
    if (!preferQwen && _hasQwen) {
      clients.add((
        VisionChatClient(
          baseUrl: AiConfig.qwenBaseUrl,
          apiKey: AppEnv.qwenApiKey,
          model: AiConfig.qwenVisionModel,
          onLog: onLog,
        ),
        SearchStackConfig.insightsQwenLabel,
      ));
    }

    AppException? lastError;
    for (final (client, label) in clients) {
      try {
        _log('Trying insights via $label…');
        final json = await client.requestJson(
          systemPrompt: system,
          userText: userText.toString(),
          imageBase64: imageBase64,
          imageMime: imageMime,
        );
        final about = AboutImageInfo(
          summary: _str(json['summary']),
          possibleSource: _str(json['possibleSource']),
          relatedSearches: _list(json['relatedSearches']),
          metadata: const {},
        );
        return _InsightsPayload(
          about: about,
          providerLabel: label,
          resultsSummary: _str(json['resultsOverview']),
        );
      } on AppException catch (error) {
        lastError = error;
        _log('$label failed: ${error.message}');
      }
    }
    if (lastError != null) throw lastError;
    return null;
  }

  String? _str(dynamic value) {
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  List<String> _list(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}

class _InsightsPayload {
  const _InsightsPayload({
    required this.about,
    required this.providerLabel,
    this.resultsSummary,
  });

  final AboutImageInfo about;
  final String providerLabel;
  final String? resultsSummary;
}

/// AI-only response when Google Lens API key is not configured.
SearchResponse buildAiOnlyPlaceholder({
  required String queryImage,
  required SearchType searchType,
}) {
  return SearchResponse(
    searchId: const Uuid().v4(),
    queryImage: queryImage,
    searchType: searchType,
    results: const SearchResultsBundle(),
  );
}
