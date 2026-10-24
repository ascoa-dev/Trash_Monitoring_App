import 'package:get/get.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';

/// Configuration for maximum number of photos allowed
class MediaUploadConfig {
  static const int maxPhotos = 5;
  static const int imageQuality = 75; // 0-100
  static const int maxEdge = 1600; // longest edge of the full image
  static const int thumbQuality = 70;
  static const int thumbMaxEdge = 480; // longest edge of the thumbnail
  static const String cacheControl = 'public, max-age=31536000, immutable';
}

/// Compress an image so its longest edge is at most [maxEdge] (never
/// upscales). flutter_image_compress scales by min(w/minWidth, h/minHeight),
/// so a square minimum equal to the target short edge caps the long edge,
/// whatever the EXIF rotation.
Future<String> compressJpeg(File file, int maxEdge, int quality) async {
  final tempDir = await getTemporaryDirectory();
  final targetPath = '${tempDir.path}/${const Uuid().v4()}.jpg';

  final buffer = await ui.ImmutableBuffer.fromUint8List(
    await file.readAsBytes(),
  );
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final w = descriptor.width, h = descriptor.height;
  descriptor.dispose();
  buffer.dispose();
  final long = w > h ? w : h;
  final short = w > h ? h : w;
  final minEdge = long <= maxEdge ? short : (short * maxEdge / long).round();

  final result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    targetPath,
    quality: quality,
    minWidth: minEdge,
    minHeight: minEdge,
    format: CompressFormat.jpeg,
  );

  if (result == null) {
    throw Exception('cleanup.compressFailed'.tr);
  }

  return result.path;
}

/// Compresses [source] to full + thumbnail JPEGs (contract sizes).
Future<({String full, String thumb})> compressJpegPair(File source) async {
  final full = await compressJpeg(
    source,
    MediaUploadConfig.maxEdge,
    MediaUploadConfig.imageQuality,
  );
  final thumb = await compressJpeg(
    File(full),
    MediaUploadConfig.thumbMaxEdge,
    MediaUploadConfig.thumbQuality,
  );
  return (full: full, thumb: thumb);
}

/// Uploads `<folderPath>/<base>.jpg` and `<base>_thumb.jpg` with the
/// cache/ownership metadata the Storage rules expect. Returns download URLs.
/// [baseName] defaults to a fresh uuid; pass a stable one so a retried upload
/// overwrites its own earlier attempt instead of leaving an orphan.
Future<({String full, String thumb})> uploadJpegPair({
  required String folderPath,
  required String fullPath,
  required String thumbPath,
  String? baseName,
  void Function(UploadTask task)? onFullTask,
}) async {
  final base = baseName ?? const Uuid().v4();
  final folder = FirebaseStorage.instance.ref().child(folderPath);
  final metadata = SettableMetadata(
    contentType: 'image/jpeg',
    cacheControl: MediaUploadConfig.cacheControl,
    customMetadata: {'ownerUid': FirebaseAuth.instance.currentUser?.uid ?? ''},
  );

  // Thumb first (tiny); the full-size upload drives any progress UI.
  final thumbSnap = await folder
      .child('${base}_thumb.jpg')
      .putFile(File(thumbPath), metadata);
  final thumbUrl = await thumbSnap.ref.getDownloadURL();

  final fullTask = folder.child('$base.jpg').putFile(File(fullPath), metadata);
  onFullTask?.call(fullTask);
  final fullSnap = await fullTask;
  return (full: await fullSnap.ref.getDownloadURL(), thumb: thumbUrl);
}

/// Represents a photo being uploaded or already uploaded
class PhotoUpload {
  final String id; // Unique identifier
  final File file; // Local file
  String? compressedPath; // Path to compressed file
  double progress; // 0.0 to 1.0
  PhotoUploadStatus status;
  String? downloadUrl; // Firebase Storage URL
  String? thumbUrl; // Thumbnail URL (null for old drafts)
  String? error;

  PhotoUpload({
    required this.id,
    required this.file,
    this.compressedPath,
    this.progress = 0.0,
    this.status = PhotoUploadStatus.pending,
    this.downloadUrl,
    this.thumbUrl,
    this.error,
  });

  PhotoUpload copyWith({
    String? id,
    File? file,
    String? compressedPath,
    double? progress,
    PhotoUploadStatus? status,
    String? downloadUrl,
    String? thumbUrl,
    String? error,
  }) {
    return PhotoUpload(
      id: id ?? this.id,
      file: file ?? this.file,
      compressedPath: compressedPath ?? this.compressedPath,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      error: error ?? this.error,
    );
  }
}

enum PhotoUploadStatus {
  pending, // Not started
  compressing, // Compressing image
  uploading, // Uploading to Firebase
  completed, // Successfully uploaded
  cancelled, // User cancelled
  error, // Error occurred
}

/// Controller to manage media uploads for cleanup
class MediaUploadController extends ChangeNotifier {
  MediaUploadController({this.storageFolder = 'cleanups'});

  final String storageFolder;
  final Map<String, PhotoUpload> _photos = {};
  final Uuid _uuid = const Uuid();

  // Track all uploaded URLs (even if photo is later removed)
  final Set<String> _allUploadedUrls = {};
  // full URL -> thumb URL, so removed photos delete both files
  final Map<String, String> _thumbByUrl = {};

  List<PhotoUpload> get photos => _photos.values.toList();
  int get photoCount => _photos.length;
  bool get canAddMore => _photos.length < MediaUploadConfig.maxPhotos;
  bool get hasPhotos => _photos.isNotEmpty;

  /// Get all successfully uploaded photo URLs (only from non-removed photos)
  List<String> get uploadedPhotoUrls {
    return _photos.values
        .where(
          (p) =>
              p.status == PhotoUploadStatus.completed && p.downloadUrl != null,
        )
        .map((p) => p.downloadUrl!)
        .toList();
  }

  /// Thumbnail URLs aligned with [uploadedPhotoUrls] (full URL when a
  /// restored old draft has no thumbnail).
  List<String> get uploadedThumbUrls {
    return _photos.values
        .where(
          (p) =>
              p.status == PhotoUploadStatus.completed && p.downloadUrl != null,
        )
        .map((p) => p.thumbUrl ?? p.downloadUrl!)
        .toList();
  }

  /// Check if all uploads are complete (or cancelled/error)
  bool get allUploadsComplete {
    if (_photos.isEmpty) return true;
    return _photos.values.every(
      (p) =>
          p.status == PhotoUploadStatus.completed ||
          p.status == PhotoUploadStatus.cancelled ||
          p.status == PhotoUploadStatus.error,
    );
  }

  /// Check if any uploads are in progress
  bool get hasUploadsInProgress {
    return _photos.values.any(
      (p) =>
          p.status == PhotoUploadStatus.compressing ||
          p.status == PhotoUploadStatus.uploading,
    );
  }

  /// Add a new photo to upload queue
  Future<void> addPhoto(File file) async {
    if (!canAddMore) {
      debugPrint(
        '[MediaUpload] Cannot add more photos (max ${MediaUploadConfig.maxPhotos})',
      );
      return;
    }

    final id = _uuid.v4();
    final photo = PhotoUpload(
      id: id,
      file: file,
      status: PhotoUploadStatus.pending,
    );

    _photos[id] = photo;
    notifyListeners();

    debugPrint('[MediaUpload] Added photo: $id');
  }

  /// Re-add a photo from a restored draft. With [uploadedUrl] it is restored
  /// as already uploaded (no re-upload); otherwise it is pending.
  /// Returns the new photo id.
  String restorePhoto(File file, {String? uploadedUrl, String? thumbUrl}) {
    final id = _uuid.v4();
    _photos[id] = PhotoUpload(
      id: id,
      file: file,
      status:
          uploadedUrl != null
              ? PhotoUploadStatus.completed
              : PhotoUploadStatus.pending,
      progress: uploadedUrl != null ? 1.0 : 0.0,
      downloadUrl: uploadedUrl,
      thumbUrl: thumbUrl,
    );
    if (uploadedUrl != null) {
      _allUploadedUrls.add(uploadedUrl);
      if (thumbUrl != null) _thumbByUrl[uploadedUrl] = thumbUrl;
    }
    notifyListeners();
    return id;
  }

  /// Add multiple photos
  Future<void> addPhotos(List<File> files) async {
    for (final file in files) {
      if (!canAddMore) break;
      await addPhoto(file);
    }
    Analytics.track(AnalyticsEvents.cleanupPhotoAdded);
  }

  /// Remove a photo from the queue
  void removePhoto(String id) {
    final photo = _photos[id];
    if (photo == null) return;

    Analytics.track(AnalyticsEvents.cleanupPhotoRemoved);

    // If photo was successfully uploaded, track its URL for later cleanup
    if (photo.status == PhotoUploadStatus.completed &&
        photo.downloadUrl != null) {
      _allUploadedUrls.add(photo.downloadUrl!);
    }

    // Cancel upload if in progress
    if (photo.status == PhotoUploadStatus.compressing ||
        photo.status == PhotoUploadStatus.uploading) {
      _photos[id] = photo.copyWith(status: PhotoUploadStatus.cancelled);
    } else {
      _photos.remove(id);
    }

    notifyListeners();
    debugPrint('[MediaUpload] Removed photo: $id');
  }

  /// Compress and upload a single photo
  Future<void> compressAndUpload(String photoId, String cleanupDocId) async {
    final photo = _photos[photoId];
    if (photo == null) {
      debugPrint('[MediaUpload] Photo not found: $photoId');
      return;
    }

    try {
      // Update status to compressing
      _photos[photoId] = photo.copyWith(
        status: PhotoUploadStatus.compressing,
        progress: 0.1,
      );
      notifyListeners();

      debugPrint('[MediaUpload] Compressing photo: $photoId');

      // Compress the image
      final compressed = await compressJpegPair(photo.file);
      final compressedPath = compressed.full;
      final thumbPath = compressed.thumb;

      if (_photos[photoId]?.status == PhotoUploadStatus.cancelled) {
        debugPrint(
          '[MediaUpload] Upload cancelled during compression: $photoId',
        );
        return;
      }

      _photos[photoId] = photo.copyWith(
        compressedPath: compressedPath,
        status: PhotoUploadStatus.uploading,
        progress: 0.3,
      );
      notifyListeners();

      debugPrint('[MediaUpload] Uploading photo: $photoId');

      // Upload to Firebase Storage
      final urls = await _uploadToFirebase(
        photoId,
        compressedPath,
        thumbPath,
        cleanupDocId,
      );
      final downloadUrl = urls.full;

      if (_photos[photoId]?.status == PhotoUploadStatus.cancelled) {
        debugPrint('[MediaUpload] Upload cancelled during upload: $photoId');
        return;
      }

      _photos[photoId] = photo.copyWith(
        downloadUrl: downloadUrl,
        thumbUrl: urls.thumb,
        status: PhotoUploadStatus.completed,
        progress: 1.0,
      );

      // Track this URL
      _allUploadedUrls.add(downloadUrl);
      _thumbByUrl[downloadUrl] = urls.thumb;

      notifyListeners();

      debugPrint('[MediaUpload] Upload complete: $photoId -> $downloadUrl');
    } catch (e) {
      debugPrint('[MediaUpload] Error uploading photo $photoId: $e');
      _photos[photoId] = photo.copyWith(
        status: PhotoUploadStatus.error,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  /// Compress and upload all pending photos
  Future<void> compressAndUploadAll(String cleanupDocId) async {
    final pendingPhotos =
        _photos.values
            .where((p) => p.status == PhotoUploadStatus.pending)
            .toList();

    debugPrint('[MediaUpload] Uploading ${pendingPhotos.length} photos');

    // Upload all photos in parallel
    await Future.wait(
      pendingPhotos.map((p) => compressAndUpload(p.id, cleanupDocId)),
    );

    debugPrint('[MediaUpload] All uploads complete');
  }

  /// Wait for all in-progress uploads to complete
  /// Returns true if all completed successfully, false if any failed/cancelled
  Future<bool> waitForUploadsToComplete({Duration? timeout}) async {
    if (!hasUploadsInProgress) {
      return allUploadsComplete;
    }

    debugPrint('[MediaUpload] Waiting for uploads to complete...');

    final maxWaitTime = timeout ?? const Duration(minutes: 5);
    final endTime = DateTime.now().add(maxWaitTime);

    while (hasUploadsInProgress && DateTime.now().isBefore(endTime)) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (hasUploadsInProgress) {
      debugPrint(
        '[MediaUpload] Upload timeout - some uploads still in progress',
      );
      return false;
    }

    debugPrint('[MediaUpload] All uploads completed');
    return allUploadsComplete;
  }

  /// Clean up unused photos from Firebase Storage
  /// Deletes photos that were uploaded but then removed by the user
  Future<void> cleanupUnusedPhotos() async {
    // Get URLs that are uploaded but not in the final list
    final finalUrls = uploadedPhotoUrls.toSet();
    final urlsToDelete = _allUploadedUrls.difference(finalUrls);

    if (urlsToDelete.isEmpty) {
      debugPrint('[MediaUpload] No unused photos to clean up');
      return;
    }

    debugPrint(
      '[MediaUpload] Cleaning up ${urlsToDelete.length} unused photos',
    );

    for (final url in urlsToDelete) {
      try {
        await FirebaseStorage.instance.refFromURL(url).delete();
        final thumb = _thumbByUrl.remove(url);
        if (thumb != null) {
          await FirebaseStorage.instance.refFromURL(thumb).delete();
        }
        debugPrint('[MediaUpload] Deleted unused photo: $url');
      } catch (e) {
        debugPrint('[MediaUpload] Error deleting photo $url: $e');
        // Continue with other deletions even if one fails
      }
    }

    // Clear the tracking set after cleanup
    _allUploadedUrls.clear();
    _allUploadedUrls.addAll(finalUrls);
  }

  /// Upload full + thumbnail to Firebase Storage (same uuid, `_thumb` suffix)
  Future<({String full, String thumb})> _uploadToFirebase(
    String photoId,
    String filePath,
    String thumbPath,
    String cleanupDocId,
  ) {
    return uploadJpegPair(
      folderPath: '$storageFolder/$cleanupDocId',
      fullPath: filePath,
      thumbPath: thumbPath,
      onFullTask: (uploadTask) {
        // Listen to upload progress
        uploadTask.snapshotEvents.listen((snapshot) {
          if (_photos[photoId]?.status == PhotoUploadStatus.cancelled) {
            uploadTask.cancel();
            return;
          }

          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          // Map progress from 0.3 to 1.0 (0.3 was already used for compression)
          final mappedProgress = 0.3 + (progress * 0.7);

          _photos[photoId] = _photos[photoId]!.copyWith(
            progress: mappedProgress,
          );
          notifyListeners();
        });
      },
    );
  }

  /// Clear all photos
  void clearAll() {
    _photos.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _photos.clear();
    super.dispose();
  }
}
