import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/widgets/floating_label_input_field.dart';
import 'package:we_monitor/shared/widgets/custom_date_picker.dart';
import 'package:we_monitor/shared/widgets/location_search_field.dart';
import 'package:we_monitor/shared/services/google_places_service.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/cleanup_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class BasicInformationSection extends StatefulWidget {
  final CleanupFormController controller;

  const BasicInformationSection({super.key, required this.controller});

  @override
  State<BasicInformationSection> createState() =>
      _BasicInformationSectionState();
}

class _BasicInformationSectionState extends State<BasicInformationSection> {
  late final TextEditingController peopleController;
  late final TextEditingController groupController;
  late final TextEditingController dateController;
  late final TextEditingController locationController;

  GoogleMapController? mapController;
  LatLng? currentPosition;
  Set<Marker> markers = {};
  Timer? _debounceTimer;
  bool _isUpdatingFromMap = false;

  late final Worker _connectivityWorker;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with values from form controller
    peopleController = TextEditingController(
      text: widget.controller.peopleCount.toString(),
    );
    groupController = TextEditingController(text: widget.controller.groupName);
    dateController = TextEditingController(text: widget.controller.date);
    locationController = TextEditingController(
      text: widget.controller.location,
    );

    // Sync changes back to form controller
    peopleController.addListener(_syncPeopleCount);
    groupController.addListener(_syncGroupName);
    dateController.addListener(_syncDate);
    locationController.addListener(_syncLocation);

    // Restore map position and marker if location was previously set
    if (widget.controller.locationLatitude != null &&
        widget.controller.locationLongitude != null) {
      debugPrint(
        '[BasicInfo] initState: restoring saved location lat=${widget.controller.locationLatitude}, lng=${widget.controller.locationLongitude}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreSavedLocation();
      });
    } else {
      // Auto-fetch location when this section is first displayed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoFetchLocation();
      });
    }
    final connectivity = Get.find<ConnectivityController>();

    _connectivityWorker = ever<bool>(connectivity.isOnline, (isOnline) async {
      if (!isOnline) return;

      // Only re-check if we already have a selected location
      if (currentPosition == null) return;

      debugPrint('[GeoFence] Connectivity restored – revalidating location');

      final isValid = await _isInCameroon(currentPosition!);

      if (!mounted) return;

      if (!isValid) {
        widget.controller.locationError = AppStrings.selectLocationInCameroon;
        debugPrint('[GeoFence] Location invalid after reconnect');
      } else {
        widget.controller.clearFieldError('location');
        debugPrint('[GeoFence] Location valid after reconnect');
      }
    });
  }

  @override
  void dispose() {
    _connectivityWorker.dispose();
    _debounceTimer?.cancel();
    peopleController.dispose();
    groupController.dispose();
    dateController.dispose();
    locationController.dispose();
    super.dispose();
  }

  /// Restore map marker and camera to previously saved location
  void _restoreSavedLocation() {
    if (widget.controller.locationLatitude == null ||
        widget.controller.locationLongitude == null) {
      return;
    }

    final savedLocation = LatLng(
      widget.controller.locationLatitude!,
      widget.controller.locationLongitude!,
    );

    debugPrint(
      '[BasicInfo] _restoreSavedLocation: restoring to lat=${savedLocation.latitude}, lng=${savedLocation.longitude}',
    );
    _updateMapLocation(savedLocation);
  }

  /// Automatically try to fetch user location (called when section opens)
  Future<void> _autoFetchLocation() async {
    // Only fetch if location is empty
    if (locationController.text.isNotEmpty) return;

    debugPrint(
      '[BasicInfo] _autoFetchLocation: started, locationField="${locationController.text}"',
    );

    try {
      debugPrint('[BasicInfo] _autoFetchLocation: checking location services');
      // Check if location services are enabled first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint(
        '[BasicInfo] _autoFetchLocation: serviceEnabled=$serviceEnabled',
      );
      if (!serviceEnabled) {
        debugPrint(
          '[BasicInfo] _autoFetchLocation: location services disabled - abort',
        );
        return;
      }

      // Check permission without requesting (don't disturb user)
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint(
        '[BasicInfo] _autoFetchLocation: current permission=$permission',
      );

      // Only fetch if permission already granted
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Position? position;
        try {
          debugPrint('[BasicInfo] _autoFetchLocation: checking getLastKnownPosition');
          position = await Geolocator.getLastKnownPosition();
          if (position != null) {
            final userLocation = LatLng(position.latitude, position.longitude);
            _updateMapLocation(userLocation);
          }
        } catch (e) {
          debugPrint('Error getting last known position in autoFetch: $e');
        }

        // Get current position with proper settings
        debugPrint(
          '[BasicInfo] _autoFetchLocation: attempting getCurrentPosition',
        );
        try {
          final currentPositionResult = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(
            const Duration(seconds: 8),
          );
          debugPrint(
            '[BasicInfo] _autoFetchLocation: got position lat=${currentPositionResult.latitude}, lng=${currentPositionResult.longitude}',
          );
          position = currentPositionResult;
        } on TimeoutException {
          debugPrint('[BasicInfo] _autoFetchLocation: getCurrentPosition timed out');
          if (position == null) return;
        } catch (e) {
          debugPrint('[BasicInfo] _autoFetchLocation: getCurrentPosition error: $e');
          if (position == null) return;
        }

        final userLocation = LatLng(position.latitude, position.longitude);
        debugPrint(
          '[BasicInfo] _autoFetchLocation: checking if location is in Cameroon...',
        );

        final connectivity = Get.find<ConnectivityController>();

        if (!connectivity.isOnline.value) {
          // Offline: validate with the bounding box, no address available.
          if (!_isInCameroonBbox(userLocation)) {
            widget.controller.locationError =
                AppStrings.locationOutsideCameroon;
            return;
          }
          _isUpdatingFromMap = true;
          locationController.text =
              'Lat ${userLocation.latitude.toStringAsFixed(5)}, Lng ${userLocation.longitude.toStringAsFixed(5)}';
          _isUpdatingFromMap = false;
          _updateMapLocation(userLocation);
          widget.controller.clearFieldError('location');
          return;
        }

        // Online: single Google reverse-geocode validates the country and
        // supplies the address. Fail-closed: only accept when Google confirms.
        final geo = await GooglePlacesService.reverseGeocode(
          position.latitude,
          position.longitude,
        );
        if (!mounted) return;

        if (geo == null) {
          debugPrint('[BasicInfo] _autoFetchLocation: geocode unavailable, falling back to Bbox');
          if (!_isInCameroonBbox(userLocation)) {
            widget.controller.locationError = AppStrings.locationOutsideCameroon;
            return;
          }
          _updateMapLocation(userLocation);
          _isUpdatingFromMap = true;
          locationController.text =
              'Lat ${userLocation.latitude.toStringAsFixed(5)}, Lng ${userLocation.longitude.toStringAsFixed(5)}';
          _isUpdatingFromMap = false;
          widget.controller.clearFieldError('location');
          return;
        }

        if (!geo.isCameroon) {
          widget.controller.locationError = AppStrings.locationOutsideCameroon;
          debugPrint(
            '[BasicInfo] _autoFetchLocation: outside Cameroon (country=${geo.countryCode})',
          );
          return;
        }

        debugPrint(
          '[BasicInfo] _autoFetchLocation: location valid, updating map',
        );
        _updateMapLocation(userLocation);

        _isUpdatingFromMap = true;
        locationController.text = geo.formattedAddress;
        _isUpdatingFromMap = false;
        widget.controller.clearFieldError('location');
      }
    } catch (e) {
      debugPrint('Error auto-fetching location: $e');
      // Silently fail - user can manually enter location
    }
  }

  /// Rough Cameroon bounding box — used ONLY as the offline fallback, when the
  /// Google Geocoding API is unreachable.
  bool _isInCameroonBbox(LatLng location) {
    return location.latitude >= 1.72767263428 &&
        location.latitude <= 12.8593962671 &&
        location.longitude >= 8.48881554529 &&
        location.longitude <= 16.0128524106;
  }

  /// Validate that coordinates fall inside Cameroon.
  ///
  /// Online: Google Geocoding is the source of truth (fail-closed — a non-CM
  /// result or an unreachable service is rejected). Offline: fall back to the
  /// bounding box, the only check available without network.
  Future<bool> _isInCameroon(LatLng location) async {
    final connectivity = Get.find<ConnectivityController>();
    if (!connectivity.isOnline.value) {
      debugPrint('[GeoFence] Offline - using bounding box fallback');
      return _isInCameroonBbox(location);
    }

    final result = await GooglePlacesService.reverseGeocode(
      location.latitude,
      location.longitude,
    );
    if (result == null) {
      debugPrint('[GeoFence] Reverse geocode unavailable - rejecting location');
      return false;
    }
    return result.isCameroon;
  }

  void _syncPeopleCount() {
    final count = int.tryParse(peopleController.text) ?? 0;
    widget.controller.peopleCount = count;
  }

  void _syncGroupName() {
    widget.controller.groupName = groupController.text;
  }

  void _syncDate() {
    widget.controller.date = dateController.text;
  }

  void _syncLocation() {
    widget.controller.location = locationController.text;
  }

  void _incrementPeople() {
    final newCount = widget.controller.peopleCount + 1;
    widget.controller.peopleCount = newCount;
    peopleController.text = newCount.toString();
  }

  void _decrementPeople() {
    if (widget.controller.peopleCount > 0) {
      final newCount = widget.controller.peopleCount - 1;
      widget.controller.peopleCount = newCount;
      peopleController.text = newCount.toString();
    }
  }

  void _getLocation() async {
    // Request location permission and get current GPS coordinates
    debugPrint('[BasicInfo] _getLocation: started');
    try {
      // Check if location services are enabled
      debugPrint('[BasicInfo] _getLocation: checking location services');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[BasicInfo] _getLocation: serviceEnabled=$serviceEnabled');
      if (!serviceEnabled) {
        debugPrint(
          '[BasicInfo] _getLocation: services disabled -> showing message and aborting',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.enableLocationServices),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[BasicInfo] _getLocation: current permission=$permission');
      bool permissionRequested = false;
      if (permission == LocationPermission.denied) {
        debugPrint('[BasicInfo] _getLocation: requesting permission');
        permissionRequested = true;
        permission = await Geolocator.requestPermission();
        debugPrint(
          '[BasicInfo] _getLocation: permission after request=$permission',
        );
        if (permission == LocationPermission.denied) {
          debugPrint('[BasicInfo] _getLocation: permission denied by user');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.locationPermissionDenied),
              backgroundColor: AppColors.errorRed,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[BasicInfo] _getLocation: permission deniedForever');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.locationPermissionPermanentlyDenied),
            backgroundColor: AppColors.errorRed,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      // Add a small delay if permission was just requested to allow layout/focus transitions to complete on Android
      if (permissionRequested) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Show loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: SizeUtils.w(context, AppDimensions.smallLoaderSize),
                  height: SizeUtils.h(context, AppDimensions.smallLoaderSize),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.pureWhite,
                    ),
                  ),
                ),
                SizedBox(
                  width: SizeUtils.w(context, AppDimensions.snackBarGapSmall),
                ),
                Text(AppStrings.gettingYourLocation),
              ],
            ),
            duration: const Duration(seconds: 15),
          ),
        );
      }

      Position? position;
      try {
        debugPrint('[BasicInfo] _getLocation: checking getLastKnownPosition');
        position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          debugPrint(
            '[BasicInfo] _getLocation: got last known position lat=${position.latitude}, lng=${position.longitude}',
          );
          // Let's update the map and controller coordinates immediately using the last known position
          final userLocation = LatLng(position.latitude, position.longitude);
          _updateMapLocation(userLocation);
        }
      } catch (e) {
        debugPrint('Error getting last known position: $e');
      }

      // Get current position with timeout
      debugPrint('[BasicInfo] _getLocation: calling getCurrentPosition');
      try {
        final currentPositionResult = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(
          const Duration(seconds: 8),
        );
        debugPrint(
          '[BasicInfo] _getLocation: position received lat=${currentPositionResult.latitude}, lng=${currentPositionResult.longitude}',
        );
        position = currentPositionResult;
      } on TimeoutException {
        debugPrint('[BasicInfo] _getLocation: getCurrentPosition timed out');
        if (position == null) {
          throw TimeoutException('Location request timed out');
        }
      } catch (e) {
        debugPrint('[BasicInfo] _getLocation: getCurrentPosition error: $e');
        if (position == null) {
          rethrow;
        }
      }

      final userLocation = LatLng(position.latitude, position.longitude);
      debugPrint(
        '[BasicInfo] _getLocation: checking if location is in Cameroon...',
      );

      final connectivity = Get.find<ConnectivityController>();

      if (!connectivity.isOnline.value) {
        // Offline: validate with the bounding box; no address available.
        if (!mounted) return;
        if (!_isInCameroonBbox(userLocation)) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          widget.controller.locationError = AppStrings.locationOutsideCameroon;
          return;
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _isUpdatingFromMap = true;
        locationController.text =
            'Lat ${userLocation.latitude.toStringAsFixed(5)}, Lng ${userLocation.longitude.toStringAsFixed(5)}';
        _isUpdatingFromMap = false;
        _updateMapLocation(userLocation);
        widget.controller.clearFieldError('location');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.locationSetSuccessfully),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Online: single Google reverse-geocode validates the country and
      // supplies the address. Fail-closed: only accept when Google confirms.
      final geo = await GooglePlacesService.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;

      if (geo == null) {
        // Could not verify against Google — let's fall back to bounding box check
        if (!_isInCameroonBbox(userLocation)) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          widget.controller.locationError = AppStrings.locationOutsideCameroon;
          debugPrint('[BasicInfo] _getLocation: geocode unavailable and outside Cameroon Bbox');
          return;
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _isUpdatingFromMap = true;
        locationController.text =
            'Lat ${userLocation.latitude.toStringAsFixed(5)}, Lng ${userLocation.longitude.toStringAsFixed(5)}';
        _isUpdatingFromMap = false;
        _updateMapLocation(userLocation);
        widget.controller.clearFieldError('location');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.locationSetSuccessfully),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (!geo.isCameroon) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        widget.controller.locationError = AppStrings.locationOutsideCameroon;
        debugPrint(
          '[BasicInfo] _getLocation: outside Cameroon (country=${geo.countryCode})',
        );
        return;
      }

      debugPrint('[BasicInfo] _getLocation: location valid, updating map');
      _updateMapLocation(userLocation);

      _isUpdatingFromMap = true;
      locationController.text = geo.formattedAddress;
      _isUpdatingFromMap = false;
      widget.controller.clearFieldError('location');

      // Hide loading snackbar and show success
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.locationSetSuccessfully),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (!mounted) return;

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.locationFetchFailed),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _updateMapLocation(LatLng position) {
    setState(() {
      currentPosition = position;
      markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: position,
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      };
    });

    // Save coordinates to controller for restoration on section reopen
    widget.controller.locationLatitude = position.latitude;
    widget.controller.locationLongitude = position.longitude;
    if (locationController.text.trim().isEmpty) {
      locationController.text =
          'Lat ${position.latitude.toStringAsFixed(5)}, '
          'Lng ${position.longitude.toStringAsFixed(5)}';
    }
    widget.controller.clearFieldError('location');
    debugPrint(
      '[BasicInfo] _updateMapLocation: saved coordinates lat=${position.latitude}, lng=${position.longitude}',
    );

    // Animate camera to new position
    mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _onPlaceSelected(PlaceDetails details) async {
    Get.find<HapticController>().selectionClick();
    // Check if selected place is in Cameroon
    if (!await _isInCameroon(details.latLng)) {
      // Set field error instead of showing snackbar
      widget.controller.locationError = AppStrings.selectLocationInCameroon;
      return;
    }
    // Update map when user selects from search
    _updateMapLocation(details.latLng);
  }

  void _onMapDragEnd() async {
    Get.find<HapticController>().selectionClick();
    // When user drags map, update the search field with reverse geocoded address
    if (currentPosition == null || _isUpdatingFromMap) return;

    widget.controller.locationLatitude = currentPosition!.latitude;
    widget.controller.locationLongitude = currentPosition!.longitude;

    // Debounce so validation runs once after the user stops moving the map.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      Duration(milliseconds: AppDimensions.placeSearchDebounceMs),
      () async {
        final pos = currentPosition;
        if (pos == null) return;

        void resetToCentre() {
          setState(() {
            currentPosition = const LatLng(3.8480, 11.5021);
            markers = {
              Marker(
                markerId: const MarkerId('selected'),
                position: const LatLng(3.8480, 11.5021),
              ),
            };
          });
          mapController?.animateCamera(
            CameraUpdate.newLatLng(const LatLng(3.8480, 11.5021)),
          );
        }

        final connectivity = Get.find<ConnectivityController>();

        if (!connectivity.isOnline.value) {
          // Offline: bounding-box check only, no address available.
          if (!mounted) return;
          if (!_isInCameroonBbox(pos)) {
            widget.controller.locationError =
                AppStrings.selectLocationInCameroon;
            resetToCentre();
            return;
          }
          _isUpdatingFromMap = true;
          locationController.text =
              'Lat ${pos.latitude.toStringAsFixed(5)}, Lng ${pos.longitude.toStringAsFixed(5)}';
          _isUpdatingFromMap = false;
          widget.controller.clearFieldError('location');
          return;
        }

        // Online: single Google reverse-geocode validates + supplies address.
        final geo = await GooglePlacesService.reverseGeocode(
          pos.latitude,
          pos.longitude,
        );
        if (!mounted) return;

        // Service error — flag it, leave the pin where it is.
        if (geo == null) {
          // Fallback to bounding box check even if online, so the app remains usable when API key is missing or fails.
          if (!_isInCameroonBbox(pos)) {
            widget.controller.locationError = AppStrings.selectLocationInCameroon;
            resetToCentre();
            return;
          }
          _isUpdatingFromMap = true;
          locationController.text =
              'Lat ${pos.latitude.toStringAsFixed(5)}, Lng ${pos.longitude.toStringAsFixed(5)}';
          _isUpdatingFromMap = false;
          widget.controller.clearFieldError('location');
          return;
        }

        if (!geo.isCameroon) {
          widget.controller.locationError = AppStrings.selectLocationInCameroon;
          resetToCentre();
          return;
        }

        _isUpdatingFromMap = true;
        locationController.text = geo.formattedAddress;
        _isUpdatingFromMap = false;
        widget.controller.clearFieldError('location');
      },
    );
  }

  // Using shared FloatingLabelInputField for consistent inputs

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        SizeUtils.h(context, AppDimensions.cleanupContentPadding),
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(
          SizeUtils.r(context, AppDimensions.cleanupSectionRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number of People - use FloatingLabelInputField with +/- buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Place the floating input in the middle, buttons on sides
                    Row(
                      children: [
                        // Decrement button
                        IconButton(
                          onPressed: () {
                            Get.find<HapticController>().selectionClick();
                            _decrementPeople();
                          },
                          icon: Icon(
                            Icons.remove,
                            size: SizeUtils.r(
                              context,
                              AppDimensions.smallIconSize,
                            ),
                          ),
                          color: AppColors.accentGreen,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),

                        // Floating input occupies the remaining width
                        Expanded(
                          child: ListenableBuilder(
                            listenable: widget.controller,
                            builder: (context, _) {
                              return FloatingLabelInputField(
                                controller: peopleController,
                                label: AppStrings.numberOfPeopleLabel,
                                hint: '0',
                                keyboardType: TextInputType.number,
                                topSpacing: AppDimensions.zero,
                                supportText: widget.controller.peopleCountError,
                                isError:
                                    widget.controller.peopleCountError != null,
                                onChanged: (val) {
                                  final parsed = int.tryParse(val) ?? 0;
                                  widget.controller.peopleCount = parsed;
                                  widget.controller.clearFieldError(
                                    'peopleCount',
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // Increment button
                        IconButton(
                          onPressed: () {
                            Get.find<HapticController>().selectionClick();
                            _incrementPeople();
                          },
                          icon: Icon(
                            Icons.add,
                            size: SizeUtils.r(
                              context,
                              AppDimensions.smallIconSize,
                            ),
                          ),
                          color: AppColors.accentGreen,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),

                    SizedBox(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.cleanupSpacing4,
                      ),
                    ),
                    Text(
                      AppStrings.totalParticipants,
                      style: AppTextStyles.bodySecondary(context).copyWith(
                        fontSize: SizeUtils.h(
                          context,
                          AppDimensions.smallFontSize,
                        ),
                        color: AppColors.textAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
          ),

          // Group Name
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              return FloatingLabelInputField(
                controller: groupController,
                label: AppStrings.groupNameLabel,
                hint: AppStrings.enterGroupName,
                supportText: widget.controller.groupNameError,
                isError: widget.controller.groupNameError != null,
                onChanged:
                    (_) => widget.controller.clearFieldError('groupName'),
              );
            },
          ),
          SizedBox(height: SizeUtils.h(context, AppDimensions.cleanupSpacing4)),
          Text(
            AppStrings.cleanAloneHint,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: SizeUtils.h(context, 12),
              color: AppColors.textHint,
            ),
          ),
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
          ),

          // Date - use custom date picker on tap (readOnly)
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              return FloatingLabelInputField(
                controller: dateController,
                label: AppStrings.dateLabel,
                hint: AppStrings.datePlaceholder,
                keyboardType: TextInputType.datetime,
                readOnly: true,
                supportText: widget.controller.dateError,
                isError: widget.controller.dateError != null,
                onTap: () async {
                  Get.find<HapticController>().selectionClick();
                  // open custom date picker on tap
                  // ignore: use_build_context_synchronously
                  final picked = await CustomDatePicker.show(
                    context,
                    initialDate: DateTime.now(),
                    startDate: DateTime(2023),
                    endDate: DateTime(2030),
                  );
                  if (!mounted) return;
                  if (picked != null) {
                    setState(
                      () =>
                          dateController.text =
                              "${picked.day}/${picked.month}/${picked.year}",
                    );
                    widget.controller.clearFieldError('date');
                  }
                },
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  size: SizeUtils.r(context, AppDimensions.smallIconSize),
                  color: AppColors.textHint,
                ),
              );
            },
          ),
          SizedBox(height: SizeUtils.h(context, AppDimensions.cleanupSpacing4)),
          Text(
            AppStrings.datePlaceholder,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: SizeUtils.h(context, AppDimensions.smallFontSize),
              color: AppColors.textHint,
            ),
          ),
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing16),
          ),

          // Use My Location Button (for GPS permission & current location)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.find<HapticController>().medium();
                _getLocation();
              },
              icon: Icon(Icons.my_location, color: AppColors.pureWhite),
              label: Text(
                AppStrings.useMyLocation,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: SizeUtils.h(context, AppDimensions.mediumFontSize),
                  color: AppColors.pureWhite,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: SizeUtils.w(
                    context,
                    AppDimensions.smallButtonHorizontalPadding,
                  ),
                  vertical: SizeUtils.h(
                    context,
                    AppDimensions.smallButtonVerticalPadding,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    SizeUtils.r(context, AppDimensions.smallButtonRadius),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
          ),

          // Location Search Field (with autocomplete dropdown)
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              return LocationSearchField(
                controller: locationController,
                label: AppStrings.locationLabel,
                hint: AppStrings.searchForLocation,
                onPlaceSelected: _onPlaceSelected,
                supportText: widget.controller.locationError,
                isError: widget.controller.locationError != null,
                onChanged: (_) => widget.controller.clearFieldError('location'),
              );
            },
          ),
          SizedBox(height: SizeUtils.h(context, AppDimensions.cleanupSpacing4)),
          Text(
            AppStrings.searchOrDragMapHint,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: SizeUtils.h(context, AppDimensions.smallFontSize),
              color: AppColors.textHint,
            ),
          ),
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
          ),

          // Map Preview (synced with search field)
          ClipRRect(
            borderRadius: BorderRadius.circular(SizeUtils.r(context, 10)),
            child: SizedBox(
              height: SizeUtils.h(context, AppDimensions.mapPreviewHeight),
              width: double.infinity,
              child: GoogleMap(
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                onMapCreated: (controller) {
                  mapController = controller;
                  // Set initial position if available
                  if (currentPosition != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLng(currentPosition!),
                    );
                  }
                },
                initialCameraPosition: CameraPosition(
                  // Center on Cameroon (Yaoundé coordinates) - default view only, no marker
                  target: const LatLng(3.8480, 11.5021),
                  zoom: 6, // Zoom out to show whole country initially
                ),
                // Set camera bounds to Cameroon
                minMaxZoomPreference: const MinMaxZoomPreference(5, 20),
                cameraTargetBounds: CameraTargetBounds(
                  LatLngBounds(
                    southwest: const LatLng(
                      1.65,
                      8.49,
                    ), // South-West corner of Cameroon
                    northeast: const LatLng(
                      13.08,
                      16.19,
                    ), // North-East corner of Cameroon
                  ),
                ),
                markers: markers,
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                // Enable all gestures for proper map interaction
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                rotateGesturesEnabled: true,
                onCameraMove: (position) {
                  // Update marker position as user drags
                  if (!_isUpdatingFromMap) {
                    setState(() {
                      currentPosition = position.target;
                      markers = {
                        Marker(
                          markerId: const MarkerId('selected'),
                          position: position.target,
                        ),
                      };
                    });
                  }
                },
                onCameraIdle: _onMapDragEnd,
              ),
            ),
          ),

          // Next Button
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing24),
          ),
          SizedBox(
            width: double.infinity,
            height: SizeUtils.h(context, AppDimensions.buttonHeight),
            child: ElevatedButton(
              onPressed: _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    SizeUtils.r(context, AppDimensions.borderRadius),
                  ),
                ),
              ),
              child: Text(
                AppStrings.nextButton,
                style: AppTextStyles.saveCleanUpText(
                  context,
                ).copyWith(color: AppColors.pureWhite),
              ),
            ),
          ),
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
          ),
        ],
      ),
    );
  }

  void _handleNext() async {
    Get.find<HapticController>().medium();
    // Validate all fields in this section
    final isValid = widget.controller.validateSection(
      AppStrings.basicInformation,
    );

    if (!isValid) {
      Get.find<HapticController>().light();
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.pleaseFixFormErrors),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Additional validation: Check if location is within Cameroon (offline-safe)
    final connectivity = Get.find<ConnectivityController>();
    if (currentPosition != null &&
        connectivity.isOnline.value &&
        !await _isInCameroon(currentPosition!)) {
      Get.find<HapticController>().light();
      widget.controller.locationError = AppStrings.selectLocationInCameroon;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.selectLocationInCameroon),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    Get.find<HapticController>().light();
    // Mark section as completed
    widget.controller.markSectionCompleted(AppStrings.basicInformation);

    // Move to next section (Trash Collected)
    widget.controller.setExpandedSection(AppStrings.trashCollected);
  }
}
