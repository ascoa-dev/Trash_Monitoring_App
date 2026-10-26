import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:we_monitor/app/models/cleanup_model.dart';
import 'package:we_monitor/app/models/pending_cleanup_model.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/services/pending_upload_service.dart';
import 'package:we_monitor/shared/services/snackbar_service.dart';

class PendingCleanupsController extends GetxController {
  final RxList<PendingCleanupModel> pendingCleanups =
      <PendingCleanupModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString uploadingId = ''.obs;

  /// Completes once the first load (with the stale-flag reset) is done.
  late final Future<void> ready;

  static Future<Box<PendingCleanupModel>> _box() =>
      Hive.openBox<PendingCleanupModel>('pending_cleanups');

  @override
  void onInit() {
    super.onInit();
    ready = loadPendingCleanups(resetStale: true);
  }

  /// [resetStale] clears `isUploading` left behind when the app was killed
  /// mid-upload; nothing can be uploading when the app has just started.
  Future<void> loadPendingCleanups({bool resetStale = false}) async {
    try {
      isLoading.value = true;
      final box = await _box();
      if (resetStale) {
        for (final c in box.values.where((c) => c.isUploading)) {
          c.isUploading = false;
          await c.save();
        }
      }
      pendingCleanups.value = box.values.toList();
    } catch (e) {
      debugPrint('[PendingCleanups] Error loading: $e');
      SnackbarService.error('sync.errorTitle'.tr, 'sync.loadFailed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Uploads one entry, resuming from wherever the last attempt stopped.
  /// [silent] (automatic uploads) skips per-entry success/error snackbars;
  /// missing-photo warnings are always shown.
  Future<bool> uploadCleanup(
    PendingCleanupModel cleanup, {
    bool silent = false,
  }) async => await _upload(cleanup, silent: silent) == PendingResult.uploaded;

  Future<PendingResult> _upload(
    PendingCleanupModel cleanup, {
    bool silent = false,
  }) => PendingUploadService.serialize(() async {
    // Uploaded (or deleted) by an earlier run while this one waited.
    if (!(await _box()).containsKey(cleanup.localId)) {
      return PendingResult.skipped;
    }
    // Only the account that saved it can upload it (rules check userId).
    if (FirebaseAuth.instance.currentUser?.uid != cleanup.userId) {
      return PendingResult.skipped;
    }
    if (!await Get.find<ConnectivityController>().checkConnectivity()) {
      if (!silent) {
        SnackbarService.warning('sync.offlineTitle'.tr, 'sync.offlineBody'.tr);
      }
      return PendingResult.skipped;
    }

    final firestore = FirebaseFirestore.instance;
    try {
      uploadingId.value = cleanup.localId;
      cleanup
        ..docId ??= firestore.collection('cleanups').doc().id
        ..uploadedFull ??= {}
        ..uploadedThumb ??= {}
        ..missingPhotos ??= []
        ..isUploading = true
        ..uploadError = null;
      await cleanup.save();
      pendingCleanups.refresh();

      final localPaths = cleanup.localPhotoPaths ?? const <String>[];
      final newlyMissing = await resumePhotoUploads(
        folder: 'cleanups/${cleanup.docId}',
        localPaths: localPaths,
        full: cleanup.uploadedFull!,
        thumb: cleanup.uploadedThumb!,
        missing: cleanup.missingPhotos!,
        persist: cleanup.save,
      );
      if (newlyMissing > 0) {
        SnackbarService.warning(
          'sync.missingTitle'.tr,
          'sync.missingBody'.trPluralParams('sync.missingBodyPlural', newlyMissing, {
            'count': '$newlyMissing',
            'place': cleanup.location,
          }),
        );
      }

      // The doc id is fixed, so a retry after a commit whose reply was lost
      // finds the doc instead of creating a duplicate.
      final cleanupRef = firestore.collection('cleanups').doc(cleanup.docId);
      final existing = await cleanupRef.get(
        const GetOptions(source: Source.server),
      );
      if (!existing.exists) {
        final urls = orderedUrls(
          localPaths,
          cleanup.uploadedFull!,
          cleanup.uploadedThumb!,
        );
        final cleanupModel = CleanupModel.fromFormData(
          userId: cleanup.userId,
          peopleCount: cleanup.peopleCount,
          groupName: cleanup.groupName,
          date: cleanup.date,
          location: cleanup.location,
          locationLatitude: cleanup.locationLatitude,
          locationLongitude: cleanup.locationLongitude,
          environment: cleanup.environment,
          trashItems: cleanup.trashItems,
          itemWeights: cleanup.itemWeights,
          itemCategories: cleanup.itemCategories,
        ).copyWith(
          photoUrls: urls.full.isEmpty ? null : urls.full,
          thumbUrls: urls.thumb.isEmpty ? null : urls.thumb,
          createdAt: cleanup.createdAt,
        );

        final batch = firestore.batch();
        batch.set(cleanupRef, cleanupModel.toFirestore());
        batch.update(firestore.collection('users').doc(cleanup.userId), {
          'cleanups': FieldValue.arrayUnion([cleanupRef.id]),
        });
        await batch.commit();
      }

      await (await _box()).delete(cleanup.localId);
      await deleteLocalPhotos(localPaths);
      await loadPendingCleanups();
      if (!silent) {
        SnackbarService.success(
          'sync.uploadedTitle'.tr,
          'sync.cleanupUploaded'.tr,
        );
      }
      return PendingResult.uploaded;
    } catch (e, st) {
      debugPrint('[PendingCleanups] Error uploading: $e');
      Analytics.error(e, st, reason: 'pending cleanup upload failed');
      cleanup
        ..isUploading = false
        ..uploadError = 'sync.failedWillRetry'.tr;
      await cleanup.save();
      pendingCleanups.refresh();
      if (!silent) {
        SnackbarService.error('sync.errorTitle'.tr, 'sync.uploadFailed'.tr);
      }
      return PendingResult.failed;
    } finally {
      uploadingId.value = '';
    }
  });

  Future<List<PendingResult>> uploadAll({bool silent = false}) async {
    final results = <PendingResult>[];
    for (final cleanup in List<PendingCleanupModel>.from(pendingCleanups)) {
      results.add(await _upload(cleanup, silent: silent));
    }
    return results;
  }

  Future<void> deleteCleanup(PendingCleanupModel cleanup) =>
      PendingUploadService.serialize(() async {
        try {
          await (await _box()).delete(cleanup.localId);
          await deleteLocalPhotos(cleanup.localPhotoPaths ?? const []);
          // Photos that already reached Storage would otherwise be orphaned.
          await deleteUploadedPhotos(
            'cleanups',
            cleanup.docId,
            [...?cleanup.uploadedFull?.values, ...?cleanup.uploadedThumb?.values],
          );
          await loadPendingCleanups();
          SnackbarService.info(
            'sync.deletedTitle'.tr,
            'sync.cleanupDeleted'.tr,
          );
        } catch (e) {
          debugPrint('[PendingCleanups] Error deleting: $e');
          SnackbarService.error('sync.errorTitle'.tr, 'sync.deleteFailed'.tr);
        }
      });
}
