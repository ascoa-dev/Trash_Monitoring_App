import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:we_monitor/app/models/pending_hotspot_model.dart';
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

      final photoUrls = await _uploadPhotos(
        hotspot.localId,
        hotspot.localPhotoPaths,
      );
      if (photoUrls == null || photoUrls.isEmpty) {
        throw Exception('Failed to upload hotspot photos');
      }

      await FirebaseFirestore.instance
          .collection('plastic_hotspots')
          .doc()
          .set(hotspot.toFirestore(photoUrls: photoUrls));

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

  Future<List<String>?> _uploadPhotos(
    String hotspotId,
    List<String> localPaths,
  ) async {
    try {
      final urls = <String>[];
      for (var i = 0; i < localPaths.length; i++) {
        final file = File(localPaths[i]);
        if (!file.existsSync()) continue;
        final ref = FirebaseStorage.instance.ref().child(
          'hotspots/$hotspotId/photo_$i.jpg',
        );
        final snapshot = await ref.putFile(file);
        urls.add(await snapshot.ref.getDownloadURL());
      }
      return urls;
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
