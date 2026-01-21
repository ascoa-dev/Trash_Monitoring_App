import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ascoa_app/app/models/cleanup_model.dart';
import 'package:ascoa_app/app/models/pending_cleanup_model.dart';
import 'package:ascoa_app/modules/start_cleanup/controllers/media_upload_controller.dart';
import 'package:ascoa_app/shared/controllers/connectivity_controller.dart';
import 'package:ascoa_app/shared/services/snackbar_service.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:ascoa_app/shared/analytics/analytics_service.dart';
import 'package:ascoa_app/app/controllers/pending_cleanups_controller.dart';

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
      case 'Basic Information':
        _basicInfoCompleted = true;
        Analytics.track(AnalyticsEvents.cleanupSectionCompleted, {
          AnalyticsProps.section: CleanupSections.basicInfo,
        });
        break;
      case 'Trash Collected':
        _trashCollectedCompleted = true;
        Analytics.track(AnalyticsEvents.cleanupSectionCompleted, {
          AnalyticsProps.section: CleanupSections.trashCollected,
        });
        break;
      case 'Photos & Videos (Optional)':
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
      case 'Basic Information':
        _basicInfoCompleted = false;
        _trashCollectedCompleted = false;
        _photosCompleted = false;
        break;
      case 'Trash Collected':
        _trashCollectedCompleted = false;
        _photosCompleted = false;
        break;
      case 'Photos & Videos (Optional)':
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

  bool validateSection(String sectionTitle) {
    final isValid = _validateSection(sectionTitle);
    notifyListeners();
    return isValid;
  }

  bool checkSectionValidity(String sectionTitle) {
    switch (sectionTitle) {
      case 'Basic Information':
        return _isBasicInformationValidWithoutErrors();
      case 'Trash Collected':
        return _isTrashCollectedValidWithoutErrors();
      case 'Photos & Videos (Optional)':
        return true;
      default:
        return true;
    }
  }

  bool _isBasicInformationValidWithoutErrors() {
    if (peopleCount < 1) return false;
    if (groupName.trim().isEmpty) return false;
    if (date.trim().isEmpty) return false;
    if (location.trim().isEmpty) return false;
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
      case 'Basic Information':
        return _validateBasicInformation();
      case 'Trash Collected':
        return _validateTrashCollected();
      case 'Photos & Videos (Optional)':
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
      peopleCountError = 'Number of people must be at least 1';
      isValid = false;
    }

    if (groupName.trim().isEmpty) {
      groupNameError = 'Group name is required';
      isValid = false;
    }

    if (date.trim().isEmpty) {
      dateError = 'Date is required';
      isValid = false;
    }

    final hasTextLocation = location.trim().isNotEmpty;
    final hasCoordinates =
        locationLatitude != null && locationLongitude != null;

    if (!hasTextLocation && !hasCoordinates) {
      locationError = 'Location is required';
      isValid = false;
    }

    return isValid;
  }

  bool _validateTrashCollected() {
    bool isValid = true;

    environmentError = null;
    trashItemsError = null;

    if (selectedEnvironments.isEmpty) {
      environmentError = 'Please select at least one environment';
      isValid = false;
    }

    final hasItems = trashItems.values.any((itemCount) => itemCount > 0);
    if (!hasItems) {
      trashItemsError = 'Please add at least one trash item';
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

  /// Submit cleanup data to Firebase or save offline
  /// Returns cleanup document ID on success, null on error
  /// If offline, saves to Hive for later upload
  Future<String?> submitCleanup(String userId) async {
    try {
      // Final validation check
      if (!checkSectionValidity('Basic Information') ||
          !checkSectionValidity('Trash Collected')) {
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

      // If there are uploads in progress, wait for them to complete
      if (mediaUploadController.hasUploadsInProgress) {
        debugPrint('[SubmitCleanup] Waiting for photo uploads to complete...');
        final uploadSuccess = await mediaUploadController
            .waitForUploadsToComplete(timeout: const Duration(minutes: 5));

        if (!uploadSuccess) {
          debugPrint(
            '[SubmitCleanup] Photo uploads did not complete successfully',
          );
          SnackbarService.error(
            'Upload Error',
            'Some photos failed to upload. Please try again.',
          );
          // You might want to show an error to the user here
          // For now, we'll continue anyway with whatever uploaded
        }
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
      ).copyWith(photoUrls: photoUrls.isNotEmpty ? photoUrls : null);

      // Use a batch for atomic operation
      final batch = firestore.batch();

      // Create cleanup document
      batch.set(cleanupRef, cleanup.toFirestore());

      // Update user document with cleanup ID
      final userRef = firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'cleanups': FieldValue.arrayUnion([cleanupRef.id]),
      });

      // Commit the batch
      await batch.commit();

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
    } catch (e) {
      Analytics.track(AnalyticsEvents.cleanupSubmitFailed, {
        AnalyticsProps.reason: e.toString(),
        AnalyticsProps.isOffline: false,
      });
      Analytics.error(e, null);
      debugPrint('[SubmitCleanup] Error: $e');
      return null;
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
          mediaUploadController.photos.map((photo) => photo.file.path).toList();

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

      // Save to Hive
      final box = await Hive.openBox<PendingCleanupModel>('pending_cleanups');
      await box.put(localId, pendingCleanup);

      // Immediately update the pending cleanups list so badge updates
      await pendingController.loadPendingCleanups();

      // Track offline submission
      Analytics.track(AnalyticsEvents.cleanupSubmitted, {
        AnalyticsProps.cleanupId: localId,
        AnalyticsProps.isOffline: true,
        AnalyticsProps.photosCount: localPhotoPaths.length,
        AnalyticsProps.environment: environmentType,
      });

      debugPrint('[SubmitCleanup] Saved offline with ID: $localId');
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
