import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:ascoa_app/app/controllers/pending_hotspots_controller.dart';
import 'package:ascoa_app/app/models/pending_hotspot_model.dart';
import 'package:ascoa_app/modules/start_cleanup/controllers/media_upload_controller.dart';
import 'package:ascoa_app/shared/controllers/connectivity_controller.dart';

class HotspotReportController extends ChangeNotifier {
  final MediaUploadController mediaUploadController = MediaUploadController(
    storageFolder: 'hotspots',
  );

  String? _hotspotDocId;
  String get hotspotDocId {
    _hotspotDocId ??=
        FirebaseFirestore.instance.collection('plastic_hotspots').doc().id;
    return _hotspotDocId!;
  }

  String location = '';
  double? locationLatitude;
  double? locationLongitude;
  String? locationError;
  String? photosError;
  bool isSubmitting = false;

  bool validate() {
    var isValid = true;
    locationError = null;
    photosError = null;

    final hasLocationText = location.trim().isNotEmpty;
    final hasCoordinates =
        locationLatitude != null && locationLongitude != null;
    if (!hasLocationText && !hasCoordinates) {
      locationError = 'Location is required';
      isValid = false;
    }

    if (!mediaUploadController.hasPhotos) {
      photosError = 'Add at least one hotspot photo';
      isValid = false;
    }

    notifyListeners();
    return isValid;
  }

  Future<String?> submit() async {
    if (!validate()) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      isSubmitting = true;
      notifyListeners();

      final isOnline =
          await Get.find<ConnectivityController>().checkConnectivity();
      if (!isOnline) {
        return _saveOffline(user.uid);
      }

      if (mediaUploadController.hasUploadsInProgress) {
        final completed = await mediaUploadController.waitForUploadsToComplete(
          timeout: const Duration(minutes: 5),
        );
        if (!completed) return null;
      }

      await mediaUploadController.cleanupUnusedPhotos();
      final photoUrls = mediaUploadController.uploadedPhotoUrls;
      if (photoUrls.isEmpty) return null;

      await FirebaseFirestore.instance
          .collection('plastic_hotspots')
          .doc(hotspotDocId)
          .set({
            'userId': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'location': {
              'name': location,
              'latitude': locationLatitude,
              'longitude': locationLongitude,
            },
            'photoUrls': photoUrls,
            'status': 'reported',
          });

      return hotspotDocId;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String?> _saveOffline(String userId) async {
    final localPaths =
        mediaUploadController.photos.map((photo) => photo.file.path).toList();
    final localId = const Uuid().v4();
    final pending = PendingHotspotModel(
      localId: localId,
      userId: userId,
      location: location,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      localPhotoPaths: localPaths,
      createdAt: DateTime.now(),
      savedAt: DateTime.now(),
    );

    final box = await Hive.openBox<PendingHotspotModel>('pending_hotspots');
    await box.put(localId, pending);
    await Get.find<PendingHotspotsController>().loadPendingHotspots();
    return localId;
  }

  void setLocation(String value) {
    location = value;
    locationError = null;
    notifyListeners();
  }

  void setCoordinates(double latitude, double longitude) {
    locationLatitude = latitude;
    locationLongitude = longitude;
    locationError = null;
    notifyListeners();
  }

  Future<void> addPhotos(List<File> files) async {
    await mediaUploadController.addPhotos(files);
    photosError = null;
    notifyListeners();
  }
}
