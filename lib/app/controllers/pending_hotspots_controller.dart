import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:we_monitor/app/models/pending_hotspot_model.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/media_upload_controller.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/services/snackbar_service.dart';

class PendingHotspotsController extends GetxController {
  final RxList<PendingHotspotModel> pendingHotspots =
      <PendingHotspotModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString uploadingId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPendingHotspots();
  }

  Future<void> loadPendingHotspots() async {
    try {
      isLoading.value = true;
      final box = await Hive.openBox<PendingHotspotModel>('pending_hotspots');
      pendingHotspots.value = box.values.toList();
    } catch (e) {
      debugPrint('[PendingHotspots] Error loading: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> uploadHotspot(PendingHotspotModel hotspot) async {
    final isOnline =
        await Get.find<ConnectivityController>().checkConnectivity();
    if (!isOnline) {
      SnackbarService.warning(
        'Offline',
        'You need an internet connection to upload hotspots',
      );
      return false;
    }

    try {
      uploadingId.value = hotspot.localId;
      hotspot.isUploading = true;
      hotspot.uploadError = null;
      await hotspot.save();
      pendingHotspots.refresh();

      final uploaded = await _uploadPhotos(
        hotspot.localId,
        hotspot.localPhotoPaths,
      );
      final photoUrls = uploaded?.full;
      if (uploaded == null || photoUrls == null || photoUrls.isEmpty) {
        throw Exception('Failed to upload hotspot photos');
      }

      await FirebaseFirestore.instance
          .collection('plastic_hotspots')
          .doc()
          .set(
            hotspot.toFirestore(
              photoUrls: photoUrls,
              thumbUrls: uploaded.thumb,
            ),
          );

      final box = await Hive.openBox<PendingHotspotModel>('pending_hotspots');
      await box.delete(hotspot.localId);
      await loadPendingHotspots();
      SnackbarService.success('Success', 'Hotspot uploaded successfully');
      return true;
    } catch (e) {
      hotspot.isUploading = false;
      hotspot.uploadError = e.toString();
      await hotspot.save();
      pendingHotspots.refresh();
      SnackbarService.error('Upload Error', 'Failed to upload hotspot');
      return false;
    } finally {
      uploadingId.value = '';
    }
  }

  Future<({List<String> full, List<String> thumb})?> _uploadPhotos(
    String hotspotId,
    List<String> localPaths,
  ) async {
    try {
      final full = <String>[];
      final thumb = <String>[];
      for (final path in localPaths) {
        final file = File(path);
        if (!file.existsSync()) continue;
        final compressed = await compressJpegPair(file);
        final urls = await uploadJpegPair(
          folderPath: 'hotspots/$hotspotId',
          fullPath: compressed.full,
          thumbPath: compressed.thumb,
        );
        full.add(urls.full);
        thumb.add(urls.thumb);
      }
      return (full: full, thumb: thumb);
    } catch (e) {
      debugPrint('[PendingHotspots] Error uploading photos: $e');
      return null;
    }
  }

  Future<void> uploadAll() async {
    for (final hotspot in List<PendingHotspotModel>.from(pendingHotspots)) {
      if (!hotspot.isUploading) {
        await uploadHotspot(hotspot);
      }
    }
  }

  Future<void> deleteHotspot(PendingHotspotModel hotspot) async {
    final box = await Hive.openBox<PendingHotspotModel>('pending_hotspots');
    await box.delete(hotspot.localId);
    await loadPendingHotspots();
    SnackbarService.info('Deleted', 'Hotspot report deleted');
  }
}
