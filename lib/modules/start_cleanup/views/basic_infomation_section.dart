import 'package:ascoa_app/app/controllers/haptic_controller.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/controllers/connectivity_controller.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';
import 'package:ascoa_app/shared/widgets/floating_label_input_field.dart';
import 'package:ascoa_app/shared/widgets/custom_date_picker.dart';
import 'package:ascoa_app/shared/widgets/location_search_field.dart';
import 'package:ascoa_app/shared/services/google_places_service.dart';
import 'package:ascoa_app/modules/start_cleanup/controllers/cleanup_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
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
        // Get current position with proper settings
        debugPrint(
          '[BasicInfo] _autoFetchLocation: attempting getCurrentPosition',
        );
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        debugPrint(
          '[BasicInfo] _autoFetchLocation: got position lat=${position.latitude}, lng=${position.longitude}',
        );

        final userLocation = LatLng(position.latitude, position.longitude);
        debugPrint(
          '[BasicInfo] _autoFetchLocation: checking if location is in Cameroon...',
        );

        // Check if location is in Cameroon (rough bounds check)
        final isInCameroon = await _isInCameroon(userLocation);
        debugPrint(
          '[BasicInfo] _autoFetchLocation: isInCameroon=$isInCameroon',
        );

        if (!isInCameroon) {
          if (mounted) {
            // Set field error - will trigger FloatingLabelInputField to display error
            widget.controller.locationError =
                AppStrings.locationOutsideCameroon;
            debugPrint(
              '[BasicInfo] _autoFetchLocation: locationError set -> ${widget.controller.locationError}',
            );
            debugPrint(
              '[BasicInfo] _autoFetchLocation: aborting due to location outside Cameroon',
            );
          }
          return;
        }

        debugPrint(
          '[BasicInfo] _autoFetchLocation: location valid, updating map',
        );
        _updateMapLocation(userLocation);

        // Reverse geocode to get address
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty && mounted) {
            final place = placemarks.first;
            // Only accept if in Cameroon
            if (place.isoCountryCode != 'CM') {
              // Set field error instead of showing snackbar
              widget.controller.locationError = AppStrings.cameroonOnlyLocation;
              debugPrint(
                '[BasicInfo] _autoFetchLocation: country code=${place.isoCountryCode}, not CM',
              );
              debugPrint(
                '[BasicInfo] _autoFetchLocation: locationError set -> ${widget.controller.locationError}',
              );
              return;
            }

            final address =
                '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'
                    .replaceAll(RegExp(r'^,\s*'), '')
                    .replaceAll(RegExp(r',\s*,'), ',');
            _isUpdatingFromMap = true;
            locationController.text = address.trim();
            _isUpdatingFromMap = false;
            widget.controller.clearFieldError('location');
            debugPrint(
              '[BasicInfo] _autoFetchLocation: cleared location error after reverse geocode',
            );
          }
        } catch (e) {
          debugPrint('Error reverse geocoding: $e');
        }
      }
    } catch (e) {
      debugPrint('Error auto-fetching location: $e');
      // Silently fail - user can manually enter location
    }
  }

  /// Check if coordinates are within Cameroon bounds
  Future<bool> _isInCameroon(LatLng location) async {
    final connectivity = Get.find<ConnectivityController>();
    final isOnline = connectivity.isOnline.value;

    if (!isOnline) {
      debugPrint('[GeoFence] Offline - using bounding box check only');
      return location.latitude >= 1.72767263428 &&
          location.latitude <= 12.8593962671 &&
          location.longitude >= 8.48881554529 &&
          location.longitude <= 16.0128524106;
    }

    return isInCameroonByGeocoding(location);
  }

  Future<bool> isInCameroonByGeocoding(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isEmpty) return false;
      return placemarks.first.isoCountryCode == 'CM';
    } catch (e) {
      debugPrint('[GeoFence] Reverse geocoding failed: $e');
      return false;
    }
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
      if (permission == LocationPermission.denied) {
        debugPrint('[BasicInfo] _getLocation: requesting permission');
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

      // Get current position with timeout
      debugPrint('[BasicInfo] _getLocation: calling getCurrentPosition');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('[BasicInfo] _getLocation: getCurrentPosition timed out');
          throw Exception('Location request timed out');
        },
      );

      debugPrint(
        '[BasicInfo] _getLocation: position received lat=${position.latitude}, lng=${position.longitude}',
      );

      final userLocation = LatLng(position.latitude, position.longitude);
      debugPrint(
        '[BasicInfo] _getLocation: checking if location is in Cameroon...',
      );

      // Check if location is in Cameroon
      final isInCameroon = await _isInCameroon(userLocation);
      debugPrint('[BasicInfo] _getLocation: isInCameroon=$isInCameroon');

      if (!isInCameroon) {
        if (!mounted) return;
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // Set field error instead of showing snackbar
        widget.controller.locationError = AppStrings.locationOutsideCameroon;
        debugPrint(
          '[BasicInfo] _getLocation: locationError set -> ${widget.controller.locationError}',
        );
        debugPrint(
          '[BasicInfo] _getLocation: aborting due to location outside Cameroon',
        );
        return;
      }

      debugPrint('[BasicInfo] _getLocation: location valid, updating map');
      _updateMapLocation(userLocation);

      // Reverse geocode to get address
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;

          // Verify country is Cameroon
          if (place.isoCountryCode != 'CM') {
            // Hide loading snackbar
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
            // Set field error instead of showing snackbar
            widget.controller.locationError = AppStrings.cameroonOnlyLocation;
            return;
          }

          final address =
              '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'
                  .replaceAll(RegExp(r'^,\s*'), '')
                  .replaceAll(RegExp(r',\s*,'), ',');
          _isUpdatingFromMap = true;
          locationController.text = address.trim();
          _isUpdatingFromMap = false;
          widget.controller.clearFieldError('location');
          debugPrint('[BasicInfo] reverse geocode: cleared location error');
        }
      } catch (e) {
        debugPrint('Error reverse geocoding: $e');
      }

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
    // Check if dragged location is in Cameroon
    if (!await _isInCameroon(currentPosition!)) {
      // Set field error instead of showing snackbar
      widget.controller.locationError = AppStrings.selectLocationInCameroon;
      // Reset to center of Cameroon
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
      return;
    }

    // Debounce to avoid excessive API calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      Duration(milliseconds: AppDimensions.placeSearchDebounceMs),
      () async {
        if (currentPosition == null) return;

        try {
          final placemarks = await placemarkFromCoordinates(
            currentPosition!.latitude,
            currentPosition!.longitude,
          );

          if (placemarks.isNotEmpty && mounted) {
            final place = placemarks.first;

            // Double-check country code
            if (place.isoCountryCode != null && place.isoCountryCode != 'CM') {
              // Set field error instead of showing snackbar
              widget.controller.locationError = AppStrings.cameroonOnlyLocation;
              return;
            }

            final address =
                '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'
                    .replaceAll(RegExp(r'^,\s*'), '') // Remove leading comma
                    .replaceAll(RegExp(r',\s*,'), ','); // Remove double commas

            _isUpdatingFromMap = true;
            locationController.text = address.trim();
            _isUpdatingFromMap = false;
            widget.controller.clearFieldError('location');
          }
        } catch (e) {
          debugPrint('Error reverse geocoding: $e');
        }
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
    if (currentPosition != null && !await _isInCameroon(currentPosition!)) {
      Get.find<HapticController>().light();
      widget.controller.locationError = AppStrings.selectLocationInCameroon;
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
