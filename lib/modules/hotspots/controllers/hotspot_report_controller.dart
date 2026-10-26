import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:we_monitor/shared/services/pending_upload_service.dart';
import 'package:we_monitor/app/controllers/pending_hotspots_controller.dart';
import 'package:we_monitor/app/models/pending_hotspot_model.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/media_upload_controller.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';
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
      photosError = 'hotspot.photoRequired'.tr;
      isValid = false;
    }

    notifyListeners();
    return isValid;
  }

  /// True when the last successful [submit] queued the report in Hive
  /// instead of writing it to Firestore.
  bool savedOffline = false;

  Future<String?> submit() async {
    if (!validate()) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Analytics.log('[Hotspot] submit without signed-in user');
      return null;
    }

    savedOffline = false;
    try {
      isSubmitting = true;
      notifyListeners();

      final isOnline =
          await Get.find<ConnectivityController>().checkConnectivity();
      if (!isOnline) {
        return await _saveOffline(user.uid);
      }

      try {
        return await _saveOnline(user.uid);
      } catch (e, st) {
        // Bad signal or server error: queue it instead of losing the report.
        // The pending queue retries and reuses photos uploaded so far.
        Analytics.error(e, st, reason: 'hotspot online submit failed');
        return await _saveOffline(user.uid);
      }
    } catch (e, st) {
      Analytics.error(e, st, reason: 'hotspot submit failed');
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String> _saveOnline(String userId) async {
    final media = mediaUploadController;
    // Start anything added offline or failed; the wait below bounds it.
    media.compressAndUploadAll(hotspotDocId);
    if (media.hasUploadsInProgress &&
        !await media.waitForUploadsToComplete(
          timeout: const Duration(minutes: 2),
        )) {
      throw StateError('photo uploads timed out');
    }

    final notUploaded =
        media.photos
            .where(
              (p) =>
                  p.status != PhotoUploadStatus.completed &&
                  p.status != PhotoUploadStatus.cancelled,
            )
            .toList();
    if (notUploaded.isNotEmpty) {
      throw StateError(
        '${notUploaded.length} photo(s) not uploaded: '
        '${notUploaded.map((p) => p.error ?? p.status.name).join('; ')}',
      );
    }

    await media.cleanupUnusedPhotos();
    await FirebaseFirestore.instance
        .collection('plastic_hotspots')
        .doc(hotspotDocId)
        .set({
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'location': {
            'name': location,
            'latitude': locationLatitude,
            'longitude': locationLongitude,
          },
          'photoUrls': media.uploadedPhotoUrls,
          'thumbUrls': media.uploadedThumbUrls,
          'status': 'reported',
        })
        // Same doc id as the queued fallback, so a late commit is harmless.
        .timeout(const Duration(seconds: 30));
    return hotspotDocId;
  }

  Future<String?> _saveOffline(String userId) async {
    savedOffline = true;
    final localPaths =
        mediaUploadController.photos
            .where((photo) => photo.status != PhotoUploadStatus.cancelled)
            .map((photo) => photo.file.path)
            .toList();
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
    // Same doc id as the form, so already-uploaded photos are reused.
    final uploaded = alreadyUploaded(mediaUploadController.photos);
    pending
      ..docId = hotspotDocId
      ..uploadedFull = uploaded.full
      ..uploadedThumb = uploaded.thumb;

    final box = await Hive.openBox<PendingHotspotModel>('pending_hotspots');
    await box.put(localId, pending);
    await Get.find<PendingHotspotsController>().loadPendingHotspots();
    PendingUploadService.instance.kick();
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
