import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:we_monitor/app/models/cleanup_model.dart';
import 'package:we_monitor/app/models/cached_cleanup_model.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';

class StatsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityController _connectivityController =
      Get.find<ConnectivityController>();

  // Observable state
  final RxList<CleanupModel> allCleanups = <CleanupModel>[].obs;
  final RxList<CleanupModel> filteredCleanups = <CleanupModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxBool isLoadingFromCache = false.obs;
  bool _hasInitialized = false;

  // Filter state
  final RxSet<String> selectedEnvironments = <String>{'All'}.obs;
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);
  final RxList<DateTime> availableDates = <DateTime>[].obs;

  // Hive box for caching
  Box<CachedCleanupModel>? _cacheBox;

  // Computed stats
  int get totalCleanups => filteredCleanups.length;

  double get totalTrashKg => filteredCleanups.fold(
    0.0,
    (total, cleanup) => total + cleanup.totalWeight,
  );

  @override
  void onInit() {
    super.onInit();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    try {
      // Open Hive box for cached cleanups
      _cacheBox = await Hive.openBox<CachedCleanupModel>('cached_cleanups');

      // Load from cache first for instant display
      await _loadFromCache();

      // Then fetch fresh data if online
      if (_connectivityController.isOnline.value) {
        await fetchCleanups();
      } else {
        isLoading.value = false;
        if (allCleanups.isEmpty) {
          error.value = AppStrings.statsErrorNoCachedData;
        }
      }
    } catch (e) {
      error.value = '${AppStrings.statsErrorFailedInit}: $e';
      isLoading.value = false;
    } finally {
      _hasInitialized = true;
    }
  }

  /// Load cleanups from Hive cache
  Future<void> _loadFromCache() async {
    try {
      isLoadingFromCache.value = true;

      if (_cacheBox == null || _cacheBox!.isEmpty) {
        return;
      }

      final user = _auth.currentUser;
      if (user == null) return;

      // Get cached cleanups for current user
      final cachedCleanups =
          _cacheBox!.values
              .where((cached) => cached.userId == user.uid)
              .map((cached) => cached.toCleanupModel())
              .toList();

      if (cachedCleanups.isNotEmpty) {
        allCleanups.value = cachedCleanups;
        _updateAvailableDates();
        applyFilters();
      }
    } catch (e) {
      debugPrint('[StatsController] Error loading from cache: $e');
    } finally {
      isLoadingFromCache.value = false;
    }
  }

  /// Save cleanups to Hive cache
  Future<void> _saveToCache(List<CleanupModel> cleanups) async {
    try {
      if (_cacheBox == null) return;

      final user = _auth.currentUser;
      if (user == null) return;

      // Clear existing cache for this user
      final keysToDelete =
          _cacheBox!.keys.where((key) {
            final cached = _cacheBox!.get(key);
            return cached?.userId == user.uid;
          }).toList();

      for (final key in keysToDelete) {
        await _cacheBox!.delete(key);
      }

      // Save new cleanups to cache
      for (final cleanup in cleanups) {
        final cached = CachedCleanupModel.fromCleanupModel(cleanup);
        await _cacheBox!.put(cleanup.id, cached);
      }

      debugPrint('[StatsController] Cached ${cleanups.length} cleanups');
    } catch (e) {
      debugPrint('[StatsController] Error saving to cache: $e');
    }
  }

  Future<void> fetchCleanups() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Check connectivity
      final isConnected = await _connectivityController.checkConnectivity();
      if (!isConnected) {
        error.value = AppStrings.statsErrorNoInternet;
        isLoading.value = false;
        return;
      }

      final user = _auth.currentUser;
      if (user == null) {
        error.value = AppStrings.statsErrorNotAuthenticated;
        return;
      }

      // Fetch cleanups for the current user
      final querySnapshot =
          await _firestore
              .collection('cleanups')
              .where('userId', isEqualTo: user.uid)
              .get();

      // Sort client-side to avoid needing Firestore composite index
      final fetchedCleanups =
          querySnapshot.docs
              .map((doc) => CleanupModel.fromFirestore(doc))
              .toList()
            ..sort((a, b) {
              // Parse dates for comparison (dd/mm/yyyy format)
              final partsA = a.date.split('/');
              final partsB = b.date.split('/');
              if (partsA.length == 3 && partsB.length == 3) {
                final dateA = DateTime(
                  int.parse(partsA[2]),
                  int.parse(partsA[1]),
                  int.parse(partsA[0]),
                );
                final dateB = DateTime(
                  int.parse(partsB[2]),
                  int.parse(partsB[1]),
                  int.parse(partsB[0]),
                );
                return dateB.compareTo(dateA); // Descending order
              }
              return 0;
            });

      allCleanups.value = fetchedCleanups;

      // Track stats loaded
      Analytics.track(AnalyticsEvents.statsLoaded, {
        AnalyticsProps.cleanupsCount: fetchedCleanups.length,
      });

      // Save to cache for offline access
      await _saveToCache(fetchedCleanups);

      _updateAvailableDates();
      applyFilters();
    } catch (e) {
      error.value = '${AppStrings.statsErrorFailedLoad}: $e';
      // Keep showing cached data if fetch fails
    } finally {
      isLoading.value = false;
    }
  }

  List<CleanupModel> get currentMonthCleanups {
    final now = DateTime.now();
    return allCleanups.where((cleanup) {
      final parts = cleanup.date.split('/');
      if (parts.length != 3) return false;
      final cleanupDate = DateTime(
        int.parse(parts[2]), // year
        int.parse(parts[1]), // month
        int.parse(parts[0]), // day
      );
      return cleanupDate.year == now.year && cleanupDate.month == now.month;
    }).toList();
  }

  int get currentMonthCleanupCount => currentMonthCleanups.length;

  double get currentMonthTrashKg => currentMonthCleanups.fold(
    0.0,
    (total, cleanup) => total + cleanup.totalWeight,
  );

  bool get isFirstWeekOfMonth => DateTime.now().day <= 7;

  void _updateAvailableDates() {
    // Extract unique dates from the date string (dd/mm/yyyy format)
    final dates =
        allCleanups
            .map((c) {
              // Parse date string in format dd/mm/yyyy
              final parts = c.date.split('/');
              if (parts.length == 3) {
                return DateTime(
                  int.parse(parts[2]), // year
                  int.parse(parts[1]), // month
                  int.parse(parts[0]), // day
                );
              }
              return null;
            })
            .whereType<DateTime>()
            .toSet()
            .toList()
          ..sort();

    availableDates.value = dates;

    // Set initial date range if not already set
    if (dates.isNotEmpty && fromDate.value == null && toDate.value == null) {
      fromDate.value = dates.first;
      toDate.value = dates.last;
    }
  }

  void applyFilters() {
    filteredCleanups.value =
        allCleanups.where((cleanup) {
          // Parse cleanup date
          final parts = cleanup.date.split('/');
          if (parts.length != 3) return false;

          final cleanupDate = DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );

          // Date filter
          if (fromDate.value != null) {
            if (cleanupDate.isBefore(fromDate.value!)) return false;
          }
          if (toDate.value != null) {
            if (cleanupDate.isAfter(toDate.value!)) return false;
          }

          // Environment filter
          if (selectedEnvironments.contains('All')) return true;
          return selectedEnvironments.contains(cleanup.environment);
        }).toList();
  }

  void toggleEnvironmentFilter(String environment) {
    if (environment == 'All') {
      selectedEnvironments.clear();
      selectedEnvironments.add('All');
    } else {
      selectedEnvironments.remove('All');
      if (selectedEnvironments.contains(environment)) {
        selectedEnvironments.remove(environment);
        if (selectedEnvironments.isEmpty) {
          selectedEnvironments.add('All');
        }
      } else {
        selectedEnvironments.add(environment);
      }
    }
    Analytics.track(AnalyticsEvents.statsFilterApplied, {
      AnalyticsProps.filterType: FilterTypes.environment,
      AnalyticsProps.filterValue: environment,
    });
    applyFilters();
  }

  void setFromDate(DateTime date) {
    fromDate.value = date;
    if (toDate.value != null && date.isAfter(toDate.value!)) {
      toDate.value = date;
    }
    Analytics.track(AnalyticsEvents.statsFilterApplied, {
      AnalyticsProps.filterType: FilterTypes.date,
      AnalyticsProps.filterValue: 'from_date',
    });
    applyFilters();
  }

  void setToDate(DateTime date) {
    toDate.value = date;
    if (fromDate.value != null && date.isBefore(fromDate.value!)) {
      fromDate.value = date;
    }
    Analytics.track(AnalyticsEvents.statsFilterApplied, {
      AnalyticsProps.filterType: FilterTypes.date,
      AnalyticsProps.filterValue: 'to_date',
    });
    applyFilters();
  }

  // Get chart data
  Map<String, Map<String, int>> getChartData() {
    final data = <String, Map<String, int>>{};

    debugPrint('[StatsController] Getting chart data...');
    debugPrint(
      '[StatsController] Filtered cleanups count: ${filteredCleanups.length}',
    );

    for (final cleanup in filteredCleanups) {
      debugPrint('[StatsController] Processing cleanup: ${cleanup.id}');
      debugPrint(
        '[StatsController] Categories in cleanup: ${cleanup.categories.keys.toList()}',
      );

      cleanup.categories.forEach((category, items) {
        debugPrint(
          '[StatsController] Category: $category, Items count: ${items.length}',
        );

        if (!data.containsKey(category)) {
          data[category] = {'Freshwater': 0, 'Saltwater': 0, 'Land': 0};
        }

        final totalItems = items.values.fold(
          0,
          (total, itemCount) => total + itemCount.quantity,
        );
        final envType = cleanup.environment;

        debugPrint(
          '[StatsController] Total items in $category: $totalItems, Environment: $envType',
        );

        // Map environment types to chart categories
        String chartEnv;
        if (envType == 'Inland') {
          chartEnv = 'Land';
        } else {
          chartEnv = envType;
        }

        if (data[category]!.containsKey(chartEnv)) {
          data[category]![chartEnv] =
              (data[category]![chartEnv] ?? 0) + totalItems;
        }
      });
    }

    debugPrint('[StatsController] Final chart data: $data');
    return data;
  }

  // Get location data for map
  List<MapLocation> getLocationData() {
    final locationMap = <String, MapLocation>{};

    for (final cleanup in filteredCleanups) {
      // Only include cleanups with valid coordinates
      if (cleanup.locationLatitude != null &&
          cleanup.locationLongitude != null) {
        final key = '${cleanup.locationLatitude},${cleanup.locationLongitude}';

        if (locationMap.containsKey(key)) {
          // Aggregate data for same location
          final existing = locationMap[key]!;
          locationMap[key] = MapLocation(
            latitude: cleanup.locationLatitude!,
            longitude: cleanup.locationLongitude!,
            cleanupCount: existing.cleanupCount + 1,
            environmentType: cleanup.environment,
            trashKg: existing.trashKg + cleanup.totalWeight,
            city: cleanup.location,
            date: cleanup.date,
            groupName: cleanup.groupName,
          );
        } else {
          locationMap[key] = MapLocation(
            latitude: cleanup.locationLatitude!,
            longitude: cleanup.locationLongitude!,
            cleanupCount: 1,
            environmentType: cleanup.environment,
            trashKg: cleanup.totalWeight,
            city: cleanup.location,
            date: cleanup.date,
            groupName: cleanup.groupName,
          );
        }
      }
    }

    return locationMap.values.toList();
  }

  /// Refresh data - pull latest from Firestore
  @override
  Future<void> refresh() async {
    // Only refresh if already initialized and online
    debugPrint('[StatsController] Refresh called $_hasInitialized');
    // if (!_hasInitialized) return;

    if (_connectivityController.isOnline.value) {
      await fetchCleanups();
    }
  }

  @override
  void onClose() {
    _cacheBox?.close();
    super.onClose();
  }
}

class MapLocation {
  final double latitude;
  final double longitude;
  final int cleanupCount;
  final String environmentType;
  final double trashKg;
  final String city;
  final String date;
  final String groupName;

  MapLocation({
    required this.latitude,
    required this.longitude,
    required this.cleanupCount,
    required this.environmentType,
    required this.trashKg,
    required this.city,
    required this.date,
    required this.groupName,
  });
}
