import 'dart:io';

import 'package:dio/dio.dart';

import '../core/constants/api_config.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/url_validator.dart';
import 'search_debug_log.dart';

/// Short-lived public URLs so **Google Lens (web)** can load gallery photos.
class TemporaryImageHostService {
  TemporaryImageHostService({Dio? uploadDio, SearchLogCallback? onLog})
      : onLog = onLog,
        _uploadDio = uploadDio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 45),
                sendTimeout: const Duration(seconds: 90),
              ),
            );

  final Dio _uploadDio;
  final SearchLogCallback? onLog;

  void _log(String message) => onLog?.call(message);

  Future<String> hostTemporaryImage(File file) async {
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

    const perHostTimeout = Duration(seconds: 22);

    if (ApiConfig.imgBbApiKey.isNotEmpty) {
      _log('Upload: trying ImgBB (optional)…');
      try {
        final url = await _uploadImgBbFile(file, filename).timeout(
          perHostTimeout,
          onTimeout: () => throw const AppException(
            code: AppErrorCode.network,
            message: 'ImgBB upload timed out.',
          ),
        );
        _log('Upload: public image URL → $url');
        return url;
      } on Object catch (error) {
        _log('Upload: ImgBB failed ($error), trying catbox…');
      }
    }

    _log('Upload: ${bytes.length} bytes as "$filename" (catbox → tmpfiles → 0x0.st)');

    final attempts = <(String, Future<String> Function())>[
      ('catbox.moe', () => _uploadCatbox(bytes, filename)),
      ('tmpfiles.org', () => _uploadTmpFiles(bytes, filename)),
      ('0x0.st', () => _uploadZeroX(bytes, filename)),
    ];

    AppException? lastError;
    for (final (host, upload) in attempts) {
      try {
        _log('Upload: trying $host…');
        final url = await upload().timeout(
          perHostTimeout,
          onTimeout: () => throw AppException(
            code: AppErrorCode.network,
            message: '$host upload timed out.',
          ),
        );
        if (UrlValidator.isValidHttpUrl(url)) {
          _log('Upload: public image URL → $url');
          return url;
        }
        _log('Upload: $host returned invalid URL');
      } on AppException catch (error) {
        lastError = error;
        _log('Upload: $host failed: ${error.message}');
      } on Object catch (error) {
        lastError = AppException(
          code: AppErrorCode.invalidImage,
          message: error.toString(),
        );
        _log('Upload: $host failed: $error');
      }
    }

    throw lastError ??
        const AppException(
          code: AppErrorCode.invalidImage,
          message: 'Unable to prepare this image for search. Check your connection.',
        );
  }

  Future<String> _uploadImgBbFile(File file, String filename) async {
    final response = await _uploadDio.post<Map<String, dynamic>>(
      'https://api.imgbb.com/1/upload',
      queryParameters: {'key': ApiConfig.imgBbApiKey},
      data: FormData.fromMap({
        'image': await MultipartFile.fromFile(
          file.path,
          filename: filename.endsWith('.jpg') || filename.endsWith('.jpeg')
              ? filename
              : '$filename.jpg',
        ),
      }),
    );
    final body = response.data ?? const {};
    final statusCode = int.tryParse(body['status_code']?.toString() ?? '') ?? 0;
    if (statusCode != 200) {
      final msg = body['error'] is Map
          ? (body['error'] as Map)['message']?.toString()
          : body['status_txt']?.toString();
      throw AppException(
        code: AppErrorCode.invalidImage,
        message: msg ?? 'ImgBB upload failed.',
      );
    }
    final data = body['data'];
    if (data is! Map) {
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
    return url;
  }

  Future<String> _uploadCatbox(List<int> bytes, String filename) async {
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
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'Unable to upload this gallery image.',
      );
    }
    return url;
  }

  Future<String> _uploadTmpFiles(List<int> bytes, String filename) async {
    final response = await _uploadDio.post<Map<String, dynamic>>(
      'https://tmpfiles.org/api/v1/upload',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    final url = response.data?['data']?['url']?.toString() ?? '';
    if (url.isEmpty) {
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'Unable to upload this gallery image.',
      );
    }
    return url.replaceFirst('tmpfiles.org/', 'tmpfiles.org/dl/');
  }

  Future<String> _uploadZeroX(List<int> bytes, String filename) async {
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
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'Unable to upload this gallery image.',
      );
    }
    return url;
  }
}
