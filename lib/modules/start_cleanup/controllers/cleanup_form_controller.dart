import 'package:we_monitor/modules/start_cleanup/controllers/cleanup_section_ids.dart';
import 'package:flutter/material.dart';
import 'package:we_monitor/shared/services/pending_upload_service.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:we_monitor/app/models/cleanup_model.dart';
import 'package:we_monitor/app/models/pending_cleanup_model.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/media_upload_controller.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/drafts/form_draft.dart';
import 'package:we_monitor/shared/services/draft_service.dart';
import 'package:we_monitor/shared/services/location_validator.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';
import 'package:we_monitor/app/controllers/pending_cleanups_controller.dart';

class CleanupFormController extends ChangeNotifier {
  String? _expandedSection;

  final MediaUploadController mediaUploadController = MediaUploadController();

  // Track which sections have been completed (validated via Next button)
  bool _basicInfoCompleted = false;
  bool _trashCollectedCompleted = false;
  bool _photosCompleted = false; // Photos is optional but we track navigation

  bool get basicInfoCompleted => _basicInfoCompleted;
  bool get trashCollectedCompleted => _trashCollectedCompleted;
  bool get photosCompleted => _photosCompleted;

  /// Check if all required sections are completed for submit button
  bool get canSubmit =>
      _basicInfoCompleted && _trashCollectedCompleted && _photosCompleted;

  /// Mark a section as completed
  void markSectionCompleted(String sectionTitle) {
    switch (sectionTitle) {
      case CleanupSectionIds.basicInformation:
        _basicInfoCompleted = true;
        Analytics.track(AnalyticsEvents.cleanupSectionCompleted, {
          AnalyticsProps.section: CleanupSections.basicInfo,
        });
        break;
      case CleanupSectionIds.trashCollected:
        _trashCollectedCompleted = true;
        Analytics.track(AnalyticsEvents.cleanupSectionCompleted, {
          AnalyticsProps.section: CleanupSections.trashCollected,
        });
        break;
      case CleanupSectionIds.photosVideosOptional:
        _photosCompleted = true;
        Analytics.track(AnalyticsEvents.cleanupSectionCompleted, {
          AnalyticsProps.section: CleanupSections.photosVideos,
        });
        break;
    }
    notifyListeners();
  }

  /// Reset section completion status (used when editing)
  void resetSectionCompletion(String sectionTitle) {
    switch (sectionTitle) {
      case CleanupSectionIds.basicInformation:
        _basicInfoCompleted = false;
        _trashCollectedCompleted = false;
        _photosCompleted = false;
        break;
      case CleanupSectionIds.trashCollected:
        _trashCollectedCompleted = false;
        _photosCompleted = false;
        break;
      case CleanupSectionIds.photosVideosOptional:
        _photosCompleted = false;
        break;
    }
    notifyListeners();
  }

  String? _cleanupDocId;
  String get cleanupDocId {
    _cleanupDocId ??=
        FirebaseFirestore.instance.collection('cleanups').doc().id;
    return _cleanupDocId!;
  }

  int peopleCount = 0;
  String groupName = '';
  String date = '';
  String location = '';
  double? locationLatitude;
  double? locationLongitude;
  bool locationVerified = false;

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

  void setPickedLocation(PickedLocation loc) {
    location = loc.address;
    locationLatitude = loc.latitude;
    locationLongitude = loc.longitude;
    locationVerified = loc.verified;
    _locationError = null;
    notifyListeners();
  }

  String? peopleCountError;
  String? groupNameError;
  String? dateError;
  String? _locationError;

  String? get locationError => _locationError;
  set locationError(String? v) {
    _locationError = v;
    notifyListeners();
  }

  Set<String> selectedEnvironments = {};
  Map<String, int> trashItems = {};

  String? environmentError;
  String? trashItemsError;

  List<String> categoryOrder = [];
  Map<String, TrashCategory> categories = {};
  bool isLoadingTemplate = false;

  String? get expandedSection => _expandedSection;

  void setExpandedSection(String? section) {
    _expandedSection = section;
    notifyListeners();
  }

  /// Snapshot of the whole form for draft auto-save.
  FormDraft toDraft() => FormDraft(
    kind: FormDraft.kindCleanup,
    docId: cleanupDocId,
    savedAt: DateTime.now(),
    peopleCount: peopleCount,
    groupName: groupName,
    date: date,
    location: location,
    locationLatitude: locationLatitude,
    locationLongitude: locationLongitude,
    locationVerified: locationVerified,
    selectedEnvironments: {...selectedEnvironments},
    trashItems: {...trashItems},
    basicInfoCompleted: _basicInfoCompleted,
    trashCollectedCompleted: _trashCollectedCompleted,
    photosCompleted: _photosCompleted,
    expandedSection: _expandedSection,
    photos: DraftService.photosOf(mediaUploadController),
  );

  /// Restores a saved draft. Must run before the section widgets are (re)built.
  void applyDraft(FormDraft draft) {
    _cleanupDocId = draft.docId;
    peopleCount = draft.peopleCount;
    groupName = draft.groupName;
    date = draft.date;
    location = draft.location;
    locationLatitude = draft.locationLatitude;
    locationLongitude = draft.locationLongitude;
    locationVerified = draft.locationVerified;
    selectedEnvironments
      ..clear()
      ..addAll(draft.selectedEnvironments);
    trashItems
      ..clear()
      ..addAll(draft.trashItems);
    _basicInfoCompleted = draft.basicInfoCompleted;
    _trashCollectedCompleted = draft.trashCollectedCompleted;
    _photosCompleted = draft.photosCompleted;
    _expandedSection = draft.expandedSection;
    DraftService.restorePhotos(
      mediaUploadController,
      draft.photos,
      draft.docId,
    );
    notifyListeners();
  }

  bool validateSection(String sectionTitle) {
    final isValid = _validateSection(sectionTitle);
    notifyListeners();
    return isValid;
  }

  bool checkSectionValidity(String sectionTitle) {
    switch (sectionTitle) {
      case CleanupSectionIds.basicInformation:
        return _isBasicInformationValidWithoutErrors();
      case CleanupSectionIds.trashCollected:
        return _isTrashCollectedValidWithoutErrors();
      case CleanupSectionIds.photosVideosOptional:
        return true;
      default:
        return true;
    }
  }

  bool _isBasicInformationValidWithoutErrors() {
    if (peopleCount < 1) return false;
    if (groupName.trim().isEmpty) return false;
    if (date.trim().isEmpty) return false;
    if (pickedLocation == null) return false;
    return true;
  }

  bool _isTrashCollectedValidWithoutErrors() {
    if (selectedEnvironments.isEmpty) return false;
    final hasItems = trashItems.values.any((itemCount) => itemCount > 0);
    if (!hasItems) return false;
    return true;
  }

  Future<bool> requestExpand(String sectionTitle, BuildContext context) async {
    if (_expandedSection == sectionTitle) {
      return true;
    }

    if (_expandedSection != null) {
      final isValid = _validateSection(_expandedSection!);
      if (!isValid) {
        notifyListeners();
        return false;
      }
    }

    _expandedSection = sectionTitle;
    notifyListeners();
    return true;
  }

  Future<bool> collapseSection(BuildContext context) async {
    if (_expandedSection != null) {
      final isValid = _validateSection(_expandedSection!);
      if (!isValid) {
        notifyListeners();
        return false;
      }
    }
    _expandedSection = null;
    notifyListeners();
    return true;
  }

  void clearErrors() {
    peopleCountError = null;
    groupNameError = null;
    dateError = null;
    locationError = null;
    environmentError = null;
    trashItemsError = null;
    notifyListeners();
  }

  void clearFieldError(String fieldName) {
    switch (fieldName) {
      case 'peopleCount':
        peopleCountError = null;
        break;
      case 'groupName':
        groupNameError = null;
        break;
      case 'date':
        dateError = null;
        break;
      case 'location':
        locationError = null;
        break;
      case 'environment':
        environmentError = null;
        break;
      case 'trashItems':
        trashItemsError = null;
        break;
    }
    notifyListeners();
  }

  bool _validateSection(String sectionTitle) {
    switch (sectionTitle) {
      case CleanupSectionIds.basicInformation:
        return _validateBasicInformation();
      case CleanupSectionIds.trashCollected:
        return _validateTrashCollected();
      case CleanupSectionIds.photosVideosOptional:
        return true;
      default:
        return true;
    }
  }

  bool _validateBasicInformation() {
    bool isValid = true;
    peopleCountError = null;
    groupNameError = null;
    dateError = null;
    locationError = null;
    if (peopleCount < 1) {
      peopleCountError = 'cleanup.errPeopleMin'.tr;
      isValid = false;
    }

    if (groupName.trim().isEmpty) {
      groupNameError = 'cleanup.errGroupRequired'.tr;
      isValid = false;
    }

    if (date.trim().isEmpty) {
      dateError = 'cleanup.errDateRequired'.tr;
      isValid = false;
    }

    // Coordinates are required: free text alone can't be put on the map.
    if (pickedLocation == null) {
      _locationError = AppStrings.locationRequired;
      isValid = false;
    }

    return isValid;
  }

  bool _validateTrashCollected() {
    bool isValid = true;

    environmentError = null;
    trashItemsError = null;

    if (selectedEnvironments.isEmpty) {
      environmentError = 'cleanup.errEnvironment'.tr;
      isValid = false;
    }

    final hasItems = trashItems.values.any((itemCount) => itemCount > 0);
    if (!hasItems) {
      trashItemsError = 'cleanup.errTrashItem'.tr;
      isValid = false;
    }

    return isValid;
  }

  bool validateAll() {
    final basicValid = _validateBasicInformation();
    final trashValid = _validateTrashCollected();

    notifyListeners();
    return basicValid && trashValid;
  }

  /// Get weight information for all selected trash items
  Map<String, double> _getItemWeights() {
    final weights = <String, double>{};

    for (final itemName in trashItems.keys) {
      // Find which category contains this item
      for (final category in categories.values) {
        if (category.items.containsKey(itemName)) {
          weights[itemName] = category.items[itemName]!;
          break;
        }
      }
    }

    return weights;
  }

  /// Get category mapping for all selected trash items
  Map<String, String> _getItemCategories() {
    final itemCategories = <String, String>{};

    for (final itemName in trashItems.keys) {
      // Find which category contains this item
      for (final entry in categories.entries) {
        if (entry.value.items.containsKey(itemName)) {
          itemCategories[itemName] = entry.value.name; // Use display name
          break;
        }
      }
    }

    return itemCategories;
  }

  /// True when the last successful [submitCleanup] queued the cleanup in
  /// Hive instead of writing it to Firestore.
  bool savedOffline = false;

  /// Submit cleanup data to Firebase or save offline
  /// Returns cleanup document ID on success, null on error
  /// If offline, saves to Hive for later upload
  Future<String?> submitCleanup(String userId) async {
    savedOffline = false;
    try {
      // Final validation check
      if (!checkSectionValidity(CleanupSectionIds.basicInformation) ||
          !checkSectionValidity(CleanupSectionIds.trashCollected)) {
        debugPrint('[SubmitCleanup] Validation failed');
        return null;
      }

      // Check connectivity
      final connectivityController = Get.find<ConnectivityController>();
      final isOnline = await connectivityController.checkConnectivity();

      if (!isOnline) {
        // Save offline
        return await _saveCleanupOffline(userId);
      }

      // Start anything added offline or failed, then wait for all uploads
      mediaUploadController.compressAndUploadAll(cleanupDocId);
      if (mediaUploadController.hasUploadsInProgress) {
        debugPrint('[SubmitCleanup] Waiting for photo uploads to complete...');
        await mediaUploadController.waitForUploadsToComplete(
          timeout: const Duration(minutes: 2),
        );
      }

      // Photos still not uploaded (bad signal): queue the whole cleanup so
      // they aren't dropped. The pending queue retries and reuses uploads.
      final notUploaded =
          mediaUploadController.photos
              .where(
                (p) =>
                    p.status != PhotoUploadStatus.completed &&
                    p.status != PhotoUploadStatus.cancelled,
              )
              .toList();
      if (notUploaded.isNotEmpty) {
        Analytics.error(
          StateError(
            '${notUploaded.length} photo(s) not uploaded: '
            '${notUploaded.map((p) => p.error ?? p.status.name).join('; ')}',
          ),
          StackTrace.current,
          reason: 'cleanup photos not uploaded, queued offline',
        );
        return await _saveCleanupOffline(userId);
      }

      // Clean up any photos that were uploaded but then removed
      await mediaUploadController.cleanupUnusedPhotos();

      // Get item weights from template
      final itemWeights = _getItemWeights();

      // Get item categories
      final itemCategories = _getItemCategories();

      // Get environment type (first selected or null)
      final environmentType =
          selectedEnvironments.isNotEmpty ? selectedEnvironments.first : null;

      // Validate environment is selected
      if (environmentType == null) {
        debugPrint('[SubmitCleanup] No environment selected');
        return null;
      }

      final firestore = FirebaseFirestore.instance;

      // Use the pre-generated cleanup document ID (same one used for photo uploads)
      final cleanupRef = firestore.collection('cleanups').doc(cleanupDocId);

      // Photos should already be uploaded by now (uploaded immediately after selection)
      // Just get the URLs
      final photoUrls = mediaUploadController.uploadedPhotoUrls;
      final thumbUrls = mediaUploadController.uploadedThumbUrls;
      debugPrint(
        '[SubmitCleanup] Photos already uploaded: ${photoUrls.length}',
      );

      // Create cleanup model from form data
      final cleanup = CleanupModel.fromFormData(
        userId: userId,
        peopleCount: peopleCount,
        groupName: groupName,
        date: date,
        location: location,
        locationLatitude: locationLatitude,
        locationLongitude: locationLongitude,
        environment: environmentType,
        trashItems: trashItems,
        itemWeights: itemWeights,
        itemCategories: itemCategories,
      ).copyWith(
        photoUrls: photoUrls.isNotEmpty ? photoUrls : null,
        thumbUrls: photoUrls.isNotEmpty ? thumbUrls : null,
      );

      // Use a batch for atomic operation
      final batch = firestore.batch();

      // Create cleanup document
      batch.set(cleanupRef, cleanup.toFirestore());

      // Update user document with cleanup ID
      final userRef = firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'cleanups': FieldValue.arrayUnion([cleanupRef.id]),
      });

      // Fixed doc id: if this times out but commits later, the queued copy
      // finds the doc and skips it.
      await batch.commit().timeout(const Duration(seconds: 30));

      // Track successful submission
      Analytics.track(AnalyticsEvents.cleanupSubmitted, {
        AnalyticsProps.cleanupId: cleanupRef.id,
        AnalyticsProps.isOffline: false,
        AnalyticsProps.photosCount: photoUrls.length,
        AnalyticsProps.trashKg: cleanup.totalWeight,
        AnalyticsProps.environment: environmentType,
      });

      debugPrint('[SubmitCleanup] Success: ${cleanupRef.id}');
      return cleanupRef.id;
    } catch (e, st) {
      Analytics.track(AnalyticsEvents.cleanupSubmitFailed, {
        AnalyticsProps.reason: e.toString(),
        AnalyticsProps.isOffline: false,
      });
      Analytics.error(e, st, reason: 'cleanup online submit failed, queued');
      debugPrint('[SubmitCleanup] Error: $e, saving offline instead');
      // Bad signal or server error: queue it instead of losing the cleanup.
      return _saveCleanupOffline(userId);
    }
  }

  void loadTrashCollectedForEdit(CleanupModel cleanup) {
    groupName = cleanup.groupName;
    selectedEnvironments
      ..clear()
      ..add(cleanup.environment);
    trashItems.clear();

    cleanup.categories.forEach((_, items) {
      items.forEach((itemName, item) {
        if (item.quantity > 0) {
          trashItems[itemName] = item.quantity;
        }
      });
    });

    _trashCollectedCompleted = true;
    notifyListeners();
  }

  Future<bool> updateCleanupTrashCollected(String cleanupId) async {
    if (groupName.trim().isEmpty) {
      notifyListeners();
      return false;
    }
    if (!_validateTrashCollected()) {
      notifyListeners();
      return false;
    }

    try {
      final environmentType =
          selectedEnvironments.isNotEmpty ? selectedEnvironments.first : null;
      if (environmentType == null) return false;

      final cleanup = CleanupModel.fromFormData(
        userId: '',
        peopleCount: 1,
        groupName: groupName,
        date: '',
        location: '',
        environment: environmentType,
        trashItems: trashItems,
        itemWeights: _getItemWeights(),
        itemCategories: _getItemCategories(),
      );

      final trashCollected = cleanup.toFirestore()['trashCollected'];
      await FirebaseFirestore.instance
          .collection('cleanups')
          .doc(cleanupId)
          .update({
            'trashCollected': trashCollected,
            'basicInfo.groupName': groupName,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      debugPrint('[CleanupEdit] Error updating trash collected: $e');
      return false;
    }
  }

  /// Save cleanup offline to Hive for later upload
  Future<String?> _saveCleanupOffline(String userId) async {
    try {
      debugPrint('[SubmitCleanup] Saving offline...');
      final pendingController = Get.find<PendingCleanupsController>();

      // Get item weights from template
      final itemWeights = _getItemWeights();

      // Get item categories
      final itemCategories = _getItemCategories();

      // Get environment type (first selected or null)
      final environmentType =
          selectedEnvironments.isNotEmpty ? selectedEnvironments.first : null;

      // Validate environment is selected
      if (environmentType == null) {
        debugPrint('[SubmitCleanup] No environment selected');
        return null;
      }

      // Get local photo paths from media controller
      final localPhotoPaths =
          mediaUploadController.photos
              .where((photo) => photo.status != PhotoUploadStatus.cancelled)
              .map((photo) => photo.file.path)
              .toList();

      // Generate a unique local ID
      const uuid = Uuid();
      final localId = uuid.v4();

      // Create pending cleanup model
      final pendingCleanup = PendingCleanupModel.fromFormData(
        localId: localId,
        userId: userId,
        peopleCount: peopleCount,
        groupName: groupName,
        date: date,
        location: location,
        locationLatitude: locationLatitude,
        locationLongitude: locationLongitude,
        environment: environmentType,
        trashItems: trashItems,
        itemWeights: itemWeights,
        itemCategories: itemCategories,
        localPhotoPaths: localPhotoPaths.isNotEmpty ? localPhotoPaths : null,
      );

      // Same doc id as the form, so photos it already uploaded land in the
      // same Storage folder and are reused rather than uploaded again.
      final uploaded = alreadyUploaded(mediaUploadController.photos);
      pendingCleanup
        ..docId = cleanupDocId
        ..uploadedFull = uploaded.full
        ..uploadedThumb = uploaded.thumb;

      // Save to Hive
      final box = await Hive.openBox<PendingCleanupModel>('pending_cleanups');
      await box.put(localId, pendingCleanup);

      // Immediately update the pending cleanups list so badge updates
      await pendingController.loadPendingCleanups();
      PendingUploadService.instance.kick();

      // Track offline submission
      Analytics.track(AnalyticsEvents.cleanupSubmitted, {
        AnalyticsProps.cleanupId: localId,
        AnalyticsProps.isOffline: true,
        AnalyticsProps.photosCount: localPhotoPaths.length,
        AnalyticsProps.environment: environmentType,
      });

      debugPrint('[SubmitCleanup] Saved offline with ID: $localId');
      savedOffline = true;
      return localId;
    } catch (e) {
      Analytics.track(AnalyticsEvents.cleanupSubmitFailed, {
        AnalyticsProps.reason: e.toString(),
        AnalyticsProps.isOffline: true,
      });
      Analytics.error(e, null);
      debugPrint('[SubmitCleanup] Error saving offline: $e');
      return null;
    }
  }

  /// Fetch trash template from Firestore
  Future<void> fetchTrashTemplate() async {
    isLoadingTemplate = true;
    notifyListeners();
    debugPrint('[TrashTemplate] Starting fetch...');

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('app-templates')
              .doc('trash_template')
              .get();

      debugPrint('[TrashTemplate] Document exists: ${doc.exists}');

      if (doc.exists) {
        final data = doc.data()!;
        debugPrint('[TrashTemplate] Data keys: ${data.keys}');

        // Parse category order
        categoryOrder = List<String>.from(data['categoryOrder'] ?? []);
        debugPrint('[TrashTemplate] Category order: $categoryOrder');

        // Parse categories
        final categoriesData = data['categories'] as Map<String, dynamic>;
        debugPrint(
          '[TrashTemplate] Categories data keys: ${categoriesData.keys}',
        );

        categories = {};

        categoriesData.forEach((key, value) {
          final categoryData = value as Map<String, dynamic>;
          final items = <String, double>{};

          final itemsData = categoryData['items'] as Map<String, dynamic>;
          itemsData.forEach((itemName, weight) {
            items[itemName] = (weight as num).toDouble();
          });

          categories[key] = TrashCategory(
            name: categoryData['name'] as String,
            items: items,
          );
          debugPrint(
            '[TrashTemplate] Loaded category: ${categoryData['name']} with ${items.length} items',
          );
        });

        debugPrint(
          '[TrashTemplate] Total categories loaded: ${categories.length}',
        );
      } else {
        debugPrint('[TrashTemplate] Document does not exist!');
      }
    } catch (e) {
      debugPrint('Error fetching trash template: $e');
    } finally {
      isLoadingTemplate = false;
      notifyListeners();
      debugPrint(
        '[TrashTemplate] Fetch complete. Categories: ${categories.length}',
      );
    }
  }

  /// Get ordered categories for display
  List<MapEntry<String, TrashCategory>> getOrderedCategories() {
    final ordered = <MapEntry<String, TrashCategory>>[];

    // categoryOrder contains display names, but we need to find the matching key
    for (final displayName in categoryOrder) {
      // Find the category with this display name
      final entry = categories.entries.firstWhere(
        (e) => e.value.name == displayName,
        orElse: () => MapEntry('', TrashCategory(name: '', items: {})),
      );

      if (entry.key.isNotEmpty) {
        ordered.add(entry);
        debugPrint(
          '[TrashTemplate] Ordering: ${entry.value.name} (${entry.key})',
        );
      } else {
        debugPrint(
          '[TrashTemplate] WARNING: No category found for "$displayName"',
        );
      }
    }

    debugPrint(
      '[TrashTemplate] getOrderedCategories returning ${ordered.length} categories',
    );
    return ordered;
  }
}

/// Model for trash category
class TrashCategory {
  final String name;
  final Map<String, double> items; // itemName -> weight in kg

  TrashCategory({required this.name, required this.items});
}
