import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ascoa_app/app/models/cleanup_model.dart';
import 'package:ascoa_app/modules/start_cleanup/controllers/media_upload_controller.dart';
import 'package:get/get.dart';

/// Controller to manage cleanup form state and validation
/// Ensures only one section is expanded at a time
class CleanupFormController extends ChangeNotifier {
  String? _expandedSection;

  // Media upload controller
  final MediaUploadController mediaUploadController = MediaUploadController();

  // Pre-generated cleanup document ID for photo uploads
  String? _cleanupDocId;
  String get cleanupDocId {
    _cleanupDocId ??=
        FirebaseFirestore.instance.collection('cleanups').doc().id;
    return _cleanupDocId!;
  }

  // Basic Information fields
  int peopleCount = 0;
  String groupName = '';
  String date = '';
  String location = '';
  double? locationLatitude;
  double? locationLongitude;

  // Error messages for Basic Information fields
  String? peopleCountError;
  String? groupNameError;
  String? dateError;
  String? _locationError;

  String? get locationError => _locationError;
  set locationError(String? v) {
    _locationError = v;
    notifyListeners();
  }

  // Trash Collected fields
  Set<String> selectedEnvironments = {};
  Map<String, int> trashItems = {}; // itemName -> count

  // Error messages for Trash Collected section
  String? environmentError;
  String? trashItemsError;

  // Trash template data from Firestore
  List<String> categoryOrder = [];
  Map<String, TrashCategory> categories = {};
  bool isLoadingTemplate = false;

  String? get expandedSection => _expandedSection;

  /// Set expanded section (for UI control)
  void setExpandedSection(String? section) {
    _expandedSection = section;
    notifyListeners();
  }

  /// Validate a specific section and return true if valid
  /// This is public so UI can call it before allowing section changes
  bool validateSection(String sectionTitle) {
    final isValid = _validateSection(sectionTitle);
    notifyListeners(); // Update UI to show any errors
    return isValid;
  }

  /// Check validity of a section without mutating error fields or notifying
  /// Useful for pre-flight checks where we want to decide allow/deny actions
  /// but don't want to immediately show error messages.
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
    // Mirror the validation logic but don't set error strings
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

  /// Request to expand a section
  /// Returns true if expansion is allowed, false if validation failed
  Future<bool> requestExpand(String sectionTitle, BuildContext context) async {
    // If same section, just expand
    if (_expandedSection == sectionTitle) {
      return true;
    }

    // If another section is open, validate it first before closing
    if (_expandedSection != null) {
      final isValid = _validateSection(_expandedSection!);
      if (!isValid) {
        notifyListeners(); // Update UI to show errors
        return false; // Don't allow switching
      }
    }

    // All good, allow expansion
    _expandedSection = sectionTitle;
    notifyListeners();
    return true;
  }

  /// Collapse the current section (validate before collapsing)
  Future<bool> collapseSection(BuildContext context) async {
    if (_expandedSection != null) {
      final isValid = _validateSection(_expandedSection!);
      if (!isValid) {
        notifyListeners(); // Update UI to show errors
        return false; // Don't allow collapsing
      }
    }
    _expandedSection = null;
    notifyListeners();
    return true;
  }

  /// Clear all error messages
  void clearErrors() {
    peopleCountError = null;
    groupNameError = null;
    dateError = null;
    locationError = null;
    environmentError = null;
    trashItemsError = null;
    notifyListeners();
  }

  /// Clear specific field errors (call when user is editing)
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

  /// Validate a specific section and set error messages
  /// Returns true if valid, false if errors exist
  bool _validateSection(String sectionTitle) {
    switch (sectionTitle) {
      case 'Basic Information':
        return _validateBasicInformation();
      case 'Trash Collected':
        return _validateTrashCollected();
      case 'Photos & Videos (Optional)':
        return true; // Optional section, always valid
      default:
        return true;
    }
  }

  /// Validate Basic Information section
  /// Sets individual field errors and returns true if all valid
  bool _validateBasicInformation() {
    bool isValid = true;

    // Clear previous errors
    peopleCountError = null;
    groupNameError = null;
    dateError = null;
    locationError = null;

    // Validate people count
    if (peopleCount < 1) {
      peopleCountError = 'Number of people must be at least 1';
      isValid = false;
    }

    // Validate group name
    if (groupName.trim().isEmpty) {
      groupNameError = 'Group name is required';
      isValid = false;
    }

    // Validate date
    if (date.trim().isEmpty) {
      dateError = 'Date is required';
      isValid = false;
    }

    // Validate location
    if (location.trim().isEmpty) {
      locationError = 'Location is required';
      isValid = false;
    }

    return isValid;
  }

  /// Validate Trash Collected section
  /// Sets individual field errors and returns true if all valid
  bool _validateTrashCollected() {
    bool isValid = true;

    // Clear previous errors
    environmentError = null;
    trashItemsError = null;

    // Validate environment selection
    if (selectedEnvironments.isEmpty) {
      environmentError = 'Please select at least one environment';
      isValid = false;
    }

    // Check if at least one item has count > 0
    final hasItems = trashItems.values.any((itemCount) => itemCount > 0);
    if (!hasItems) {
      trashItemsError = 'Please add at least one trash item';
      isValid = false;
    }

    return isValid;
  }

  /// Validate all sections before save
  /// Returns true if all valid, false otherwise (with errors set)
  bool validateAll() {
    final basicValid = _validateBasicInformation();
    final trashValid = _validateTrashCollected();

    notifyListeners(); // Update UI with any errors
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

  /// Submit cleanup data to Firebase
  /// Returns cleanup document ID on success, null on error
  /// Updates user document with cleanup ID
  Future<String?> submitCleanup(String userId) async {
    try {
      // Final validation check
      if (!checkSectionValidity('basicInfo') ||
          !checkSectionValidity('trashCollected')) {
        debugPrint('[SubmitCleanup] Validation failed');
        return null;
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
          Get.snackbar(
            'Upload Error',
            'Some photos failed to upload. Please try again.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
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

      debugPrint('[SubmitCleanup] Success: ${cleanupRef.id}');
      return cleanupRef.id;
    } catch (e) {
      debugPrint('[SubmitCleanup] Error: $e');
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
