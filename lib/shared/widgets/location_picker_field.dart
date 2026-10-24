import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/services/google_places_service.dart';
import 'package:we_monitor/shared/services/location_validator.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/widgets/location_search_field.dart';

/// Location input shared by the cleanup and hotspot forms.
///
/// The parent owns the chosen [value]; this widget only reports explicit user
/// choices through [onChanged] — search result, "use my location", or the
/// full-screen map picker's confirm button. Map camera movement never changes
/// the value, so scrolling the form or a failed geocode cannot move the pin.
class LocationPickerField extends StatefulWidget {
  final PickedLocation? value;
  final ValueChanged<PickedLocation> onChanged;

  /// Reports a validation/fetch error (or null to clear it).
  final ValueChanged<String?> onError;
  final String? errorText;

  /// Pre-fill with the device location when empty and permission is granted.
  final bool autoFetchCurrentLocation;

  const LocationPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onError,
    this.errorText,
    this.autoFetchCurrentLocation = true,
  });

  @override
  State<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<LocationPickerField> {
  late final TextEditingController _textController;

  /// Bumped on every user-initiated location action. Async work captures it
  /// and drops its result if the user has since chosen something else, so a
  /// slow GPS fix can never overwrite a search result picked meanwhile.
  int _generation = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value?.address ?? '');
    if (widget.value == null && widget.autoFetchCurrentLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoFetch());
    }
  }

  @override
  void didUpdateWidget(LocationPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final address = widget.value?.address ?? '';
    if (widget.value != oldWidget.value && _textController.text != address) {
      _textController.text = address;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _commit(PickedLocation loc) {
    _textController.text = loc.address;
    widget.onError(null);
    widget.onChanged(loc);
  }

  /// Typed text that was never turned into a chosen place is discarded, so the
  /// text shown always matches the saved coordinates.
  void _onSearchFocusLost() {
    final address = widget.value?.address ?? '';
    if (_textController.text != address) {
      _textController.text = address;
    }
  }

  void _onPlaceSelected(PlaceDetails details) {
    Get.find<HapticController>().selectionClick();
    _generation++;
    // Autocomplete is restricted to Cameroon; the bbox guards bad details.
    if (!LocationValidator.inCameroonBbox(details.latLng)) {
      widget.onError(AppStrings.selectLocationInCameroon);
      _onSearchFocusLost();
      return;
    }
    _commit(
      PickedLocation(
        latitude: details.latLng.latitude,
        longitude: details.latLng.longitude,
        address:
            details.formattedAddress.isNotEmpty
                ? details.formattedAddress
                : PickedLocation.coordsLabel(details.latLng),
        verified: true,
      ),
    );
  }

  Future<void> _autoFetch() async {
    final gen = _generation;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
      final position = await _readPosition();
      if (position == null) return;
      final result = await LocationValidator.check(
        LatLng(position.latitude, position.longitude),
      );
      // Only fill an still-empty field the user hasn't touched meanwhile.
      if (!mounted || gen != _generation || widget.value != null) return;
      if (result.isValid) _commit(result.location!);
    } catch (e) {
      debugPrint('[LocationPicker] auto-fetch failed: $e');
    }
  }

  Future<void> _useMyLocation() async {
    Get.find<HapticController>().medium();
    final gen = ++_generation;
    final messenger = ScaffoldMessenger.of(context);

    if (!await Geolocator.isLocationServiceEnabled()) {
      _snack(messenger, AppStrings.enableLocationServices, AppColors.warning);
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      // Let the permission dialog's focus transition finish on Android.
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (permission == LocationPermission.denied) {
      _snack(
        messenger,
        AppStrings.locationPermissionDenied,
        AppColors.errorRed,
      );
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      _snack(
        messenger,
        AppStrings.locationPermissionPermanentlyDenied,
        AppColors.errorRed,
      );
      return;
    }

    if (mounted) setState(() => _busy = true);
    try {
      final position = await _readPosition();
      if (position == null) throw TimeoutException('No position');
      final result = await LocationValidator.check(
        LatLng(position.latitude, position.longitude),
      );
      if (!mounted || gen != _generation) return;
      if (!result.isValid) {
        widget.onError(AppStrings.locationOutsideCameroon);
        return;
      }
      _commit(result.location!);
      _snack(messenger, AppStrings.locationSetSuccessfully, AppColors.success);
    } catch (e) {
      debugPrint('[LocationPicker] use my location failed: $e');
      if (mounted && gen == _generation) {
        _snack(messenger, AppStrings.locationFetchFailed, AppColors.errorRed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// A fresh fix if one arrives within 8s, otherwise the last known position.
  Future<Position?> _readPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[LocationPicker] current position unavailable: $e');
      return Geolocator.getLastKnownPosition();
    }
  }

  Future<void> _openMapPicker() async {
    Get.find<HapticController>().selectionClick();
    final gen = ++_generation;
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullScreenLocationPicker(initial: widget.value),
      ),
    );
    if (picked != null && mounted && gen == _generation) _commit(picked);
  }

  void _snack(ScaffoldMessengerState messenger, String text, Color color) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _busy ? null : _useMyLocation,
          icon:
              _busy
                  ? SizedBox(
                    width: SizeUtils.w(context, AppDimensions.smallLoaderSize),
                    height: SizeUtils.h(context, AppDimensions.smallLoaderSize),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.pureWhite,
                      ),
                    ),
                  )
                  : const Icon(Icons.my_location, color: AppColors.pureWhite),
          label: Text(
            _busy ? AppStrings.gettingYourLocation : AppStrings.useMyLocation,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: SizeUtils.h(context, AppDimensions.mediumFontSize),
              color: AppColors.pureWhite,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonPrimary,
            disabledBackgroundColor: AppColors.buttonPrimary,
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
        SizedBox(height: SizeUtils.h(context, AppDimensions.cleanupSpacing12)),
        LocationSearchField(
          controller: _textController,
          label: AppStrings.locationLabel,
          hint: AppStrings.searchForLocation,
          onPlaceSelected: _onPlaceSelected,
          onFocusLost: _onSearchFocusLost,
          supportText: widget.errorText,
          isError: widget.errorText != null,
          onChanged: (_) => widget.onError(null),
        ),
        SizedBox(height: SizeUtils.h(context, AppDimensions.cleanupSpacing4)),
        Text(
          AppStrings.searchOrDragMapHint,
          style: AppTextStyles.bodySecondary(context).copyWith(
            fontSize: SizeUtils.h(context, AppDimensions.smallFontSize),
            color: AppColors.textHint,
          ),
        ),
        if (widget.value != null && !widget.value!.verified) ...[
          SizedBox(height: SizeUtils.h(context, AppDimensions.cleanupSpacing4)),
          Text(
            AppStrings.locationNotVerifiedOffline,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: SizeUtils.h(context, AppDimensions.smallFontSize),
              color: AppColors.warning,
            ),
          ),
        ],
        SizedBox(height: SizeUtils.h(context, AppDimensions.cleanupSpacing12)),
        _MapPreview(value: widget.value, onTap: _openMapPicker),
      ],
    );
  }
}

/// Non-interactive preview. Touches go to the page (so scrolling works) and a
/// tap opens the full-screen picker.
class _MapPreview extends StatelessWidget {
  final PickedLocation? value;
  final VoidCallback onTap;

  const _MapPreview({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final height = SizeUtils.h(context, AppDimensions.mapPreviewHeight * 0.7);
    final radius = BorderRadius.circular(SizeUtils.r(context, 10));
    final loc = value;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (loc == null)
                Container(
                  color: AppColors.skeletonBase,
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(SizeUtils.w(context, 16)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: SizeUtils.r(context, 36),
                        color: AppColors.accentGreen,
                      ),
                      SizedBox(height: SizeUtils.h(context, 8)),
                      Text(
                        AppStrings.tapToChooseOnMap,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary(context),
                      ),
                    ],
                  ),
                )
              else
                IgnorePointer(
                  child: GoogleMap(
                    // Recreate on change so the camera always shows the pin.
                    key: ValueKey('${loc.latitude},${loc.longitude}'),
                    liteModeEnabled: true,
                    initialCameraPosition: CameraPosition(
                      target: loc.latLng,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: loc.latLng,
                      ),
                    },
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                  ),
                ),
              if (loc != null)
                Positioned(
                  right: SizeUtils.w(context, 8),
                  bottom: SizeUtils.h(context, 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeUtils.w(context, 10),
                      vertical: SizeUtils.h(context, 6),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(
                        SizeUtils.r(context, 16),
                      ),
                      boxShadow: const [
                        BoxShadow(color: AppColors.shadowMedium, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_location_alt_outlined,
                          size: SizeUtils.r(context, 16),
                          color: AppColors.buttonPrimary,
                        ),
                        SizedBox(width: SizeUtils.w(context, 4)),
                        Text(
                          AppStrings.adjustOnMap,
                          style: AppTextStyles.bodySecondary(context).copyWith(
                            color: AppColors.buttonPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen map with a fixed centre pin. Nothing is saved until the user
/// presses "Confirm location", and the point is validated before it is
/// returned. An invalid point keeps the pin where it is and shows an error.
class FullScreenLocationPicker extends StatefulWidget {
  final PickedLocation? initial;

  const FullScreenLocationPicker({super.key, this.initial});

  @override
  State<FullScreenLocationPicker> createState() =>
      _FullScreenLocationPickerState();
}

class _FullScreenLocationPickerState extends State<FullScreenLocationPicker> {
  GoogleMapController? _map;
  late LatLng _target;
  String? _address;
  String? _error;
  bool _checking = false;
  bool _hasLocationPermission = false;
  Timer? _addressDebounce;
  int _addressRequest = 0;

  @override
  void initState() {
    super.initState();
    _target = widget.initial?.latLng ?? LocationValidator.defaultCenter;
    _address = widget.initial?.address;
    Geolocator.checkPermission().then((p) {
      if (!mounted) return;
      setState(
        () =>
            _hasLocationPermission =
                p == LocationPermission.always ||
                p == LocationPermission.whileInUse,
      );
    });
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    super.dispose();
  }

  void _onCameraMove(CameraPosition position) {
    _target = position.target;
    if (_error != null || _address != null) {
      setState(() {
        _error = null;
        _address = null;
      });
    }
  }

  /// Address preview only — display, never saved without Confirm.
  void _onCameraIdle() {
    _addressDebounce?.cancel();
    _addressDebounce = Timer(
      Duration(milliseconds: AppDimensions.placeSearchDebounceMs),
      () async {
        final request = ++_addressRequest;
        final point = _target;
        final geo = await GooglePlacesService.reverseGeocode(
          point.latitude,
          point.longitude,
        );
        if (!mounted || request != _addressRequest) return;
        setState(() {
          _address =
              (geo != null && geo.formattedAddress.isNotEmpty)
                  ? geo.formattedAddress
                  : PickedLocation.coordsLabel(point);
        });
      },
    );
  }

  Future<void> _goToMyLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 8));
      _map?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          17,
        ),
      );
    } catch (e) {
      debugPrint('[LocationPicker] my location failed: $e');
    }
  }

  Future<void> _confirm() async {
    Get.find<HapticController>().medium();
    setState(() {
      _checking = true;
      _error = null;
    });
    final point = _target;
    final result = await LocationValidator.check(point);
    if (!mounted) return;
    if (!result.isValid) {
      Get.find<HapticController>().heavy();
      setState(() {
        _checking = false;
        _error = AppStrings.selectLocationInCameroon;
      });
      return;
    }
    Navigator.of(context).pop(result.location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          AppStrings.chooseLocationTitle,
          style: AppTextStyles.heading2(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (c) => _map = c,
            initialCameraPosition: CameraPosition(
              target: _target,
              zoom: widget.initial != null ? 16 : 6,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(5, 20),
            cameraTargetBounds: CameraTargetBounds(
              LocationValidator.cameroonBounds,
            ),
            myLocationEnabled: _hasLocationPermission,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
          ),
          // Fixed centre pin; its tip marks the camera target.
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: SizeUtils.r(context, 44)),
                child: Icon(
                  Icons.location_on,
                  size: SizeUtils.r(context, 48),
                  color: AppColors.errorRed,
                ),
              ),
            ),
          ),
          Positioned(
            top: SizeUtils.h(context, 12),
            left: SizeUtils.w(context, 16),
            right: SizeUtils.w(context, 16),
            child: Container(
              padding: EdgeInsets.all(SizeUtils.w(context, 10)),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(SizeUtils.r(context, 10)),
                boxShadow: const [
                  BoxShadow(color: AppColors.shadowMedium, blurRadius: 6),
                ],
              ),
              child: Text(
                AppStrings.movePinHint,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary(context),
              ),
            ),
          ),
          if (_hasLocationPermission)
            Positioned(
              right: SizeUtils.w(context, 16),
              bottom: SizeUtils.h(context, 180),
              child: FloatingActionButton.small(
                heroTag: 'location_picker_my_location',
                backgroundColor: AppColors.background,
                onPressed: _goToMyLocation,
                child: const Icon(
                  Icons.my_location,
                  color: AppColors.buttonPrimary,
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                margin: EdgeInsets.all(SizeUtils.w(context, 16)),
                padding: EdgeInsets.all(SizeUtils.w(context, 16)),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(SizeUtils.r(context, 14)),
                  boxShadow: const [
                    BoxShadow(color: AppColors.shadowMedium, blurRadius: 8),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          color: AppColors.accentGreen,
                          size: SizeUtils.r(context, 20),
                        ),
                        SizedBox(width: SizeUtils.w(context, 8)),
                        Expanded(
                          child: Text(
                            _address ?? AppStrings.checkingLocation,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(context),
                          ),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      SizedBox(height: SizeUtils.h(context, 8)),
                      Text(
                        _error!,
                        style: AppTextStyles.bodySecondary(
                          context,
                        ).copyWith(color: AppColors.errorRed),
                      ),
                    ],
                    SizedBox(height: SizeUtils.h(context, 12)),
                    SizedBox(
                      height: SizeUtils.h(context, AppDimensions.buttonHeight),
                      child: ElevatedButton(
                        onPressed: _checking ? null : _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              SizeUtils.r(context, AppDimensions.borderRadius),
                            ),
                          ),
                        ),
                        child:
                            _checking
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.pureWhite,
                                    ),
                                  ),
                                )
                                : Text(
                                  AppStrings.confirmLocation,
                                  style: AppTextStyles.saveCleanUpText(
                                    context,
                                  ).copyWith(color: AppColors.pureWhite),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
