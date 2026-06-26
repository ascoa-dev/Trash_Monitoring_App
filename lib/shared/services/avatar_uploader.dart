import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/controllers/auth_controller.dart';

/// Service for uploading avatar images to Firebase Storage and updating Firestore
/// Uses UserModel for type-safe updates and syncs with AuthController
class AvatarUploader {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload avatar and thumbnail to Firebase Storage
  ///
  /// Uploads to: avatars/{uid}/avatar.webp and avatars/{uid}/thumb.webp
  /// Updates Firestore user doc with avatarUrl, thumbUrl, avatarUpdatedAt
  /// Updates FirebaseAuth photoURL
  ///
  /// [avatarFile]: Main avatar file (e.g., 600x600 WebP)
  /// [thumbnailFile]: Thumbnail file (e.g., 200x200 WebP)
  /// [onProgress]: Progress callback (0.0 to 1.0)
  ///
  /// Returns cache-busted avatar URL on success
  /// Throws exception on failure
  Future<String> uploadAvatar({
    required File avatarFile,
    required File thumbnailFile,
    required void Function(double) onProgress,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Upload main avatar (80% of progress)
      final avatarRef = _storage.ref('avatars/$uid/avatar.webp');
      final avatarTask = avatarRef.putFile(
        avatarFile,
        SettableMetadata(contentType: 'image/webp'),
      );

      avatarTask.snapshotEvents.listen((snapshot) {
        final progress =
            snapshot.bytesTransferred / (snapshot.totalBytes.toDouble());
        onProgress(progress * 0.8); // 0-80% for avatar
      });

      await avatarTask;
      final avatarUrl = await avatarRef.getDownloadURL();

      // Upload thumbnail (remaining 20% of progress)
      final thumbRef = _storage.ref('avatars/$uid/thumb.webp');
      final thumbTask = thumbRef.putFile(
        thumbnailFile,
        SettableMetadata(contentType: 'image/webp'),
      );

      thumbTask.snapshotEvents.listen((snapshot) {
        final progress =
            snapshot.bytesTransferred / (snapshot.totalBytes.toDouble());
        onProgress(0.8 + (progress * 0.2)); // 80-100% for thumb
      });

      await thumbTask;
      final thumbUrl = await thumbRef.getDownloadURL();

      // Cache-bust with timestamp for immediate refresh. Use Uri helpers so we
      // preserve existing query params like Firebase download tokens.
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cacheBustedAvatar = _appendCacheBuster(avatarUrl, timestamp);
      final cacheBustedThumb = _appendCacheBuster(thumbUrl, timestamp);

      // Update Firestore user document using structured update
      final avatarUpdate = {
        'avatarUrl': cacheBustedAvatar,
        'thumbUrl': cacheBustedThumb,
        'avatarUpdatedAt': FieldValue.serverTimestamp(),
        'photoURL': avatarUrl, // Also store clean URL for FirebaseAuth sync
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(uid)
          .set(avatarUpdate, SetOptions(merge: true));

      // Update FirebaseAuth profile photo URL
      await _auth.currentUser!.updatePhotoURL(avatarUrl);

      // Sync the updated model with AuthController if available
      try {
        final authController = Get.find<AuthController>();
        // Refresh the current user model to reflect the new avatar
        await authController.fetchCurrentUserProfile();
      } catch (e) {
        // AuthController not available (unlikely but handle gracefully)
      }

      return cacheBustedAvatar;
    } catch (e) {
      // Log error in production
      rethrow;
    }
  }

  /// Delete avatar files from Firebase Storage
  /// Call this if user wants to remove their profile photo
  Future<void> deleteAvatar() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // Delete files (ignore errors if files don't exist)
      await _storage
          .ref('avatars/$uid/avatar.webp')
          .delete()
          .catchError((_) {});
      await _storage.ref('avatars/$uid/thumb.webp').delete().catchError((_) {});

      // Clear Firestore fields using structured update
      final clearAvatarUpdate = {
        'avatarUrl': null,
        'thumbUrl': null,
        'avatarUpdatedAt': FieldValue.serverTimestamp(),
        'photoURL': null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(uid)
          .set(clearAvatarUpdate, SetOptions(merge: true));

      // Clear FirebaseAuth photoURL
      await _auth.currentUser!.updatePhotoURL(null);

      // Sync the updated model with AuthController if available
      try {
        final authController = Get.find<AuthController>();
        // Refresh the current user model to reflect the removed avatar
        await authController.fetchCurrentUserProfile();
      } catch (e) {
        // AuthController not available (unlikely but handle gracefully)
      }
    } catch (e) {
      // Log error in production
      rethrow;
    }
  }
}

String _appendCacheBuster(String url, int timestamp) {
  final uri = Uri.parse(url);
  final updatedQuery = Map<String, String>.from(uri.queryParameters);
  updatedQuery['v'] = timestamp.toString();
  return uri.replace(queryParameters: updatedQuery).toString();
}
