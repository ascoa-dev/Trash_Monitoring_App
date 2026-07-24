import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/app/routes/app_routes.dart';
import 'package:we_monitor/modules/achievements/achievements_controller.dart';
import 'package:we_monitor/modules/hotspots/controllers/hotspot_report_controller.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/media_upload_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/services/google_places_service.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/widgets/circular_upload_progress.dart';
import 'package:we_monitor/shared/widgets/location_search_field.dart';
import 'package:we_monitor/shared/widgets/image_picker_dialog.dart';

class HotspotReportScreen extends StatefulWidget {
  const HotspotReportScreen({super.key});

  @override
  State<HotspotReportScreen> createState() => _HotspotReportScreenState();
}

class _HotspotReportScreenState extends State<HotspotReportScreen> {
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  Timer? _debounceTimer;
  bool _isUpdatingFromMap = false;
  late final Worker _connectivityWorker;

  HotspotReportController get controller => Get.find<HotspotReportController>();

  @override
  void initState() {
    super.initState();
    _locationController.addListener(() {
      controller.setLocation(_locationController.text);
    });

    final connectivity = Get.find<ConnectivityController>();
    _connectivityWorker = ever<bool>(connectivity.isOnline, (isOnline) async {
      if (!isOnline) return;
      if (_currentPosition == null) return;
      final pos = _currentPosition!;
      final isValid = await _isInCameroon(pos);
      if (!mounted) return;
      if (!isValid) {
        controller.setLocationError(AppStrings.selectLocationInCameroon);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFetchLocation();
    });
  }

  @override
  void dispose() {
    _connectivityWorker.dispose();
    _debounceTimer?.cancel();
    _locationController.dispose();
    super.dispose();
  }

  bool _isInCameroonBbox(LatLng location) {
    return location.latitude >= 1.72767263428 &&
        location.latitude <= 12.8593962671 &&
        location.longitude >= 8.48881554529 &&
        location.longitude <= 16.0128524106;
  }

  Future<bool> _isInCameroon(LatLng location) async {
    final connectivity = Get.find<ConnectivityController>();
    if (!connectivity.isOnline.value) {
      return _isInCameroonBbox(location);
    }
    final result = await GooglePlacesService.reverseGeocode(
      location.latitude,
      location.longitude,
    );
    if (result == null) return false;
    return result.isCameroon;
  }

  void _updateMapPosition(LatLng position) {
    setState(() {
      _currentPosition = position;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: position,
        ),
      };
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  Future<void> _autoFetchLocation() async {
    if (_locationController.text.isNotEmpty) return;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          _updateMapPosition(LatLng(position.latitude, position.longitude));
        }
      } catch (_) {}

      try {
        final current = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 8));
        position = current;
      } on TimeoutException {
        if (position == null) return;
      } catch (_) {
        if (position == null) return;
      }

      final userLocation = LatLng(position.latitude, position.longitude);
      final connectivity = Get.find<ConnectivityController>();

      if (!connectivity.isOnline.value) {
        if (!_isInCameroonBbox(userLocation)) return;
        _updateMapPosition(userLocation);
        controller.setCoordinates(userLocation.latitude, userLocation.longitude);
        _isUpdatingFromMap = true;
        _locationController.text =
            'Lat ${userLocation.latitude.toStringAsFixed(5)}, Lng ${userLocation.longitude.toStringAsFixed(5)}';
        _isUpdatingFromMap = false;
        return;
      }

      final geo = await GooglePlacesService.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      if (geo == null || !geo.isCameroon) return;

      _updateMapPosition(userLocation);
      controller.setCoordinates(userLocation.latitude, userLocation.longitude);
      _isUpdatingFromMap = true;
      _locationController.text = geo.formattedAddress;
      _isUpdatingFromMap = false;
    } catch (e) {
      debugPrint('[HotspotReport] _autoFetchLocation error: $e');
    }
  }

  void _onMapDragEnd() {
    if (_currentPosition == null || _isUpdatingFromMap) return;
    controller.setCoordinates(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      Duration(milliseconds: AppDimensions.placeSearchDebounceMs),
      () async {
        final pos = _currentPosition;
        if (pos == null) return;

        void resetToCentre() {
          const yaounde = LatLng(3.8480, 11.5021);
          setState(() {
            _currentPosition = yaounde;
            _markers = {const Marker(markerId: MarkerId('selected'), position: yaounde)};
          });
          _mapController?.animateCamera(CameraUpdate.newLatLng(yaounde));
        }

        final connectivity = Get.find<ConnectivityController>();
        if (!connectivity.isOnline.value) {
          if (!mounted) return;
          if (!_isInCameroonBbox(pos)) {
            controller.setLocationError(AppStrings.selectLocationInCameroon);
            resetToCentre();
            return;
          }
          _isUpdatingFromMap = true;
          _locationController.text =
              'Lat ${pos.latitude.toStringAsFixed(5)}, Lng ${pos.longitude.toStringAsFixed(5)}';
          _isUpdatingFromMap = false;
          controller.setLocationError(null);
          return;
        }

        final geo = await GooglePlacesService.reverseGeocode(pos.latitude, pos.longitude);
        if (!mounted) return;
        if (geo == null || !geo.isCameroon) {
          controller.setLocationError(AppStrings.selectLocationInCameroon);
          resetToCentre();
          return;
        }
        _isUpdatingFromMap = true;
        _locationController.text = geo.formattedAddress;
        _isUpdatingFromMap = false;
        controller.setLocationError(null);
      },
    );
  }

  Future<void> _useCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack(AppStrings.enableLocationServices, AppColors.warning);
        return;
      }

      var permission = await Geolocator.checkPermission();
      bool permissionRequested = false;
      if (permission == LocationPermission.denied) {
        permissionRequested = true;
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack(AppStrings.locationPermissionDenied, AppColors.errorRed);
        return;
      }

      if (permissionRequested) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          controller.setCoordinates(position.latitude, position.longitude);
          _updateMapPosition(LatLng(position.latitude, position.longitude));
          _isUpdatingFromMap = true;
          _locationController.text =
              'Lat ${position.latitude.toStringAsFixed(5)}, Lng ${position.longitude.toStringAsFixed(5)}';
          _isUpdatingFromMap = false;
        }
      } catch (e) {
        debugPrint('Error getting last known position in hotspot: $e');
      }

      try {
        final currentPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 8));
        position = currentPos;
      } on TimeoutException {
        if (position == null) {
          throw TimeoutException('Location request timed out');
        }
      } catch (e) {
        if (position == null) rethrow;
      }

      controller.setCoordinates(position.latitude, position.longitude);
      _updateMapPosition(LatLng(position.latitude, position.longitude));

      final connectivity = Get.find<ConnectivityController>();
      if (connectivity.isOnline.value) {
        try {
          final geo = await GooglePlacesService.reverseGeocode(
            position.latitude,
            position.longitude,
          );
          if (!mounted) return;
          if (geo != null) {
            _isUpdatingFromMap = true;
            _locationController.text = geo.formattedAddress;
            _isUpdatingFromMap = false;
          } else {
            _isUpdatingFromMap = true;
            _locationController.text =
                'Lat ${position.latitude.toStringAsFixed(5)}, Lng ${position.longitude.toStringAsFixed(5)}';
            _isUpdatingFromMap = false;
          }
        } catch (e) {
          debugPrint('Geocoding error in hotspot: $e');
          _isUpdatingFromMap = true;
          _locationController.text =
              'Lat ${position.latitude.toStringAsFixed(5)}, Lng ${position.longitude.toStringAsFixed(5)}';
          _isUpdatingFromMap = false;
        }
      } else {
        _isUpdatingFromMap = true;
        _locationController.text =
            'Lat ${position.latitude.toStringAsFixed(5)}, Lng ${position.longitude.toStringAsFixed(5)}';
        _isUpdatingFromMap = false;
      }
    } catch (e) {
      _showSnack(AppStrings.locationFetchFailed, AppColors.errorRed);
    }
  }

  Future<void> _pickImages() async {
    final media = controller.mediaUploadController;
    if (!media.canAddMore) {
      _showSnack(
        'Maximum ${MediaUploadConfig.maxPhotos} photos allowed',
        AppColors.errorRed,
      );
      return;
    }

    final remaining = MediaUploadConfig.maxPhotos - media.photoCount;
    final ImageSource? source = await Get.dialog<ImageSource?>(
      const ImagePickerDialog(),
    );
    if (source == null) return;

    List<XFile> picked = [];
    if (source == ImageSource.camera) {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      if (file != null) {
        picked = [file];
      }
    } else {
      picked = await _picker.pickMultiImage(
        imageQuality: 100,
        limit: remaining,
      );
    }
    if (picked.isEmpty) return;

    final files =
        picked.take(remaining).map((image) => File(image.path)).toList();
    await controller.addPhotos(files);

    final isOnline = Get.find<ConnectivityController>().isOnline.value;
    if (isOnline) {
      for (final file in files) {
        final photo = media.photos.firstWhere((p) => p.file.path == file.path);
        media.compressAndUpload(photo.id, controller.hotspotDocId);
      }
    }

    _showSnack(
      isOnline
          ? '${files.length} photo(s) uploading...'
          : '${files.length} photo(s) saved for offline upload.',
      AppColors.info,
    );
  }

  Future<void> _submit() async {
    Get.find<HapticController>().medium();
    final id = await controller.submit();
    if (!mounted) return;
    if (id == null) {
      _showSnack(
        'Failed to save hotspot report. Please check the form.',
        AppColors.errorRed,
      );
      return;
    }

    final wasOnline = Get.find<ConnectivityController>().isOnline.value;
    _showSnack(
      wasOnline
          ? 'Hotspot report saved.'
          : 'Hotspot saved offline. It will upload when you are online.',
      AppColors.success,
    );
    Get.offAllNamed(AppRoutes.home);
    if (wasOnline) {
      AchievementsController.checkAfterActivity();
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Report Plastic Hotspot',
          style: AppTextStyles.heading2(context),
        ),
        leading: BackButton(
          color: AppColors.black87,
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            SizeUtils.w(context, AppDimensions.screenPadding),
          ),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final media = controller.mediaUploadController;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add the hotspot location and up to ${MediaUploadConfig.maxPhotos} photos.',
                    style: AppTextStyles.body(context),
                  ),
                  SizedBox(
                    height: SizeUtils.h(
                      context,
                      AppDimensions.cleanupSpacing20,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(
                      Icons.my_location,
                      color: AppColors.pureWhite,
                    ),
                    label: Text(
                      AppStrings.useMyLocation,
                      style: AppTextStyles.buttonPrimaryText(
                        context,
                      ).copyWith(color: AppColors.pureWhite),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                    ),
                  ),
                  SizedBox(
                    height: SizeUtils.h(
                      context,
                      AppDimensions.cleanupSpacing16,
                    ),
                  ),
                  LocationSearchField(
                    controller: _locationController,
                    label: AppStrings.locationLabel,
                    hint: AppStrings.searchForLocation,
                    onPlaceSelected: (details) {
                      final lat = details.latLng.latitude;
                      final lng = details.latLng.longitude;
                      controller.setCoordinates(lat, lng);
                      _updateMapPosition(LatLng(lat, lng));
                    },
                    supportText: controller.locationError,
                    isError: controller.locationError != null,
                    onChanged: controller.setLocation,
                  ),
                  SizedBox(height: SizeUtils.h(context, 4)),
                  Text(
                    AppStrings.searchOrDragMapHint,
                    style: AppTextStyles.bodySecondary(context).copyWith(
                      fontSize: SizeUtils.h(
                        context,
                        AppDimensions.smallFontSize,
                      ),
                      color: AppColors.textHint,
                    ),
                  ),
                  SizedBox(
                    height: SizeUtils.h(
                      context,
                      AppDimensions.cleanupSpacing12,
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SizeUtils.r(context, 10)),
                    child: SizedBox(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.mapPreviewHeight,
                        useContentHeight: false,
                      ),
                      width: double.infinity,
                      child: GoogleMap(
                        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                          Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        },
                        onMapCreated: (ctrl) {
                          _mapController = ctrl;
                          if (_currentPosition != null) {
                            ctrl.animateCamera(
                              CameraUpdate.newLatLng(_currentPosition!),
                            );
                          }
                        },
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(3.8480, 11.5021),
                          zoom: 6,
                        ),
                        minMaxZoomPreference: const MinMaxZoomPreference(5, 20),
                        cameraTargetBounds: CameraTargetBounds(
                          LatLngBounds(
                            southwest: const LatLng(1.65, 8.49),
                            northeast: const LatLng(13.08, 16.19),
                          ),
                        ),
                        markers: _markers,
                        zoomControlsEnabled: false,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        onCameraMove: (position) {
                          if (!_isUpdatingFromMap) {
                            setState(() {
                              _currentPosition = position.target;
                              _markers = {
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
                  SizedBox(
                    height: SizeUtils.h(
                      context,
                      AppDimensions.cleanupSpacing20,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: media.canAddMore ? _pickImages : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonGreen,
                      disabledBackgroundColor: AppColors.grey400,
                    ),
                    child: Text(
                      AppStrings.uploadImagesButton,
                      style: AppTextStyles.buttonPrimaryText(
                        context,
                      ).copyWith(color: AppColors.pureWhite),
                    ),
                  ),
                  if (controller.photosError != null) ...[
                    SizedBox(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.inputErrorSpacing,
                      ),
                    ),
                    Text(
                      controller.photosError!,
                      style: AppTextStyles.bodySecondary(
                        context,
                      ).copyWith(color: AppColors.errorRed),
                    ),
                  ],
                  SizedBox(
                    height: SizeUtils.h(
                      context,
                      AppDimensions.cleanupSpacing16,
                    ),
                  ),
                  _PhotoGrid(media: media),
                  SizedBox(
                    height: SizeUtils.h(
                      context,
                      AppDimensions.cleanupSpacing24,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: controller.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonGreen,
                      disabledBackgroundColor: AppColors.grey400,
                    ),
                    child: Text(
                      controller.isSubmitting ? 'SAVING...' : 'SAVE HOTSPOT',
                      style: AppTextStyles.saveCleanUpText(
                        context,
                      ).copyWith(color: AppColors.pureWhite),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.media});

  final MediaUploadController media;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: media,
      builder: (context, _) {
        if (!media.hasPhotos) return const SizedBox.shrink();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: media.photoCount <= 3 ? media.photoCount : 2,
            crossAxisSpacing: SizeUtils.w(
              context,
              AppDimensions.cleanupSpacing12,
            ),
            mainAxisSpacing: SizeUtils.h(
              context,
              AppDimensions.cleanupSpacing12,
            ),
          ),
          itemCount: media.photos.length,
          itemBuilder: (context, index) {
            final photo = media.photos[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(SizeUtils.r(context, 8)),
                  child: Image.file(photo.file, fit: BoxFit.cover, cacheWidth: 300),
                ),
                if (photo.status == PhotoUploadStatus.compressing ||
                    photo.status == PhotoUploadStatus.uploading)
                  Container(
                    color: AppColors.black54,
                    child: Center(
                      child: CircularUploadProgress(
                        size: SizeUtils.r(
                          context,
                          AppDimensions.circularLoaderSize,
                        ),
                        progress: photo.progress,
                        activeColor: AppColors.loaderActive,
                        trackColor: AppColors.loaderTrack,
                        strokeWidth: SizeUtils.r(
                          context,
                          AppDimensions.circularLoaderStrokeWidth,
                        ),
                        gap: SizeUtils.r(
                          context,
                          AppDimensions.circularLoaderGap,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                    ),
                    onPressed: () => media.removePhoto(photo.id),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
