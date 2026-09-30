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
    if (source == ImageSource.gallery) {
      final photos = await Permission.photos.request();
      final storage = photos.isGranted || photos.isLimited
          ? photos
          : await Permission.storage.request();
      if (storage.isPermanentlyDenied) {
        throw const AppException(
          code: AppErrorCode.validation,
          message: 'allowPhotoAccess',
        );
      }
    } else {
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
      requestFullMetadata: true,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
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
