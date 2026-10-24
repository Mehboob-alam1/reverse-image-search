import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../errors/app_exception.dart';
import 'image_validator.dart';

class PickedMedia {
  PickedMedia._();

  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickOriginal({required ImageSource source}) async {
    // Gallery: use the OS photo picker (Android Photo Picker / iOS PHPicker).
    // Do NOT request READ_MEDIA_IMAGES / storage — Play policy forbids it when
    // the system picker is enough for one-off image selection.
    if (source == ImageSource.camera) {
      final camera = await Permission.camera.request();
      if (!camera.isGranted) {
        throw const AppException(
          code: AppErrorCode.validation,
          message: 'allowCameraAccess',
        );
      }
    }

    final picked = await _picker.pickImage(
      source: source,
      // Avoid triggering full media-library access on Android.
      requestFullMetadata: false,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 78,
    );
    if (picked == null) return null;

    return persistOriginalBytes(picked);
  }

  static Future<File> persistOriginalBytes(XFile picked) async {
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      throw const AppException(
        code: AppErrorCode.invalidImage,
        message: 'emptyImage',
      );
    }

    final dir = await getTemporaryDirectory();
    final originalName = p.basename(picked.name.isNotEmpty ? picked.name : picked.path);
    final ext = p.extension(originalName).replaceFirst('.', '').toLowerCase();
    final safeExt = ImageValidator.isSupportedExtension('x.$ext') ? ext : 'jpg';
    final dest = File(
      p.join(dir.path, 'original_${DateTime.now().millisecondsSinceEpoch}.$safeExt'),
    );
    await dest.writeAsBytes(bytes, flush: true);

    final error = ImageValidator.validateFile(dest);
    if (error != null) throw error;
    return dest;
  }
}
