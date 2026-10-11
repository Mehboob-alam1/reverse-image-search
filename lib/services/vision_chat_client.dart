import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/constants/ai_config.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';

typedef VisionLogCallback = void Function(String message);

class VisionChatClient {
  VisionChatClient({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    Dio? dio,
    this.onLog,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: AiConfig.aiTimeout,
                sendTimeout: AiConfig.aiTimeout,
              ),
            );

  final String baseUrl;
  final String apiKey;
  final String model;
  final Dio _dio;
  final VisionLogCallback? onLog;

  void _log(String message) => onLog?.call(message);

  Future<Map<String, dynamic>> requestJson({
    required String systemPrompt,
    required String userText,
    String? imageBase64,
    String? imageMime,
  }) async {
    if (apiKey.isEmpty) {
      throw const AppException(
        code: AppErrorCode.unavailable,
        message: 'AI API key is missing.',
      );
    }

    final content = <Map<String, dynamic>>[
      {'type': 'text', 'text': userText},
    ];
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      final mime = imageMime ?? 'image/jpeg';
      content.add({
        'type': 'image_url',
        'image_url': {
          'url': 'data:$mime;base64,$imageBase64',
        },
      });
    }

    _log('Vision chat: $model @ $baseUrl');
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': model,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': content},
          ],
          'max_tokens': 900,
          'temperature': 0.3,
        },
      );
      final choices = response.data?['choices'];
      if (choices is! List || choices.isEmpty) {
        throw const AppException(
          code: AppErrorCode.unavailable,
          message: 'AI returned an empty response.',
        );
      }
      final message = choices.first['message'];
      final raw = message is Map ? message['content']?.toString() ?? '' : '';
      return _parseJsonObject(raw);
    } on DioException catch (error) {
      final detail = error.response?.data?.toString() ?? error.message;
      throw AppException(
        code: AppErrorCode.network,
        message: 'AI request failed: $detail',
      );
    }
  }

  Map<String, dynamic> _parseJsonObject(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const AppException(
      code: AppErrorCode.unavailable,
      message: 'AI response was not JSON.',
    );
  }
}
