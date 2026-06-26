import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';

/// Configuration for maximum number of photos allowed
class MediaUploadConfig {
  static const int maxPhotos = 5;
  static const int imageQuality = 75; // 0-100
  static const int maxWidth = 1920;
  static const int maxHeight = 1920;
}

/// Represents a photo being uploaded or already uploaded
class PhotoUpload {
  final String id; // Unique identifier
  final File file; // Local file
  String? compressedPath; // Path to compressed file
  double progress; // 0.0 to 1.0
  PhotoUploadStatus status;
  String? downloadUrl; // Firebase Storage URL
  String? error;

  PhotoUpload({
    required this.id,
    required this.file,
    this.compressedPath,
    this.progress = 0.0,
    this.status = PhotoUploadStatus.pending,
    this.downloadUrl,
    this.error,
  });

  PhotoUpload copyWith({
    String? id,
    File? file,
    String? compressedPath,
    double? progress,
    PhotoUploadStatus? status,
    String? downloadUrl,
    String? error,
  }) {
    return PhotoUpload(
      id: id ?? this.id,
      file: file ?? this.file,
      compressedPath: compressedPath ?? this.compressedPath,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      downloadUrl: downloadUrl ?? this.downloadUrl,
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
      final compressedPath = await _compressImage(photo.file);

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
      final downloadUrl = await _uploadToFirebase(
        photoId,
        compressedPath,
        cleanupDocId,
      );

      if (_photos[photoId]?.status == PhotoUploadStatus.cancelled) {
        debugPrint('[MediaUpload] Upload cancelled during upload: $photoId');
        return;
      }

      _photos[photoId] = photo.copyWith(
        downloadUrl: downloadUrl,
        status: PhotoUploadStatus.completed,
        progress: 1.0,
      );

      // Track this URL
      _allUploadedUrls.add(downloadUrl);

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
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
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

  /// Compress an image file
  Future<String> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = '${tempDir.path}/${_uuid.v4()}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: MediaUploadConfig.imageQuality,
      minWidth: MediaUploadConfig.maxWidth,
      minHeight: MediaUploadConfig.maxHeight,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception('Failed to compress image');
    }

    return result.path;
  }

  /// Upload a file to Firebase Storage
  Future<String> _uploadToFirebase(
    String photoId,
    String filePath,
    String cleanupDocId,
  ) async {
    final file = File(filePath);
    final fileName = '${_uuid.v4()}.jpg';
    final ref = FirebaseStorage.instance
        .ref()
        .child(storageFolder)
        .child(cleanupDocId)
        .child(fileName);

    final uploadTask = ref.putFile(file);

    // Listen to upload progress
    uploadTask.snapshotEvents.listen((snapshot) {
      if (_photos[photoId]?.status == PhotoUploadStatus.cancelled) {
        uploadTask.cancel();
        return;
      }

      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      // Map progress from 0.3 to 1.0 (0.3 was already used for compression)
      final mappedProgress = 0.3 + (progress * 0.7);

      _photos[photoId] = _photos[photoId]!.copyWith(progress: mappedProgress);
      notifyListeners();
    });

    // Wait for upload to complete
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
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
