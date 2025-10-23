import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Image compression and resizing utilities for avatar uploads
class ImageUtils {
  /// Compress image to WebP format with specified target size and quality
  ///
  /// [file]: Input image file
  /// [targetSizePx]: Maximum width/height in pixels (maintains aspect ratio)
  /// [quality]: Compression quality 0-100 (default 75)
  ///
  /// Returns compressed File or null on failure
  static Future<File?> compressToWebP(
    File file, {
    required int targetSizePx,
    int quality = 75,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = p.join(tempDir.path, 'avatar_$timestamp.webp');

      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: targetSizePx,
        minHeight: targetSizePx,
        quality: quality,
        format: CompressFormat.webp,
        keepExif: false, // Strip EXIF for privacy and size
      );

      if (result == null) return null;

      final outFile = File(outPath);
      await outFile.writeAsBytes(result);
      return outFile;
    } catch (e) {
      debugPrint('ImageUtils.compressToWebP error: $e');
      return null;
    }
  }

  /// Create thumbnail from image
  ///
  /// [file]: Input image file
  /// [sizePx]: Thumbnail size in pixels (default 200)
  /// [quality]: Compression quality 0-100 (default 70)
  ///
  /// Returns thumbnail File or null on failure
  static Future<File?> createThumbnail(
    File file, {
    int sizePx = 200,
    int quality = 70,
  }) async {
    return compressToWebP(file, targetSizePx: sizePx, quality: quality);
  }

  /// Clean up temporary files (call after successful upload)
  static Future<void> cleanupTempFiles(List<File> files) async {
    for (final file in files) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('ImageUtils.cleanupTempFiles error: $e');
      }
    }
  }
}
