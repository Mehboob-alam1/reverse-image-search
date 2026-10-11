import 'dart:io';

import 'package:uuid/uuid.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/url_validator.dart';
import '../models/search_response.dart';
import '../models/search_type.dart';
import 'search_debug_log.dart';
import 'temporary_image_host_service.dart';

/// Prepares images for **free Google Lens** (web). No paid SerpApi/Apify calls.
class GoogleLensSearchService {
  GoogleLensSearchService({
    required TemporaryImageHostService imageHost,
    this.onLog,
  }) : _imageHost = imageHost;

  final TemporaryImageHostService _imageHost;
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
    _log('Google Lens (free): ready with image URL');
    return _placeholder(queryImage: imageUrl, searchType: searchType);
  }

  Future<SearchResponse> searchFile({
    required File file,
    required SearchType searchType,
  }) async {
    _log('Google Lens (free): hosting gallery image for lens.google.com…');
    final hosted = await _imageHost.hostTemporaryImage(file);
    return _placeholder(queryImage: hosted, searchType: searchType);
  }

  SearchResponse _placeholder({
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
}
