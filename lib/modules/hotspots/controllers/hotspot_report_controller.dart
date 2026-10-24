import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:we_monitor/app/controllers/pending_hotspots_controller.dart';
import 'package:we_monitor/app/models/pending_hotspot_model.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/media_upload_controller.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/drafts/form_draft.dart';
import 'package:we_monitor/shared/services/draft_service.dart';
import 'package:we_monitor/shared/services/location_validator.dart';

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
  bool locationVerified = false;
  String? locationError;

  /// The chosen location, or null until the user explicitly picks one.
  PickedLocation? get pickedLocation =>
      (locationLatitude == null || locationLongitude == null)
          ? null
          : PickedLocation(
            latitude: locationLatitude!,
            longitude: locationLongitude!,
            address: location,
            verified: locationVerified,
          );
  String? photosError;
  bool isSubmitting = false;

  bool validate() {
    var isValid = true;
    locationError = null;
    photosError = null;

    // Coordinates are required: free text alone can't be put on the map.
    if (pickedLocation == null) {
      locationError = AppStrings.locationRequired;
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
      final thumbUrls = mediaUploadController.uploadedThumbUrls;
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
            'thumbUrls': thumbUrls,
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

  void setPickedLocation(PickedLocation loc) {
    location = loc.address;
    locationLatitude = loc.latitude;
    locationLongitude = loc.longitude;
    locationVerified = loc.verified;
    locationError = null;
    notifyListeners();
  }

  /// Snapshot of the form for draft auto-save.
  FormDraft toDraft() => FormDraft(
    kind: FormDraft.kindHotspot,
    docId: hotspotDocId,
    savedAt: DateTime.now(),
    location: location,
    locationLatitude: locationLatitude,
    locationLongitude: locationLongitude,
    locationVerified: locationVerified,
    photos: DraftService.photosOf(mediaUploadController),
  );

  void applyDraft(FormDraft draft) {
    _hotspotDocId = draft.docId;
    location = draft.location;
    locationLatitude = draft.locationLatitude;
    locationLongitude = draft.locationLongitude;
    locationVerified = draft.locationVerified;
    DraftService.restorePhotos(
      mediaUploadController,
      draft.photos,
      draft.docId,
    );
    notifyListeners();
  }

  void setLocationError(String? error) {
    locationError = error;
    notifyListeners();
  }

  Future<void> addPhotos(List<File> files) async {
    await mediaUploadController.addPhotos(files);
    photosError = null;
    notifyListeners();
  }
}
