import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:we_monitor/app/models/pending_hotspot_model.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/services/pending_upload_service.dart';
import 'package:we_monitor/shared/services/snackbar_service.dart';

class PendingHotspotsController extends GetxController {
  final RxList<PendingHotspotModel> pendingHotspots =
      <PendingHotspotModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString uploadingId = ''.obs;

  /// Completes once the first load (with the stale-flag reset) is done.
  late final Future<void> ready;

  static Future<Box<PendingHotspotModel>> _box() =>
      Hive.openBox<PendingHotspotModel>('pending_hotspots');

  @override
  void onInit() {
    super.onInit();
    ready = loadPendingHotspots(resetStale: true);
  }

  /// [resetStale] clears `isUploading` left behind when the app was killed
  /// mid-upload; nothing can be uploading when the app has just started.
  Future<void> loadPendingHotspots({bool resetStale = false}) async {
    try {
      isLoading.value = true;
      final box = await _box();
      if (resetStale) {
        for (final h in box.values.where((h) => h.isUploading)) {
          h.isUploading = false;
          await h.save();
        }
      }
      pendingHotspots.value = box.values.toList();
    } catch (e) {
      debugPrint('[PendingHotspots] Error loading: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Uploads one report, resuming from wherever the last attempt stopped.
  Future<bool> uploadHotspot(
    PendingHotspotModel hotspot, {
    bool silent = false,
  }) async => await _upload(hotspot, silent: silent) == PendingResult.uploaded;

  Future<PendingResult> _upload(
    PendingHotspotModel hotspot, {
    bool silent = false,
  }) => PendingUploadService.serialize(() async {
    if (!(await _box()).containsKey(hotspot.localId)) {
      return PendingResult.skipped;
    }
    if (FirebaseAuth.instance.currentUser?.uid != hotspot.userId) {
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
      uploadingId.value = hotspot.localId;
      hotspot
        ..docId ??= firestore.collection('plastic_hotspots').doc().id
        ..uploadedFull ??= {}
        ..uploadedThumb ??= {}
        ..missingPhotos ??= []
        ..isUploading = true
        ..uploadError = null;
      await hotspot.save();
      pendingHotspots.refresh();

      final newlyMissing = await resumePhotoUploads(
        folder: 'hotspots/${hotspot.docId}',
        localPaths: hotspot.localPhotoPaths,
        full: hotspot.uploadedFull!,
        thumb: hotspot.uploadedThumb!,
        missing: hotspot.missingPhotos!,
        persist: hotspot.save,
      );
      if (newlyMissing > 0) {
        SnackbarService.warning(
          'sync.missingTitle'.tr,
          'sync.missingBody'.trPluralParams('sync.missingBodyPlural', newlyMissing, {
            'count': '$newlyMissing',
            'place': hotspot.location,
          }),
        );
      }

      final ref = firestore.collection('plastic_hotspots').doc(hotspot.docId);
      final existing = await ref.get(const GetOptions(source: Source.server));
      if (!existing.exists) {
        final urls = orderedUrls(
          hotspot.localPhotoPaths,
          hotspot.uploadedFull!,
          hotspot.uploadedThumb!,
        );
        // A hotspot report needs at least one photo. Keep the entry so the
        // user sees why and can delete it.
        if (urls.full.isEmpty) {
          hotspot
            ..isUploading = false
            ..uploadError = 'sync.hotspotNoPhotos'.tr;
          await hotspot.save();
          pendingHotspots.refresh();
          return PendingResult.skipped;
        }
        await ref.set(
          hotspot.toFirestore(photoUrls: urls.full, thumbUrls: urls.thumb),
        );
      }

      await (await _box()).delete(hotspot.localId);
      await deleteLocalPhotos(hotspot.localPhotoPaths);
      await loadPendingHotspots();
      if (!silent) {
        SnackbarService.success(
          'sync.uploadedTitle'.tr,
          'sync.hotspotUploaded'.tr,
        );
      }
      return PendingResult.uploaded;
    } catch (e, st) {
      debugPrint('[PendingHotspots] Error uploading: $e');
      Analytics.error(e, st, reason: 'pending hotspot upload failed');
      hotspot
        ..isUploading = false
        ..uploadError = 'sync.failedWillRetry'.tr;
      await hotspot.save();
      pendingHotspots.refresh();
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
    for (final hotspot in List<PendingHotspotModel>.from(pendingHotspots)) {
      results.add(await _upload(hotspot, silent: silent));
    }
    return results;
  }

  Future<void> deleteHotspot(PendingHotspotModel hotspot) =>
      PendingUploadService.serialize(() async {
        await (await _box()).delete(hotspot.localId);
        await deleteLocalPhotos(hotspot.localPhotoPaths);
        await deleteUploadedPhotos(
          'plastic_hotspots',
          hotspot.docId,
          [...?hotspot.uploadedFull?.values, ...?hotspot.uploadedThumb?.values],
        );
        await loadPendingHotspots();
        SnackbarService.info('sync.deletedTitle'.tr, 'sync.hotspotDeleted'.tr);
      });
}
