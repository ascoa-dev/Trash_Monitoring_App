import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:we_monitor/app/models/pending_cleanup_model.dart';
import 'package:we_monitor/app/models/cleanup_model.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/services/snackbar_service.dart';

class PendingCleanupsController extends GetxController {
  final RxList<PendingCleanupModel> pendingCleanups =
      <PendingCleanupModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString uploadingId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPendingCleanups();
  }

  Future<void> loadPendingCleanups() async {
    try {
      isLoading.value = true;
      final box = await Hive.openBox<PendingCleanupModel>('pending_cleanups');
      pendingCleanups.value = box.values.toList();
    } catch (e) {
      debugPrint('[PendingCleanups] Error loading: $e');
      SnackbarService.error('Error', 'Failed to load pending cleanups');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> uploadCleanup(PendingCleanupModel cleanup) async {
    try {
      final connectivityController = Get.find<ConnectivityController>();
      final isOnline = await connectivityController.checkConnectivity();

      if (!isOnline) {
        SnackbarService.warning(
          'Offline',
          'You need an internet connection to upload cleanups',
        );
        return false;
      }

      uploadingId.value = cleanup.localId;

      cleanup.isUploading = true;
      await cleanup.save();
      pendingCleanups.refresh();

      List<String>? photoUrls;
      if (cleanup.localPhotoPaths != null &&
          cleanup.localPhotoPaths!.isNotEmpty) {
        photoUrls = await _uploadPhotos(
          cleanup.localId,
          cleanup.localPhotoPaths!,
        );
        if (photoUrls == null) {
          cleanup.isUploading = false;
          cleanup.uploadError = 'Failed to upload photos';
          await cleanup.save();
          pendingCleanups.refresh();
          uploadingId.value = '';
          return false;
        }
      }

      final firestore = FirebaseFirestore.instance;

      final cleanupRef = firestore.collection('cleanups').doc();
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
      ).copyWith(photoUrls: photoUrls, createdAt: cleanup.createdAt);

      final batch = firestore.batch();

      batch.set(cleanupRef, cleanupModel.toFirestore());

      final userRef = firestore.collection('users').doc(cleanup.userId);
      batch.update(userRef, {
        'cleanups': FieldValue.arrayUnion([cleanupRef.id]),
      });

      await batch.commit();

      final box = await Hive.openBox<PendingCleanupModel>('pending_cleanups');
      await box.delete(cleanup.localId);

      await loadPendingCleanups();

      SnackbarService.success('Success', 'Cleanup uploaded successfully');

      uploadingId.value = '';
      return true;
    } catch (e) {
      debugPrint('[PendingCleanups] Error uploading: $e');

      cleanup.isUploading = false;
      cleanup.uploadError = e.toString();
      await cleanup.save();
      pendingCleanups.refresh();

      SnackbarService.error(
        'Upload Error',
        'Failed to upload cleanup: ${e.toString()}',
      );

      uploadingId.value = '';
      return false;
    }
  }

  Future<List<String>?> _uploadPhotos(
    String cleanupId,
    List<String> localPaths,
  ) async {
    try {
      final photoUrls = <String>[];

      for (int i = 0; i < localPaths.length; i++) {
        final localPath = localPaths[i];
        final file = File(localPath);

        if (!file.existsSync()) {
          debugPrint('[PendingCleanups] Photo not found: $localPath');
          continue;
        }

        final storageRef = FirebaseStorage.instance.ref().child(
          'cleanups/$cleanupId/photo_$i.jpg',
        );

        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        photoUrls.add(downloadUrl);
      }

      return photoUrls;
    } catch (e) {
      debugPrint('[PendingCleanups] Error uploading photos: $e');
      return null;
    }
  }

  Future<void> uploadAll() async {
    final cleanups = List<PendingCleanupModel>.from(pendingCleanups);

    for (final cleanup in cleanups) {
      if (!cleanup.isUploading) {
        await uploadCleanup(cleanup);
      }
    }
  }

  Future<void> deleteCleanup(PendingCleanupModel cleanup) async {
    try {
      final box = await Hive.openBox<PendingCleanupModel>('pending_cleanups');
      await box.delete(cleanup.localId);
      await loadPendingCleanups();

      SnackbarService.info('Deleted', 'Cleanup deleted');
    } catch (e) {
      debugPrint('[PendingCleanups] Error deleting: $e');
      SnackbarService.error('Error', 'Failed to delete cleanup');
    }
  }
}
